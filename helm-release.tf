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

  values = concat(
    [
      file("${path.module}/values/reducto.yaml"),
      var.datadog_api_key != "" ? yamlencode(local.otel_env_vars) : "",
      yamlencode({
        # Keep dual-stack DNS behavior explicit for this portable deployment.
        dnsConfigNoAAAA = false
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
        # Chart 1.12.6 contains Streaq, but the legacy baseline keeps it
        # disabled until a deployment explicitly opts into those workloads.
        streaqWorkerDefaults = {
          enabled = false
        }
        streaqWorkers = {}
        # Keep the credentials JSON out of Deployment and Pod specs. Chart
        # 1.12.6 stores secretEnv.stringData in a release-scoped Secret.
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
          }, local.managed_redis_consumed ? {
          REDIS_URL = local.redis_url
        } : {})
        redis = merge(
          { enabled = false },
          local.managed_redis_consumed ? {
            tls = {
              existingSecret = "reducto-redis-ca"
              key            = "ca.crt"
              mountPath      = "/etc/reducto/redis-tls/ca.crt"
              checksum       = sha256(google_redis_instance.reducto[0].server_ca_certs[0].cert)
            }
          } : {},
        )
      })
    ],
    [for values_path in var.reducto_extra_values_files : file(values_path)],
  )

  depends_on = [
    module.gke,
    google_storage_bucket.private_bucket,
    module.network,
    helm_release.keda,
    kubectl_manifest.backend_config,
    kubectl_manifest.redis_ca,
    google_redis_instance.reducto,
  ]
}
