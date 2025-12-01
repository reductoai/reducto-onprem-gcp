# SSL Policy to enforce TLS 1.2+ (disable TLS 1.0 and TLS 1.1)
# https://cloud.google.com/load-balancing/docs/ssl-policies-concepts
resource "google_compute_ssl_policy" "reducto" {
  name            = "reducto-ssl-policy"
  project         = var.project_id
  min_tls_version = "TLS_1_2"
  profile         = "MODERN"
}

# FrontendConfig to reference the SSL policy for the ingress
resource "kubectl_manifest" "frontend_config" {
  yaml_body = <<-EOT
    apiVersion: networking.gke.io/v1beta1
    kind: FrontendConfig
    metadata:
      namespace: ${kubectl_manifest.namespace.name}
      name: reducto-frontendconfig
    spec:
      sslPolicy: ${google_compute_ssl_policy.reducto.name}
    EOT

  depends_on = [
    kubectl_manifest.namespace,
    google_compute_ssl_policy.reducto,
  ]
}
