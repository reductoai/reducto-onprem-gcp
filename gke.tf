data "google_compute_zones" "available" {
  project = var.project_id
  region  = var.region
  status  = "UP"
}

locals {
  # Filter out AI zones (e.g., us-central1-ai1a) as they are reserved for AI workloads
  # and may have different resource availability or pricing
  available_zones = [
    for zone in data.google_compute_zones.available.names : zone
    if !can(regex("-ai\\d+[a-z]$", zone))
  ]
  zones = slice(
    local.available_zones,
    0,
    min(3, length(local.available_zones))
  )
}

# GKE Standard
module "gke" {
  source  = "terraform-google-modules/kubernetes-engine/google//modules/private-cluster"
  version = "~> 38.0"

  project_id                  = var.project_id
  name                        = var.cluster_name
  regional                    = true
  region                      = var.region
  zones                       = local.zones
  network                     = module.network.network_name
  subnetwork                  = var.subnet_name
  ip_range_pods               = var.pods_cidr_name
  ip_range_services           = var.services_cidr_name
  create_service_account      = true
  enable_private_endpoint     = false
  enable_private_nodes        = true
  enable_cost_allocation      = true
  enable_intranode_visibility = true
  enable_shielded_nodes       = true
  default_max_pods_per_node   = 20
  remove_default_node_pool    = true
  deletion_protection         = var.deletion_protection

  node_pools = concat([
    {
      name               = "reducto-primary-node-pool"
      machine_type       = var.primary_machine_type
      total_min_count    = 2
      total_max_count    = 100
      location_policy    = "BALANCED"
      local_ssd_count    = 1
      disk_size_gb       = 100
      disk_type          = "pd-ssd"
      auto_repair        = true
      auto_upgrade       = true
      preemptible        = false
      max_pods_per_node  = 20
      enable_secure_boot = true
    },
    {
      name               = "reducto-secondary-node-pool"
      machine_type       = var.secondary_machine_type
      total_min_count    = 1
      total_max_count    = 100
      location_policy    = "BALANCED"
      local_ssd_count    = 1
      disk_size_gb       = 100
      disk_type          = "pd-ssd"
      auto_repair        = true
      auto_upgrade       = true
      preemptible        = false
      max_pods_per_node  = 20
      enable_secure_boot = true
    },
    {
      name               = "reducto-secondary-node-pool-preemptible"
      machine_type       = var.secondary_machine_type
      total_min_count    = 0
      total_max_count    = 100
      location_policy    = "BALANCED"
      local_ssd_count    = 1
      disk_size_gb       = 100
      disk_type          = "pd-ssd"
      auto_repair        = true
      auto_upgrade       = true
      preemptible        = true
      max_pods_per_node  = 20
      enable_secure_boot = true
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