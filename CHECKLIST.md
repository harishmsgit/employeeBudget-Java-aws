# End-to-End Delivery Checklist

## 1. AWS Foundation

- [ ] Confirm EKS cluster exists: `webapp-eks-cluster`
- [ ] Confirm worker nodes and IAM roles are healthy
- [ ] Confirm VPC networking (2 public + 2 private subnets)
- [ ] Confirm NAT, route tables, security groups
- [ ] Confirm kubectl access to cluster

## 2. Domain and DNS (Namecheap + Cloudflare)

- [ ] Domain uses Cloudflare nameservers in Namecheap
- [ ] Cloudflare DNS record created:
  - [ ] `app.<your-domain>` CNAME/A to ingress endpoint
- [ ] SSL mode in Cloudflare set to Full (strict)
- [ ] TLS certificate ready in ingress (cert-manager or ACM strategy)

## 3. Container and Registry

- [ ] ECR repositories created:
  - [ ] `employee-service`
  - [ ] `project-service`
  - [ ] `budget-service`
- [ ] Docker images build successfully
- [ ] Images pushed with immutable tags (commit SHA)

## 4. CI/CD

- [ ] GitHub secrets configured:
  - [ ] `AWS_REGION`
  - [ ] `AWS_ROLE_TO_ASSUME` (recommended) or static keys
  - [ ] `ECR_REGISTRY`
- [ ] GitHub Actions pipeline passing
- [ ] Kustomize tags updated per environment

## 5. GitOps + ArgoCD

- [ ] ArgoCD installed in EKS
- [ ] Argo Rollouts installed in EKS
- [ ] ArgoCD Application created for each environment
- [ ] Auto-sync policy validated

## 6. Runtime Platform

- [ ] NGINX ingress controller installed in EKS
- [ ] IngressClass is `nginx`
- [ ] Environment overlays tested:
  - [ ] dev
  - [ ] qa
  - [ ] prod

## 7. Data + Messaging

- [ ] PostgreSQL reachable from pods
- [ ] Kafka reachable from pods
- [ ] Topics available:
  - [ ] `employee-changed`
  - [ ] `project-changed`

## 8. Application Functional

- [ ] Employee REST endpoints tested
- [ ] Project GraphQL operations tested
- [ ] Budget GraphQL operations tested
- [ ] Event flow validated Employee -> Project -> Budget

## 9. Blue/Green Release

- [ ] Rollouts resources applied
- [ ] Preview service reachable
- [ ] Promotion tested
- [ ] Rollback tested

## 10. Production Readiness

- [ ] Resource requests/limits tuned
- [ ] Probes configured
- [ ] Logs/metrics/traces integrated
- [ ] Backup/restore runbook ready
- [ ] On-call alerting configured
