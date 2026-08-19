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
  redis_configs = {
    "maxmemory-policy" = "noeviction"
  }

  transit_encryption_mode = "SERVER_AUTHENTICATION"

  depends_on = [
    google_project_service.services,
    module.private_service_access,
  ]
}

locals {
  chart_versions_with_redis_ca = ["1.12.3", "1.12.4", "1.12.6"]
  chart_supports_redis_ca      = contains(local.chart_versions_with_redis_ca, var.reducto_helm_chart_version)
  mount_managed_redis_ca       = coalesce(var.mount_managed_redis_ca, local.chart_supports_redis_ca)
  managed_redis_consumed       = var.enable_managed_redis && local.mount_managed_redis_ca

  redis_url = var.enable_managed_redis ? format(
    "rediss://default:%s@%s:%s",
    urlencode(google_redis_instance.reducto[0].auth_string),
    google_redis_instance.reducto[0].host,
    google_redis_instance.reducto[0].port,
  ) : null
}

resource "kubectl_manifest" "redis_ca" {
  count = local.managed_redis_consumed ? 1 : 0

  yaml_body = yamlencode({
    apiVersion = "v1"
    kind       = "Secret"
    metadata = {
      name      = "reducto-redis-ca"
      namespace = kubectl_manifest.namespace.name
    }
    type = "Opaque"
    stringData = {
      "ca.crt" = google_redis_instance.reducto[0].server_ca_certs[0].cert
    }
  })

  depends_on = [kubectl_manifest.namespace]
}
