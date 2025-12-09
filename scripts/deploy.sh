#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Deploy the demo-node-app container locally.

Required:
  --image TAG        Full image tag to deploy (e.g. ghcr.io/org/demo:sha)

Optional:
  --name NAME        Container name (default: demo-node-app)
  --port PORT        Host port to map (default: 3000)
  --previous TAG     Previous image tag to use for rollback if health fails

Examples:
  ./scripts/deploy.sh --image ghcr.io/acme/demo:abc123
  ./scripts/deploy.sh --image ghcr.io/acme/demo:abc123 --previous ghcr.io/acme/demo:latest
EOF
}

IMAGE=""
NAME="demo-node-app"
PORT="3000"
PREVIOUS_IMAGE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --image) IMAGE="$2"; shift 2 ;;
    --name) NAME="$2"; shift 2 ;;
    --port) PORT="$2"; shift 2 ;;
    --previous) PREVIOUS_IMAGE="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage; exit 1 ;;
  esac
done

if [[ -z "$IMAGE" ]]; then
  echo "ERROR: --image is required" >&2
  usage
  exit 1
fi

echo "[deploy] Using image: $IMAGE"
if docker ps -a --format '{{.Names}}' | grep -q "^${NAME}\$"; then
  echo "[deploy] Stopping existing container ${NAME}"
  docker rm -f "$NAME" >/dev/null 2>&1 || true
fi

echo "[deploy] Starting container ${NAME} on port ${PORT}"
docker run -d \
  --name "$NAME" \
  -p "${PORT}:3000" \
  -e BUILD_ID="${IMAGE##*:}" \
  "$IMAGE"

echo "[deploy] Waiting for health check..."
for i in {1..15}; do
  if curl -fsS "http://localhost:${PORT}/healthz" >/dev/null 2>&1; then
    echo "[deploy] Health check passed"
    exit 0
  fi
  sleep 1
done

echo "[deploy] Health check failed for ${IMAGE}"
if [[ -n "$PREVIOUS_IMAGE" ]]; then
  echo "[deploy] Attempting rollback to ${PREVIOUS_IMAGE}"
  ./scripts/rollback.sh --image "$PREVIOUS_IMAGE" --name "$NAME" --port "$PORT"
fi

exit 1

