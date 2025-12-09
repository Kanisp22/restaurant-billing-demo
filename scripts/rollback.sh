#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Rollback the demo-node-app container to a known-good image.

Required:
  --image TAG        Full image tag to deploy (e.g. ghcr.io/org/demo:latest)

Optional:
  --name NAME        Container name (default: demo-node-app)
  --port PORT        Host port to map (default: 3000)
EOF
}

IMAGE=""
NAME="demo-node-app"
PORT="3000"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --image) IMAGE="$2"; shift 2 ;;
    --name) NAME="$2"; shift 2 ;;
    --port) PORT="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage; exit 1 ;;
  esac
done

if [[ -z "$IMAGE" ]]; then
  echo "ERROR: --image is required" >&2
  usage
  exit 1
fi

echo "[rollback] Rolling back ${NAME} to ${IMAGE}"
if docker ps -a --format '{{.Names}}' | grep -q "^${NAME}\$"; then
  docker rm -f "$NAME" >/dev/null 2>&1 || true
fi

docker run -d \
  --name "$NAME" \
  -p "${PORT}:3000" \
  -e BUILD_ID="${IMAGE##*:}" \
  "$IMAGE"

echo "[rollback] Container restarted with ${IMAGE}"

