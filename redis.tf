resource "google_redis_instance" "reducto" {
  count = var.enable_managed_redis ? 1 : 0

  project            = var.project_id
  region             = var.region
  name               = "${var.cluster_name}-redis"
  display_name       = "Reducto managed Redis"
  tier               = var.managed_redis_tier
  memory_size_gb     = var.managed_redis_memory_size_gb
  redis_version      = var.managed_redis_version
  auth_enabled       = true
  authorized_network = module.network.network_self_link
  connect_mode       = "PRIVATE_SERVICE_ACCESS"

  transit_encryption_mode = "SERVER_AUTHENTICATION"

  depends_on = [
    google_project_service.services,
    module.private_service_access,
  ]
}

locals {
  redis_url = var.enable_managed_redis ? format(
    "rediss://default:%s@%s:%s",
    urlencode(google_redis_instance.reducto[0].auth_string),
    google_redis_instance.reducto[0].host,
    google_redis_instance.reducto[0].port,
  ) : null
}
