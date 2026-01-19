# GitHub Copilot Instructions — Devops-Programme Monorepo

Purpose: give AI coding agents the minimal, repo-specific context and actionable conventions
so they can be productive immediately. Merge any task-specific guidance from subfolders
instead of overwriting it (see the Argo CD workshop below).

**Scope**: This repo contains a small Python/Flask demo app, Dockerfiles, Kubernetes manifests,
workshop materials (Argo CD GitOps), and infra examples (Packer, Terraform). Do not change
training/workshop rules unless the task explicitly targets that workshop.

- **Workshop guidance:** The Argo CD workshop has its own strict instructions. Preserve or
  reference it rather than modify: [telerik-argocd-gitops-workshop-2026/.github/copilot-instructions.md](telerik-argocd-gitops-workshop-2026/.github/copilot-instructions.md#L1)

**Big picture / major components**
- `app/` — small Flask demo application. Entry points: [app/app.py](app/app.py) and [app/password_generator.py](app/password_generator.py).
- `Dockerfile` and `Dockerfile2` — two different images for local experiments; both expose port 3000.
- `telerik-argocd-gitops-workshop-2026/` — a self-contained workshop (Argo CD + scenarios). Treat as training material.
- `pod-manifests/`, `pod.yaml` and `terraform/` — infra examples (Kubernetes/terraform) for learning.

**Critical developer workflows (run these locally)**
- Run unit tests: `python -m unittest app/app_test.py`
- Run the Flask app locally: `python3 app/app.py` (listens on port 3000, `PORT` env var supported)
- Build & run Docker (root Dockerfile):
  - `docker build -t devops-app -f Dockerfile .`
  - `docker run -p 3000:3000 devops-app`
- Alternative Docker (password generator):
  - `docker build -t passgen -f Dockerfile2 .`
  - `docker run -p 3000:3000 passgen`
- Terraform quick check (example infra): `cd terraform && terraform init && terraform plan`
- Workshop (Argo CD) steps: follow [telerik-argocd-gitops-workshop-2026/README.md](telerik-argocd-gitops-workshop-2026/README.md) — do NOT change app manifests there unless instructed.

**Project-specific conventions & patterns**
- Tests: `unittest` style tests that import `app` directly (see [app/app_test.py](app/app_test.py)).
- Flask: app binds to `0.0.0.0` and uses port `3000` by default; code reads `PORT` in `app/app.py`.
- Dockerfiles create non-root users (`flask`, `pyt`) — avoid assuming root in container tasks.
- `requirements.txt` pins Flask 3.x — check Python version constraints before upgrading.
- Workshop manifests are intentionally minimal and educational; they avoid Helm/Kustomize and advanced features.

**Integration points & external dependencies**
- Argo CD: see `telerik-argocd-gitops-workshop-2026/argocd/application.yaml` (repo-driven deployment).
- Terraform: `terraform/kubernetes.tf` shows terraform usage for Kubernetes resources.
- Docker Hub / external images: some manifests reference public images (e.g., the workshop uses `nginx:1.25`).

**Editing rules for AI agents**
- Preserve existing workshop instructions: reference rather than overwrite [telerik-argocd-gitops-workshop-2026/.github/copilot-instructions.md](telerik-argocd-gitops-workshop-2026/.github/copilot-instructions.md#L1).
- When changing code: run `python -m unittest` and prefer minimal, focused edits.
- When adding k8s manifests, follow the workshop's manifest style if the change targets that workshop (stable API versions, simple readable manifests).

If anything in these instructions is unclear or you need more specific examples (build scripts, CI, or exact file edits), tell me which area to expand.
