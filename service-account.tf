resource "google_service_account" "service_account" {
  account_id   = "reducto-sa"
  display_name = "Reducto Service Account"
  project      = var.project_id
}

resource "google_storage_bucket_iam_member" "gcs_object_admin" {
  bucket = google_storage_bucket.private_bucket.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.service_account.email}"
}

resource "google_project_iam_member" "vertex_ai" {
  project = var.project_id
  role    = "roles/aiplatform.user"
  member  = "serviceAccount:${google_service_account.service_account.email}"
}

resource "google_storage_hmac_key" "s3_compatible_key" {
  service_account_email = google_service_account.service_account.email
}

resource "google_service_account_key" "service_account_key" {
  service_account_id = google_service_account.service_account.name
}

locals {
  service_account_key = base64decode(google_service_account_key.service_account_key.private_key)
}