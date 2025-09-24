
# EKS + VPC + Argo CD (Terraform)

This repository provisions an AWS VPC and an Amazon EKS cluster, then bootstraps Argo CD on the cluster — all via Terraform.

Overview
- Provision VPC (private/public subnets, IGW, NATs, route tables)
- Provision EKS control plane + node groups
- Install Argo CD via a Terraform module that uses `helm_release`
- Provide access and troubleshooting steps

Prerequisites
- macOS (commands below assume macOS)
- AWS CLI configured with an account that can create VPCs, EKS, IAM, EC2, ELB
- Terraform >= 1.0
- kubectl
- helm (optional for manual steps)
- jq (optional)

Repository layout
- modules/
  - vpc/        — VPC, subnets, routing
  - eks/        — EKS cluster & node groups
  - argocd/     — Helm-based Argo CD install (helm_release)
- environments/
  - dev/        — environment root Terraform that composes modules
- README.md

High-level flow
1. Create VPC and networking resources.
2. Create EKS control plane and node groups.
3. Configure kubectl to point to the new cluster.
4. Install Argo CD using the modules/argocd Terraform module (uses `helm_release`).

Apply sequence (recommended)
1. Initialize and apply infra (VPC + EKS)
```bash
# from your environment root (e.g. environments/dev)
terraform init
terraform plan -var-file=terraform.tfvars
terraform apply -var-file=terraform.tfvars
```

2. Configure kubectl for the new cluster
```bash
aws eks --region <region> update-kubeconfig --name <cluster_name>
kubectl get nodes
```

3. Deploy Argo CD (module uses helm_release)
```bash
# from the same Terraform root that declares module "argocd"
terraform init
terraform apply -var-file=terraform.tfvars
```
Ensure kubeconfig is available to the Helm provider (common approach: aws eks update-kubeconfig).

Argocd module (modules/argocd)
- Purpose: install Argo CD chart via Terraform `helm_release`.
- Inputs (typical): chart repo, chart name, values, namespace, release name.
- Minimal implementation (inside modules/argocd/main.tf):
```hcl
resource "helm_release" "argocd" {
  name             = var.release_name
  repository       = var.chart_repository # e.g. "https://argoproj.github.io/argo-helm"
  chart            = var.chart_name       # e.g. "argo-cd"
  namespace        = var.namespace
  create_namespace = true
  values           = var.values           # list of YAML strings or maps
}
```
Expose useful outputs such as the argocd-server service address.

Accessing Argo CD
- If `server.service.type = LoadBalancer`:
```bash
kubectl -n argocd get svc argocd-server
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 --decode
# login: user "admin" + retrieved password
```
- If no LB: use port-forward
```bash
kubectl -n argocd port-forward svc/argocd-server 8080:443
# open http://localhost:8080
```

Recommended Terraform outputs (root)
- cluster endpoint / name
- kubeconfig command
- argocd server address (if module exposes it)

Best practices
- Pin provider, module and chart versions.
- Keep sensitive data out of committed tfvars (use environment variables or secrets manager).
- Use least-privilege IAM roles for production.
- Prefer private EKS and secure Ingress + DNS for production Argo CD.
- Make Helm provider use explicit Kubernetes provider config (endpoint, token, ca) for CI.

Troubleshooting
- Nodes not joining: verify node IAM role policies, subnets, and security groups.
- Helm release failing: inspect Terraform error and `kubectl -n argocd describe deployment` / `kubectl logs`.
- Argo CD admin secret missing: ensure release completed and namespace exists.

References
- AWS EKS docs: https://docs.aws.amazon.com/eks/latest/userguide/what-is-eks.html
- Argo CD Helm chart: https://github.com/argoproj/argo-helm
- Terraform Helm provider: https://registry.terraform.io/providers/hashicorp/helm

License: MIT