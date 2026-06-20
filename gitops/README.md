# GitOps — Kubernetes Manifests

This folder contains all Kubernetes manifests managed by ArgoCD via Kustomize.
No Helm charts are used; overlays patch the base resources for each environment.

## Structure

```
gitops/
├── base/                        # Shared manifests (all environments)
│   ├── kustomization.yaml
│   ├── secret-template.yaml     # Secret shape (fill values before apply)
│   ├── employee/
│   │   ├── rollout.yaml         # Argo Rollout (blue/green)
│   │   ├── service-active.yaml
│   │   └── service-preview.yaml
│   ├── project/
│   │   ├── rollout.yaml
│   │   ├── service-active.yaml
│   │   └── service-preview.yaml
│   ├── budget/
│   │   ├── rollout.yaml
│   │   ├── service-active.yaml
│   │   └── service-preview.yaml
│   └── ingress/
│       └── ingress.yaml         # NGINX Ingress for harishweb.online
└── overlays/
    ├── dev/                     # dev.harishweb.online
    │   ├── kustomization.yaml   # ECR image tags (auto-updated by CI)
    │   ├── patch-env.yaml       # SPRING_PROFILES_ACTIVE=dev
    │   └── patch-ingress-host.yaml
    ├── qa/                      # qa.harishweb.online
    │   ├── kustomization.yaml
    │   ├── patch-env.yaml
    │   └── patch-ingress-host.yaml
    └── prod/                    # app.harishweb.online
        ├── kustomization.yaml
        ├── patch-env.yaml
        └── patch-ingress-host.yaml
```

## How Image Tags Are Updated

GitHub Actions writes the new commit SHA into the overlay kustomization on
every push to `main` for `dev`, and a manual promote workflow for `qa`/`prod`:

```bash
# Triggered automatically by ci-cd.yml for dev
sed -i "s/newTag: .*/newTag: ${GITHUB_SHA}/g" gitops/overlays/dev/kustomization.yaml

# Promote to qa or prod via GitHub Actions workflow_dispatch
# File: .github/workflows/promote-env.yml
```

## Apply Manually (without ArgoCD)

```bash
# Preview rendered YAML
kubectl kustomize gitops/overlays/dev

# Apply to cluster
kubectl apply -k gitops/overlays/dev
kubectl apply -k gitops/overlays/qa
kubectl apply -k gitops/overlays/prod
```

## Secrets

`gitops/base/secret-template.yaml` is a template only.
**Do not commit real secrets.** Use AWS Secrets Manager + External Secrets
Operator or `kubectl create secret` with sealed secrets in production.

## Domains

| Environment | Hostname |
|-------------|----------|
| dev | dev.harishweb.online |
| qa | qa.harishweb.online |
| prod | app.harishweb.online |
