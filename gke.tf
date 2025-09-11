# GKE Standard
module "gke" {
  source  = "terraform-google-modules/kubernetes-engine/google//modules/private-cluster"
  version = "~> 38.0"

  project_id                = var.project_id
  name                      = var.cluster_name
  regional                  = true
  region                    = var.region
  network                   = module.network.network_name
  subnetwork                = var.subnet_name
  ip_range_pods             = var.pods_cidr_name
  ip_range_services         = var.services_cidr_name
  create_service_account    = true
  enable_private_endpoint   = false
  enable_private_nodes      = true
  default_max_pods_per_node = 20
  remove_default_node_pool  = true
  deletion_protection       = var.deletion_protection

  node_pools = concat([
    {
      name              = "reducto-c2d-highcpu-8"
      machine_type      = "c2d-highcpu-8"
      min_count         = 1
      max_count         = 100
      local_ssd_count   = 1
      disk_size_gb      = 100
      disk_type         = "pd-ssd"
      auto_repair       = true
      auto_upgrade      = true
      preemptible       = false
      max_pods_per_node = 20
    },
    {
      name              = "reducto-c2d-highcpu-16"
      machine_type      = "c2d-highcpu-16"
      min_count         = 1
      max_count         = 100
      local_ssd_count   = 1
      disk_size_gb      = 100
      disk_type         = "pd-ssd"
      auto_repair       = true
      auto_upgrade      = true
      preemptible       = false
      max_pods_per_node = 20
    },
    {
      name              = "reducto-c2d-highcpu-16-preemptible"
      machine_type      = "c2d-highcpu-16"
      min_count         = 0
      max_count         = 100
      local_ssd_count   = 1
      disk_size_gb      = 100
      disk_type         = "pd-ssd"
      auto_repair       = true
      auto_upgrade      = true
      preemptible       = true
      max_pods_per_node = 20
    },
  ], var.extra_node_pools)

  master_authorized_networks = [
    for cidr in concat(var.control_plane_allowed_cidrs, [var.subnet_cidr, var.pods_cidr, var.services_cidr]) : {
      cidr_block   = cidr
      display_name = "control plane authorized networks"
    }
  ]
}

# GKE Autopilot
# module "gke" {
#   source  = "terraform-google-modules/kubernetes-engine/google//modules/beta-autopilot-private-cluster"
#   version = "~> 37.0"

#   project_id                             = var.project_id
#   name                                   = var.cluster_name
#   regional                               = true
#   region                                 = var.region
#   network                                = module.network.network_name
#   subnetwork                             = var.subnet_name
#   ip_range_pods                          = var.pods_cidr_name
#   ip_range_services                      = var.services_cidr_name
#   release_channel                        = "REGULAR"
#   enable_vertical_pod_autoscaling        = true # required for GKE Autopilot
#   enable_private_endpoint                = false
#   enable_private_nodes                   = true
#   http_load_balancing                    = true
#   deletion_protection                    = var.deletion_protection
#   insecure_kubelet_readonly_port_enabled = false

#   master_authorized_networks = [
#     for cidr in concat(var.control_plane_allowed_cidrs, [var.subnet_cidr, var.pods_cidr, var.services_cidr]) : {
#       cidr_block   = cidr
#       display_name = "control plane authorized networks"
#     }
#   ]
# }