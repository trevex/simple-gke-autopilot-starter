terraform {
  backend "gcs" {
    bucket = "nvoss-terraform-dev" # TODO: CHANGEME
    prefix = "terraform/dev"
  }
}

provider "google" {
  project = var.project
  region  = var.region
}

provider "google-beta" {
  project = var.project
  region  = var.region
}


# Enable required APIs

resource "google_project_service" "services" {
  for_each = toset([
    "cloudresourcemanager.googleapis.com",
    "compute.googleapis.com",
    "container.googleapis.com",
    "iam.googleapis.com",
    "artifactregistry.googleapis.com",
    "dns.googleapis.com",
  ])
  project = var.project
  service = each.value
}


# Let's create our artifact registry for our container-images

resource "google_artifact_registry_repository" "images" {
  #checkov:skip=CKV_GCP_84:We do not want to use CSEK
  location      = var.region
  repository_id = "images"
  description   = "Primary container-image registry"
  format        = "DOCKER"

  depends_on = [google_project_service.services]
}


# The underlying network mainly for the cluster

locals {
  cluster_secondary_range_name  = "pods"
  services_secondary_range_name = "services"
}

module "network" {
  source = "../../modules//network"

  name = "network-dev"
  subnetworks = [{
    name_affix    = "main" # full name will be `${name}-${name_affix}-${region}`
    ip_cidr_range = "10.10.0.0/20"
    region        = var.region
    secondary_ip_range = [{ # Use larger ranges in production!
      range_name    = local.cluster_secondary_range_name
      ip_cidr_range = "10.10.32.0/19"
      }, {
      range_name    = local.services_secondary_range_name
      ip_cidr_range = "10.10.16.0/20"
    }]
  }]

  depends_on = [google_project_service.services]
}

# Dedicated zone for our environment

module "dns_zone" {
  source = "../../modules//dns-zone"

  parent_project   = var.dns_project
  parent_zone_name = var.dns_zone_name

  name = "nvoss-dev"
  fqdn = var.dns_dedicated_fqdn

  depends_on = [google_project_service.services]
}


# Create GKE Autopilot cluster in the network

module "cluster" {
  source = "../../modules//cluster"

  name                   = "cluster-dev"
  project                = var.project
  region                 = var.region
  network_id             = module.network.id
  subnetwork_id          = module.network.subnetworks["network-dev-main-${var.region}"].id
  master_ipv4_cidr_block = "172.16.0.0/28"

  cluster_secondary_range_name  = local.cluster_secondary_range_name
  services_secondary_range_name = local.services_secondary_range_name

  depends_on = [module.network]
}

# The service account used by the nodes should have read access to our private images without a pullSecret

resource "google_artifact_registry_repository_iam_member" "cluster_ar_reader" {
  project    = google_artifact_registry_repository.images.project
  location   = google_artifact_registry_repository.images.location
  repository = google_artifact_registry_repository.images.name

  role   = "roles/artifactregistry.reader"
  member = "serviceAccount:${module.cluster.cluster_sa_email}"
}

# Let's setup some K8s components such as external-dns and cert-manager

data "google_client_config" "cluster" {}

provider "kubernetes" {
  host                   = module.cluster.host
  token                  = data.google_client_config.cluster.access_token
  cluster_ca_certificate = module.cluster.cluster_ca_certificate
}

provider "helm" {
  kubernetes {
    host                   = module.cluster.host
    token                  = data.google_client_config.cluster.access_token
    cluster_ca_certificate = module.cluster.cluster_ca_certificate
  }
}

# External DNS

module "external_dns" {
  source = "../../modules//external-dns"

  project       = var.project
  chart_version = var.external_dns_version
  dns_zones     = [module.dns_zone.fqdn]
}

# Cert-Manager

module "cert_manager" {
  source = "../../modules//cert-manager"

  project           = var.project
  chart_version     = var.cert_manager_version
  dns_zones         = [module.dns_zone.fqdn]
  letsencrypt_email = var.letsencrypt_email
}

