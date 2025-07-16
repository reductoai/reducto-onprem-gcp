resource "random_string" "bucket_name_suffix" {
  length  = 4
  special = false
  lower   = true
  upper   = false
}

resource "google_storage_bucket" "private_bucket" {
  name     = "${var.bucket_name_prefix}-${random_string.bucket_name_suffix.result}"
  location = var.region
  project  = var.project_id

  uniform_bucket_level_access = true

  public_access_prevention = "enforced"

  versioning {
    enabled = false
  }

  # Lifecycle management
  lifecycle_rule {
    condition {
      age = 1
    }
    action {
      type = "Delete"
    }
  }

  # CORS configuration
  cors {
    origin          = ["*"]
    method          = ["GET", "PUT"]
    response_header = ["*"]
  }

  force_destroy = !var.deletion_protection
}


