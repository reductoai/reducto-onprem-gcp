resource "google_project_service" "services" {
  for_each = toset(var.enable_apis)
  project  = var.project_id
  service  = each.value

  disable_on_destroy = false
}

resource "random_string" "api_key_name_suffix" {
  length  = 4
  special = false
  lower   = true
  upper   = false
}

resource "google_apikeys_key" "vision" {
  name         = "reducto-${random_string.api_key_name_suffix.result}"
  display_name = "Reducto Cloud Vision Key"
  project      = var.project_id

  depends_on = [google_project_service.services]
}