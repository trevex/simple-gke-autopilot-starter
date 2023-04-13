output "id" {
  value = google_container_cluster.cluster.id
}

output "name" {
  value = google_container_cluster.cluster.name
}

output "host" {
  value = "https://${google_container_cluster.cluster.endpoint}"
}

output "cluster_ca_certificate" {
  value = base64decode(google_container_cluster.cluster.master_auth[0].cluster_ca_certificate)
}

output "cluster_sa_email" {
  value = google_service_account.cluster.email
}
