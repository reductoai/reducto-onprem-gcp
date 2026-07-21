locals {
  backend_config_name = "reducto-backendconfig"
}

resource "kubectl_manifest" "namespace" {
  yaml_body = <<-EOT
    apiVersion: v1
    kind: Namespace
    metadata:
      name: reducto
    EOT
}

resource "kubectl_manifest" "backend_config" {
  yaml_body = <<-EOT
    apiVersion: cloud.google.com/v1
    kind: BackendConfig
    metadata:
      namespace: ${kubectl_manifest.namespace.name}
      name: ${local.backend_config_name}
    spec:
      timeoutSec: 900
      connectionDraining:
        drainingTimeoutSec: 300
    EOT
}

resource "helm_release" "reducto" {
  namespace        = kubectl_manifest.namespace.name
  name             = "reducto"
  create_namespace = false

  repository_username = var.reducto_helm_repo_username
  repository_password = var.reducto_helm_repo_password

  chart   = var.reducto_helm_chart_oci
  version = var.reducto_helm_chart_version
  wait    = true
  timeout = var.helm_release_timeout

  values = [
    file("${path.module}/values/reducto.yaml"),
    var.datadog_api_key != "" ? yamlencode(local.otel_env_vars) : "",
    yamlencode({
      # Chart 1.12.2 compatibility defaults for dual-stack DNS and Kubernetes
      # 1.33 traffic-distribution validation.
      dnsConfigNoAAAA        = false
      setTrafficDistribution = "PreferClose"
      http = {
        service = {
          annotations = {
            "cloud.google.com/backend-config" = jsonencode({ ports = { "80" = local.backend_config_name } })
          }
        }
      }
      ingress = {
        host = var.reducto_host
      }
      # Chart 1.12.2 contains Streaq, but the certified legacy baseline keeps
      # it disabled until a deployment explicitly opts into those workloads.
      streaqWorkerDefaults = {
        enabled = false
      }
      streaqWorkers = {}
      redis = {
        enabled = false
      }
      # Keep the credentials JSON out of Deployment and Pod specs. Chart
      # 1.12.2 stores secretEnv.stringData in a release-scoped Secret.
      secretEnv = {
        create = true
        stringData = {
          GOOGLE_APPLICATION_CREDENTIALS = local.service_account_key_json
        }
      }
      env = merge({
        GCP_PROJECT_ID        = var.project_id
        GCP_REGION            = var.region
        GCP_API_KEY           = google_apikeys_key.vision.key_string
        GCP_ACCESS_KEY_ID     = google_storage_hmac_key.s3_compatible_key.access_id
        GCP_SECRET_ACCESS_KEY = google_storage_hmac_key.s3_compatible_key.secret
        BUCKET                = google_storage_bucket.private_bucket.name
        DATABASE_URL          = local.database_url
        }, var.enable_managed_redis ? {
        REDIS_URL = local.redis_url
      } : {})
    })
  ]

  depends_on = [
    module.gke,
    google_storage_bucket.private_bucket,
    module.network,
    helm_release.keda,
    kubectl_manifest.backend_config,
    google_redis_instance.reducto,
  ]
}
