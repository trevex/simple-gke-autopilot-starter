resource "kubernetes_namespace" "dns" {
  metadata {
    name = "external-dns"
  }
}

module "wi" {
  source = "..//workload-identity"

  project   = var.project
  name      = "external-dns"
  namespace = kubernetes_namespace.dns.metadata[0].name
  roles     = ["roles/dns.admin"]
}

resource "helm_release" "external_dns" {
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "external-dns"
  version    = trimprefix(var.chart_version, "v")

  name      = "external-dns"
  namespace = kubernetes_namespace.dns.metadata[0].name

  set {
    name  = "fullnameOverride"
    value = "external-dns"
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
    name  = "provider"
    value = "google"
  }
  set {
    name  = "google.project"
    value = var.project
  }
  set {
    name  = "domainFilters"
    value = "{${join(",", [for zone in var.dns_zones : replace(zone, "/\\.\\z/", "")])}}"
  }
}
