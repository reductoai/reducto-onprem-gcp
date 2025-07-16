module "network" {
  source  = "terraform-google-modules/network/google"
  version = ">= 7.5"

  project_id   = var.project_id
  network_name = var.network_name

  subnets = [
    {
      subnet_name           = var.subnet_name
      subnet_ip             = var.subnet_cidr
      subnet_region         = var.region
      subnet_private_access = true
    },
    {
      subnet_name   = "reducto-regional-proxy"
      subnet_ip     = var.regional_proxy_subnet_cidr
      subnet_region = var.region
      role          = "ACTIVE"
      purpose       = "REGIONAL_MANAGED_PROXY"
    },
  ]

  secondary_ranges = {
    (var.subnet_name) = [
      {
        range_name    = var.pods_cidr_name
        ip_cidr_range = var.pods_cidr
      },
      {
        range_name    = var.services_cidr_name
        ip_cidr_range = var.services_cidr
      }
    ]
  }
}

# NAT and router to allowed private nodes to download Reducto image
resource "google_compute_router" "router" {
  project = var.project_id
  name    = "reducto-nat-router"
  network = module.network.network_name
  region  = var.region
}

module "cloud-nat" {
  source                             = "terraform-google-modules/cloud-nat/google"
  version                            = "~> 5.0"
  project_id                         = var.project_id
  region                             = var.region
  router                             = google_compute_router.router.name
  name                               = "reducto-nat"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

module "private_service_access" {
  source  = "terraform-google-modules/sql-db/google//modules/private_service_access"
  version = "~> 26.1"

  project_id  = var.project_id
  vpc_network = module.network.network_name

  depends_on = [module.network]
}