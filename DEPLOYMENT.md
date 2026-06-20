# End-to-End Deployment Guide

## 1. Prerequisites

- AWS account and IAM permissions for EKS/ECR
- Existing EKS cluster: `webapp-eks-cluster`
- `kubectl`, `helm`, `terraform`, `aws` CLI installed
- ArgoCD and Argo Rollouts installed in cluster
- NGINX ingress controller installed in cluster

## 2. Terraform (EKS + ECR + Namespace)

```bash
cd infra/terraform
terraform init
terraform plan -var-file=terraform.tfvars.example
terraform apply -var-file=terraform.tfvars.example
```

## 3. Build and Push Docker Images

Option A: Use GitHub Actions pipeline from `.github/workflows/ci-cd.yml`

Option B: Local push

```bash
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 495013583028.dkr.ecr.us-east-1.amazonaws.com

docker build -f services/employee-service/Dockerfile -t 495013583028.dkr.ecr.us-east-1.amazonaws.com/employee-service:<tag> .
docker build -f services/project-service/Dockerfile -t 495013583028.dkr.ecr.us-east-1.amazonaws.com/project-service:<tag> .
docker build -f services/budget-service/Dockerfile -t 495013583028.dkr.ecr.us-east-1.amazonaws.com/budget-service:<tag> .

docker push 495013583028.dkr.ecr.us-east-1.amazonaws.com/employee-service:<tag>
docker push 495013583028.dkr.ecr.us-east-1.amazonaws.com/project-service:<tag>
docker push 495013583028.dkr.ecr.us-east-1.amazonaws.com/budget-service:<tag>
```

## 4. Configure GitOps Overlay

1. Edit `gitops/overlays/<env>/kustomization.yaml`
2. Set `newName` to real ECR repo URL
3. Set `newTag` to image tag (usually git SHA)
4. Commit and push to git

## 5. ArgoCD Applications

Update repo URL in:
- `argocd/app-dev.yaml`
- `argocd/app-qa.yaml`
- `argocd/app-prod.yaml`

Apply to cluster:

```bash
kubectl apply -f argocd/app-dev.yaml
kubectl apply -f argocd/app-qa.yaml
kubectl apply -f argocd/app-prod.yaml
```

## 6. Domain Access (Namecheap + Cloudflare)

1. In Namecheap, use Cloudflare nameservers
2. Get ingress external endpoint:

```bash
kubectl get svc -n ingress-nginx ingress-nginx-controller
```

3. In Cloudflare DNS, create record:
- Type: CNAME or A
- Name: `app` (or `dev`, `qa`)
- Value: ingress endpoint
- Proxy: Enabled (orange cloud)

4. Update hosts in overlays:
- dev: `dev.harishweb.online`
- qa: `qa.harishweb.online`
- prod: `app.harishweb.online`

5. Ensure TLS secret exists (`dev-app-tls`, `qa-app-tls`, `prod-app-tls`)

## 7. Blue/Green Deployments

Rollout resources are already defined with:
- active service
- preview service
- autoPromotionEnabled: false

Promote manually:

```bash
kubectl argo rollouts get rollout employee-service -n dda-app
kubectl argo rollouts promote employee-service -n dda-app
```

Repeat for project and budget services.

## 8. API Access

- Employee REST examples:
  - `POST /employee/addEmp`
  - `PUT /employee/updateEmp?id=1`
  - `DELETE /employee/deleteEmp?id=1`
  - `GET /employee/getEmp?id=1`

- Project GraphQL endpoint:
  - `POST /graphql/project`

- Budget GraphQL endpoint:
  - `POST /graphql/budget`

## 9. Local Service Layout

- Infra stack: `infra/docker-compose.yml`
- Employee service compose: `services/employee-service/docker-compose.yml`
- Project service compose: `services/project-service/docker-compose.yml`
- Budget service compose: `services/budget-service/docker-compose.yml`
