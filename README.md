# Java Spring Boot Microservices on AWS EKS (DDD + EDA)

This repository contains a simple, production-oriented starter for 3 microservices plus one infra stack:

1. Employee service (REST API)
2. Project service (GraphQL API)
3. Budget service (GraphQL API)

Design goals:
- DDD bounded contexts
- Event-driven communication with Kafka
- PostgreSQL persistence
- Docker images in ECR
- Deploy to existing EKS cluster (`webapp-eks-cluster`)
- GitOps with ArgoCD
- Blue/Green delivery with Argo Rollouts
- NGINX env-specific config for dev/qa/prod

## Bounded Contexts

- Context 1: Employee
  - Endpoints: `/addEmp`, `/updateEmp`, `/deleteEmp`, `/getEmp`
- Context 2: Project (GraphQL)
  - Operations: `addProject`, `updateProject`, `deleteProject`, `getProject`
- Context 3: Budget (GraphQL)
  - Operations: `addbuget`, `updatebuget`, `deletebuget`, `budgetLinedProject`

## Top-Level Structure

```
.
├── services/
│   ├── employee-service/   # REST API — Dockerfile + docker-compose.yml
│   ├── project-service/    # GraphQL API — Dockerfile + docker-compose.yml
│   └── budget-service/     # GraphQL API — Dockerfile + docker-compose.yml
├── infra/                  # Shared infra: Terraform, NGINX, local compose
│   ├── docker-compose.yml
│   ├── terraform/
│   ├── nginx/{dev,qa,prod}/
│   └── local/
├── gitops/                 # Kubernetes manifests managed via Kustomize
│   ├── base/
│   └── overlays/{dev,qa,prod}/
├── argocd/                 # ArgoCD Application CRDs per environment
│   ├── app-dev.yaml
│   ├── app-qa.yaml
│   └── app-prod.yaml
└── .github/workflows/      # CI/CD pipelines
```

## Quick Start (Local)

1. Start dependencies:
  - `cd infra && docker compose up -d`
  - This starts local PostgreSQL and creates `employee_db`, `project_db`, and `budget_db`.
2. Run services:
  - Employee: `cd services/employee-service && docker compose up -d --build`
  - Project: `cd services/project-service && docker compose up -d --build`
  - Budget: `cd services/budget-service && docker compose up -d --build`

## Deploy to EKS (Summary)

1. Build and push images to ECR (`.github/workflows/ci-cd.yml` can do this).
2. Update image tags in `gitops/overlays/<env>/kustomization.yaml`.
3. Apply ArgoCD application manifest from `argocd/apps/`.
4. ArgoCD syncs manifests into EKS namespace.
5. Route domain in Cloudflare to NGINX ingress controller endpoint.

For complete steps, see `CHECKLIST.md`.



Terraform:

aws s3api create-bucket \
  --bucket harish-terraform-state-bucket \
  --region ap-south-1 \
  --create-bucket-configuration LocationConstraint=ap-south-1

aws s3api put-bucket-versioning \
  --bucket harish-terraform-state-bucket \
  --versioning-configuration Status=Enabled

aws dynamodb create-table \
  --table-name harish-terraform-state-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region ap-south-1


  cd ~/employeeBudget-Java-aws
git config pull.rebase false        # merge strategy (one-time config)
git pull origin master

cd ~/employeeBudget-Java-aws
git fetch origin
git reset --hard origin/main

ls rpsp_infra/iac/terraform/environments/dev/backend.hcl
# should show the file now

cd rpsp_infra/iac/terraform
terraform init -backend-config=environments/dev/backend.hcl




aws s3api create-bucket \
  --bucket harish-terraform-state-bucket \
  --region ap-south-1 \
  --create-bucket-configuration LocationConstraint=ap-south-1

aws s3api put-bucket-versioning \
  --bucket harish-terraform-state-bucket \
  --versioning-configuration Status=Enabled


  cd rpsp_infra/iac/terraform

# Copy example and fill in real values
cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars: replace all REPLACE_WITH_... placeholders

terraform init -backend-config=environments/dev/backend.hcl -reconfigure
terraform plan -var-file=terraform.tfvars

cd ~/employeeBudget-Java-aws/rpsp_infra/iac/terraform
terraform init -backend-config=environments/dev/backend.hcl -reconfigure
terraform plan -var-file=terraform.tfvars