resource "google_service_account" "service_account" {
  account_id   = var.reducto_service_account_name
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
  service_account_key      = base64decode(google_service_account_key.service_account_key.private_key)
  service_account_key_json = jsonencode(local.service_account_key)
}

resource "google_project_iam_member" "service_account_token_creator" {
  project = var.project_id
  role    = "roles/iam.serviceAccountTokenCreator"
  member  = "serviceAccount:${google_service_account.service_account.email}"
}

## WORKLOAD IDENTITY
# Docs: https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity#kubernetes-sa-to-iam

resource "google_project_iam_member" "service_usage_consumer" {
  # for vision.googleapis.com
  count   = var.workload_identity ? 1 : 0
  project = var.project_id
  role    = "roles/serviceusage.serviceUsageConsumer"
  member  = "serviceAccount:${google_service_account.service_account.email}"
}


resource "google_service_account_iam_member" "workload_identity_user" {
  count              = var.workload_identity ? 1 : 0
  service_account_id = google_service_account.service_account.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[${local.namespace_name}/${local.release_name}-reducto]"
}