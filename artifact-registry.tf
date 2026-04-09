locals {
  artifact_registry_location = var.artifact_registry_location != "" ? var.artifact_registry_location : var.region
}

resource "google_artifact_registry_repository" "main" {
  location      = local.artifact_registry_location
  repository_id = var.artifact_registry_repository_id
  description   = "Docker images for Reducto on GCP"
  format        = "DOCKER"
  project       = var.project_id

  depends_on = [google_project_service.services["artifactregistry.googleapis.com"]]
}

# Default node service account (module.gke with create_service_account = true) must
# be able to pull images referenced by workloads on the nodes.
resource "google_artifact_registry_repository_iam_member" "gke_nodes_pull" {
  project    = var.project_id
  location   = google_artifact_registry_repository.main.location
  repository = google_artifact_registry_repository.main.repository_id
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:${module.gke.service_account}"
}

resource "google_service_account" "artifact_registry_push" {
  account_id   = var.artifact_registry_push_service_account_id
  display_name = "Artifact Registry image push"
  project      = var.project_id
}

resource "google_artifact_registry_repository_iam_member" "push_writer" {
  project    = var.project_id
  location   = google_artifact_registry_repository.main.location
  repository = google_artifact_registry_repository.main.repository_id
  role       = "roles/artifactregistry.writer"
  member     = google_service_account.artifact_registry_push.member
}
