# Demo Node App CI/CD (GitHub Actions → Local Docker)

This repo demonstrates an end-to-end CI/CD pipeline for a simple Node.js + Express app. The pipeline builds, tests, packages into Docker, and deploys to a local Docker engine on the GitHub runner. Optional publishing to GHCR is supported when a token is provided.

## Quick Start
- Install/test: `npm ci && npm test`
- Local container: `docker build -t demo-node-app:local --build-arg BUILD_ID=local . && docker run -d -p 3000:3000 --name demo-node-app demo-node-app:local`
- Health check: `curl -fsS http://localhost:3000/healthz`

## CI/CD Workflow
- File: `.github/workflows/ci-cd.yml`
- Jobs:
  - `build-and-test`: checkout → Node setup → `npm ci` → `npm test` → Docker build (tags SHA + latest) → save tar artifact → optional push to GHCR if `CR_PAT` is set.
  - `deploy-local`: download artifact → load image → run `scripts/deploy.sh` → smoke check `/healthz`.
  - `rollback-on-failure`: if deploy fails, `scripts/rollback.sh` redeploys `:latest`.
- Triggers: `push`/`pull_request` to `main`, plus manual `workflow_dispatch` with optional `deploy_tag`.

## Deployment & Rollback Scripts
- Deploy: `./scripts/deploy.sh --image <image:tag> --previous <fallback:tag>`
  - Runs container, waits for `/healthz`, rolls back to `--previous` if health fails.
- Rollback: `./scripts/rollback.sh --image <image:tag>`

## GHCR (optional)
- Add secret `CR_PAT` (PAT with `packages:write`) to enable image pushes to GHCR.
- Images are tagged with commit SHA and `latest` for traceability.

## Documentation PDF
- Local (requires Node): `npx md-to-pdf docs/pipeline-notes.md -o docs/pipeline-notes.pdf`
- GitHub Actions alternative: run workflow `Build Docs PDF` (workflow_dispatch). It generates `docs/pipeline-notes.pdf` and uploads it as an artifact named `pipeline-notes-pdf`.

## Deliverables Checklist
- GitHub repo URL
- Pipeline YAML: `.github/workflows/ci-cd.yml`
- Shell scripts: `scripts/deploy.sh`, `scripts/rollback.sh`
- Screenshots/recordings:
  - Pipeline run (build/test/deploy)
  - Successful deployment (`docker ps`, `curl /` showing build tag)
  - Rollback/error handling demonstration
- Documentation PDF: `docs/pipeline-notes.pdf` (export from `docs/pipeline-notes.md`)


