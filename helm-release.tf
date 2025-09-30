locals {
  backend_config_name = "reducto-backendconfig"
  namespace_name      = "reducto"
  release_name        = "reducto"
}

resource "kubectl_manifest" "namespace" {
  yaml_body = <<-EOT
    apiVersion: v1
    kind: Namespace
    metadata:
      name: ${local.namespace_name}
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

locals {
  # Presense of GCP_SERVICE_ACCOUNT_EMAIL indicates that workload identity is being used.
  # Node selector is only for Standard cluster not for Autopilot.
  with_workload_identity_yaml = <<-WIYAML
    http:
      nodeSelector:
        iam.gke.io/gke-metadata-server-enabled: "true"

    worker:
      nodeSelector:
        iam.gke.io/gke-metadata-server-enabled: "true"

    serviceAccount:
      annotations:
        iam.gke.io/gcp-service-account: ${google_service_account.service_account.email}

    env:
      GCP_PROJECT_ID: ${var.project_id}
      GCP_REGION: ${var.region}
      GCP_SERVICE_ACCOUNT_EMAIL: ${google_service_account.service_account.email}
      BUCKET: ${google_storage_bucket.private_bucket.name}
      DATABASE_URL: ${local.database_url}
   WIYAML

  with_service_account_key_yaml = <<-SAKYAML
   env:
     GCP_PROJECT_ID: ${var.project_id}
     GCP_REGION: ${var.region}
     GCP_API_KEY: ${google_apikeys_key.vision.key_string}
     GCP_ACCESS_KEY_ID: ${google_storage_hmac_key.s3_compatible_key.access_id}
     GCP_SECRET_ACCESS_KEY: ${google_storage_hmac_key.s3_compatible_key.secret}
     GOOGLE_APPLICATION_CREDENTIALS: ${local.service_account_key_json}
     BUCKET: ${google_storage_bucket.private_bucket.name}
     DATABASE_URL: ${local.database_url}
   SAKYAML
}

resource "helm_release" "reducto" {
  namespace        = kubectl_manifest.namespace.name
  name             = local.release_name
  create_namespace = false

  repository_username = var.reducto_helm_repo_username
  repository_password = var.reducto_helm_repo_password

  chart   = var.reducto_helm_chart_oci
  version = var.reducto_helm_chart_version
  wait    = false

  values = [
    "${file("values/reducto.yaml")}",
    var.workload_identity ? local.with_workload_identity_yaml : local.with_service_account_key_yaml,
    <<-EOT
    http:
      service:
        annotations:
          cloud.google.com/backend-config: '{"ports": {"80":"${local.backend_config_name}"}}'
    ingress:
      host: ${var.reducto_host}
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