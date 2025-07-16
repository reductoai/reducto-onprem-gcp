resource "helm_release" "keda" {
  name             = "keda"
  repository       = "https://kedacore.github.io/charts"
  chart            = "keda"
  version          = "2.15.0"
  namespace        = "keda-system"
  create_namespace = true

  values = [
    "${file("values/keda.yaml")}"
  ]

  depends_on = [
    module.gke,
  ]
}