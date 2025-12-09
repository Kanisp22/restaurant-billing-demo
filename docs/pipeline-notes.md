# Demo Node App CI/CD (GitHub Actions → Local Docker)

## Overview
- Source: Node.js + Express (`src/index.js`), containerized with `Dockerfile`.
- Pipeline: `.github/workflows/ci-cd.yml` builds, tests, packages, deploys to a local Docker engine on the GitHub runner. Optional push to GHCR when `CR_PAT` secret is present.
- Deploy tooling: `scripts/deploy.sh` (deploy with health check + optional rollback), `scripts/rollback.sh` (manual rollback).

## Reproduce Locally
1) Clone repo, install deps, run tests:
   ```bash
   npm ci
   npm test
   ```
2) Build and run with Docker:
   ```bash
   docker build -t demo-node-app:local --build-arg BUILD_ID=local .
   docker run -d -p 3000:3000 --name demo-node-app demo-node-app:local
   curl -fsS http://localhost:3000/healthz
   ```
3) Deploy script with rollback option:
   ```bash
   ./scripts/deploy.sh --image demo-node-app:local --previous demo-node-app:prev
   ./scripts/rollback.sh --image demo-node-app:prev
   ```

## GitHub Actions Flow
1) `build-and-test`: checkout → Node setup → `npm ci` → `npm test` → build Docker image (tags SHA + latest) → save image tar → upload artifact → optional GHCR push.
2) `deploy-local`: download image artifact → load → run `scripts/deploy.sh` → smoke check `/healthz`.
3) `rollback-on-failure`: if deploy job fails, `scripts/rollback.sh` redeploys latest tag.

### Triggers
- `push`/`pull_request` to `main`.
- `workflow_dispatch` with optional `deploy_tag` for re-deploying a prior image.

### Secrets
- `CR_PAT` (personal access token with `packages:write`) to publish images to GHCR (optional).

## Rollback Strategy
- Health check inside `deploy.sh`; on failure, auto-calls `rollback.sh` with `--previous` tag when provided.
- Manual rollback: rerun workflow_dispatch with `deploy_tag` set to last known good SHA, or run `rollback.sh --image <good-tag>` on the host.

## Security & Maintainability Notes
- Least-privilege PAT; avoid storing secrets in repo. Use GitHub Environments for prod credentials.
- Supply chain: use `npm ci` with lockfile and `node:18-slim`. Pin Actions versions (`@v4`, `@v5`).
- Observability: container logs via `docker logs demo-node-app`; health endpoint `/healthz`.
- Testing: minimal integration test in `src/__tests__/health.test.js`; extend with supertest and contract tests as needed.
- Cleanup: containers removed before redeploy; images tagged by SHA for traceability.

## Files of Interest
- Pipeline: `.github/workflows/ci-cd.yml`
- Dockerfile: `Dockerfile`
- Compose: `docker-compose.yml` (developer convenience)
- Scripts: `scripts/deploy.sh`, `scripts/rollback.sh`
- App entry: `src/index.js`
- Tests: `src/__tests__/health.test.js`

## Demo Artifacts to Capture
- Screenshot: GitHub Actions run (green) showing build/test/deploy jobs.
- Screenshot: `docker ps` + `curl /` response showing `build` value (from SHA).
- Screenshot/clip: failed deploy triggering rollback (e.g., health check fails) and container restarted from previous tag.

## Converting to PDF
- From repo root:
  ```bash
  npx md-to-pdf docs/pipeline-notes.md
  # or: pandoc docs/pipeline-notes.md -o docs/pipeline-notes.pdf
  ```

