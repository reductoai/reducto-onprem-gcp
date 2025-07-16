resource "random_string" "db_password" {
  length  = 16
  special = false
  upper   = true
  lower   = true
  numeric = true
}

resource "random_string" "db_name_suffix" {
  length  = 4
  special = false
  lower   = true
  upper   = false
}

module "pg" {
  source  = "terraform-google-modules/sql-db/google//modules/postgresql"
  version = "~> 26.0"

  name                 = "reducto-db-${random_string.db_name_suffix.result}"
  random_instance_name = false
  project_id           = var.project_id
  database_version     = "POSTGRES_16"
  region               = var.region


  tier                            = var.db_tier
  availability_type               = var.db_availability_type
  maintenance_window_day          = 7
  maintenance_window_hour         = 12
  maintenance_window_update_track = "stable"
  edition                         = "ENTERPRISE"

  use_autokey         = false
  deletion_protection = var.deletion_protection

  ip_configuration = {
    ipv4_enabled       = false
    ssl_mode           = "ENCRYPTED_ONLY"
    private_network    = module.network.network_self_link
    allocated_ip_range = null
  }

  backup_configuration = {
    enabled = false
  }

  db_name               = local.db_name
  db_charset            = "UTF8"
  db_collation          = "en_US.UTF8"
  disk_size             = 20
  disk_autoresize       = true
  disk_autoresize_limit = 100

  user_name     = local.db_user
  user_password = random_string.db_password.result

  depends_on = [module.private_service_access]
}


locals {
  db_name      = "reducto"
  db_user      = "reducto"
  database_url = "postgresql://${local.db_user}:${random_string.db_password.result}@${module.pg.private_ip_address}:5432/${local.db_name}"
}