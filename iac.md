rpsp_infra/iac/
├── helm/
│   ├── nginx/                   ← NGINX Ingress Helm chart
│   │   ├── Chart.yaml
│   │   ├── values.yaml          ← base (rate-limit, CORS, TLS toggles)
│   │   ├── values-{dev,qa,prod}.yaml
│   │   └── templates/
│   │       ├── _helpers.tpl     ← FQDN builder, labels
│   │       ├── ingress.yaml     ← env-aware, regex paths, security headers
│   │       └── configmap.yaml   ← NGINX tuning params
│   └── apps/                    ← All 3 microservices Helm chart
│       ├── values.yaml          ← one file controls all 3 services
│       ├── values-{dev,qa,prod}.yaml
│       └── templates/
│           ├── rollout.yaml     ← Argo Rollout blue/green (hardened)
│           ├── service.yaml     ← active + preview services per svc
│           ├── hpa.yaml         ← HPA with scale-up/down stabilization
│           └── pdb.yaml         ← PodDisruptionBudget (prod only)
├── terraform/
│   ├── versions.tf, variables.tf, main.tf, outputs.tf
│   ├── modules/
│   │   ├── ecr/   ← repos, lifecycle policies (immutable tags, auto-cleanup)
│   │   ├── lambda/← IAM, SQS queue, DLQ, EventBridge rule, X-Ray, CW alarms
│   │   └── batch/ ← Fargate compute env, job queue, job definition, EventBridge cron, alarms
│   └── environments/
│       ├── dev/main.tf   ← S3 remote state, dev-scoped vars
│       └── prod/main.tf  ← S3 remote state, prod-scoped vars + SNS alerts
├── lambda/short-execution/
│   ├── handler.py         ← Routes employee/budget/project events, SQS batch consumer
│   ├── requirements.txt
│   └── Makefile           ← clean/install/package/deploy
└── batch/night-job/
    ├── processor.py        ← 4 jobs: reconcile, snapshot, report, archive
    ├── requirements.txt
    └── Dockerfile          ← multi-stage, non-root user, Graviton-ready




 Key design decisions
Concern	Decision
Lambda timeout	5 min max, SQS + EventBridge triggers, partial-batch-failure support
Batch trigger	EventBridge cron cron(0 1 * * ? *) → Batch Fargate → 2h hard limit
Batch compute	Fargate (no EC2 fleet to manage), auto-scales to 16 vCPU in prod
Secrets	DB password fetched from Secrets Manager at runtime — never in env plaintext
Prod readiness	HPA, PDB, CloudWatch alarms on Lambda errors, Batch failures, DLQ depth
ECR	Immutable tags, scan-on-push, lifecycle rules keep ≤10 prod / ≤5 dev images   