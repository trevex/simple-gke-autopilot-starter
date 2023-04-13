output "cluster_id" {
  value = module.cluster.id
}

output "artifact_repository_id" {
  value = google_artifact_registry_repository.images.id
}
