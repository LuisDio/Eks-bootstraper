resource "helm_release" "argocd_release" {
  repository = var.argo_repository
  chart      = var.argo_chart
  version    = var.argo_version

  name      = var.argo_name
  namespace = var.argo_namespace

  create_namespace = true

  values = var.argo_values
}
