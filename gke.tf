module "gke" {
  source  = "terraform-google-modules/kubernetes-engine/google//modules/beta-autopilot-private-cluster"
  version = "~> 37.0"

  project_id                             = var.project_id
  name                                   = var.cluster_name
  regional                               = true
  region                                 = var.region
  network                                = module.network.network_name
  subnetwork                             = var.subnet_name
  ip_range_pods                          = var.pods_cidr_name
  ip_range_services                      = var.services_cidr_name
  release_channel                        = "REGULAR"
  enable_vertical_pod_autoscaling        = true # required for GKE Autopilot
  enable_private_endpoint                = false
  enable_private_nodes                   = true
  http_load_balancing                    = true
  deletion_protection                    = var.deletion_protection
  insecure_kubelet_readonly_port_enabled = false

  master_authorized_networks = [
    for cidr in concat(var.control_plane_allowed_cidrs, [var.subnet_cidr, var.pods_cidr, var.services_cidr]) : {
      cidr_block   = cidr
      display_name = "control plane authorized networks"
    }
  ]
}