resource "google_dns_managed_zone" "zone" {
  name        = var.name
  dns_name    = var.fqdn
  description = var.description
}

data "google_dns_managed_zone" "parent" {
  name    = var.parent_zone_name
  project = var.parent_project
}

resource "google_dns_record_set" "parent" {
  project      = var.parent_project
  managed_zone = data.google_dns_managed_zone.parent.name

  name = var.fqdn
  type = "NS"
  ttl  = 21600

  rrdatas = google_dns_managed_zone.zone.name_servers
}
