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

  depends_on = [module.gke]
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

  values = [
    "${file("values/reducto.yaml")}",
    <<-EOT
    http:
      service:
        annotations:
          cloud.google.com/backend-config: '{"ports": {"80":"${local.backend_config_name}"}}'
    ingress:
      host: ${var.reducto_host}
    env:
      GCP_PROJECT_ID: ${var.project_id}
      GCP_REGION: ${var.region}
      GCP_API_KEY: ${google_apikeys_key.vision.key_string}
      GCP_ACCESS_KEY_ID: ${google_storage_hmac_key.s3_compatible_key.access_id}
      GCP_SECRET_ACCESS_KEY: ${google_storage_hmac_key.s3_compatible_key.secret}
      GOOGLE_APPLICATION_CREDENTIALS: ${local.service_account_key_json}
      BUCKET: ${google_storage_bucket.private_bucket.name}
      DATABASE_URL: ${local.database_url}
    EOT
  ]

  depends_on = [
    module.gke,
    google_storage_bucket.private_bucket,
    module.network,
    helm_release.keda,
    kubectl_manifest.backend_config,
  ]
}

data "kubernetes_ingress_v1" "ingress" {
  metadata {
    name      = "${helm_release.reducto.name}-reducto-http-ingress"
    namespace = kubectl_manifest.namespace.name
  }
  depends_on = [helm_release.reducto]
}