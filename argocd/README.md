# ArgoCD — Application Definitions

This folder contains ArgoCD `Application` CRD manifests, one per environment.
ArgoCD watches the matching `gitops/overlays/<env>` path in the Git repo and
continuously reconciles the live cluster state against it.

## Files

| File | Environment | Namespace |
|------|------------|-----------|
| `app-dev.yaml` | dev | dda-app |
| `app-qa.yaml` | qa | dda-app |
| `app-prod.yaml` | prod | dda-app |

## Apply to Cluster

```bash
# Install ArgoCD (once)
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Apply environment applications
kubectl apply -f argocd/app-dev.yaml
kubectl apply -f argocd/app-qa.yaml
kubectl apply -f argocd/app-prod.yaml
```

## Blue/Green Promotion

Argo Rollouts (installed separately) handles blue/green per service.
`autoPromotionEnabled: false` means every release waits for a manual promote:

```bash
kubectl argo rollouts promote employee-service -n dda-app
kubectl argo rollouts promote project-service  -n dda-app
kubectl argo rollouts promote budget-service   -n dda-app
```

## Sync Flow

```
GitHub push → GitHub Actions updates gitops/overlays/<env>/kustomization.yaml
           → ArgoCD detects diff → applies to EKS namespace dda-app
```

## Repo Reference

- Repo: `https://github.com/harishmsgit/employeeBudget-Java-aws.git`
- Branch: `main`
- GitOps path: `gitops/overlays/<env>`
