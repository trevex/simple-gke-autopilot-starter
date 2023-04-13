resource "kubernetes_namespace" "cert_manager" {
  metadata {
    name = "cert-manager"
  }
}

module "wi" {
  source = "..//workload-identity"

  project   = var.project
  name      = "cert-manager"
  namespace = kubernetes_namespace.cert_manager.metadata[0].name
  roles     = ["roles/dns.admin"]
}

resource "helm_release" "cert_manager" {
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = var.chart_version

  name      = "cert-manager"
  namespace = kubernetes_namespace.cert_manager.metadata[0].name

  set {
    name  = "fullnameOverride"
    value = "cert-manager"
  }
  set {
    name  = "serviceAccount.name"
    value = module.wi.k8s_service_account_name
  }
  set {
    name  = "serviceAccount.create"
    value = "false"
  }
  set {
    name  = "installCRDs"
    value = "true"
  }
  set {
    name  = "prometheus.enabled"
    value = "false"
  }
  set {
    name  = "global.leaderElection.namespace"
    value = kubernetes_namespace.cert_manager.metadata[0].name
  }
}

# Unable to use `kubernetes_manifest` for this:
# https://github.com/hashicorp/terraform-provider-kubernetes-alpha/issues/235
resource "helm_release" "letsencrypt" {
  name      = "letsencrypt"
  namespace = kubernetes_namespace.cert_manager.metadata[0].name
  chart     = "${path.module}/letsencrypt-chart"

  set {
    name  = "email"
    value = var.letsencrypt_email
  }
  set {
    name  = "projectID"
    value = var.project
  }
  set {
    name  = "dnsZones"
    value = "{${join(",", [for zone in var.dns_zones : replace(zone, "/\\.\\z/", "")])}}"
  }

  depends_on = [helm_release.cert_manager]
}
