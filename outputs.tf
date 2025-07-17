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