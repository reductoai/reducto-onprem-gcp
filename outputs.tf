output "bucket_name" {
  description = "The name of the private GCS bucket"
  value       = google_storage_bucket.private_bucket.name
}

output "bucket_url" {
  description = "The URL of the private GCS bucket"
  value       = google_storage_bucket.private_bucket.url
}

output "google_access_key_id" {
  description = "The access key ID for S3 compatible access to the bucket"
  value       = google_storage_hmac_key.s3_compatible_key.access_id
  sensitive   = true
}

output "google_secret_access_key" {
  description = "The secret access key for S3 compatible access to the bucket"
  value       = google_storage_hmac_key.s3_compatible_key.secret
  sensitive   = true
}

output "database_url" {
  description = "The URL of the database"
  value       = local.database_url
  sensitive   = true
}

output "service_account_key" {
  description = "The key for the Reducto service account"
  value       = local.service_account_key
  sensitive   = true
}

output "vpc_network_name" {
  description = "The name of the VPC network created for Reducto"
  value       = module.network.network_name
}

output "artifact_registry_repository_id" {
  description = "Artifact Registry repository ID"
  value       = google_artifact_registry_repository.main.repository_id
}

output "artifact_registry_location" {
  description = "Region where the Artifact Registry repository is hosted"
  value       = google_artifact_registry_repository.main.location
}

output "artifact_registry_docker_url" {
  description = "Docker registry hostname for docker push/pull (REGION-docker.pkg.dev/PROJECT/REPO)"
  value       = "${google_artifact_registry_repository.main.location}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.main.repository_id}"
}

output "artifact_registry_push_service_account_email" {
  description = "Service account email for pushing images to Artifact Registry (use with Workload Identity Federation, gcloud auth activate-service-account, or a manually created key)"
  value       = google_service_account.artifact_registry_push.email
}
