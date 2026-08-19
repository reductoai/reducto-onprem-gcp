variable "project_id" {
  type        = string
  description = "The ID of the project where the network will be created"
}


# https://registry.terraform.io/providers/hashicorp/google/latest/docs/guides/provider_reference#quota-management-configuration
variable "billing_project_id" {
  type        = string
  description = "Required for billing for creating cloud vision API key. Defaults to var.project_id"
  default     = ""
}

variable "region" {
  type        = string
  description = "The region where the network will be created"
  default     = "us-west1"
}

variable "network_name" {
  type        = string
  description = "The name of the network to create"
  default     = "reducto-network"
}

variable "subnet_name" {
  type        = string
  description = "The name of the subnet to create"
  default     = "reducto-subnet"
}

variable "router_name" {
  type    = string
  default = "reducto-nat-router"
}

variable "subnet_cidr" {
  type        = string
  description = "The CIDR block for the subnet"
  default     = "10.127.0.0/16"
}

# https://cloud.google.com/load-balancing/docs/proxy-only-subnets
variable "regional_proxy_subnet_cidr" {
  type        = string
  description = "The CIDR block for the regional proxy subnet for internal load balancing"
  default     = "10.129.0.0/16"
}

variable "regional_proxy_subnet_name" {
  type    = string
  default = "reducto-regional-proxy"
}

variable "pods_cidr_name" {
  type        = string
  description = "The name of the pods CIDR range"
  default     = "reducto-pods-range"
}

variable "pods_cidr" {
  type        = string
  description = "The CIDR block for the pods"
  default     = "10.131.0.0/16"
}

variable "services_cidr_name" {
  type        = string
  description = "The name of the services CIDR range"
  default     = "reducto-services-range"
}


variable "services_cidr" {
  type        = string
  description = "The CIDR block for the services"
  default     = "10.133.0.0/16"
}


variable "enable_apis" {
  type        = list(string)
  description = "The list of APIs to enable"
  default = [
    # Base APIs used by Terraform and the network modules
    "cloudresourcemanager.googleapis.com",
    "compute.googleapis.com",
    "iam.googleapis.com",
    "serviceusage.googleapis.com",
    # for GKE
    "container.googleapis.com",
    # for accessing postgres on private network
    "servicenetworking.googleapis.com",
    # for managed Redis
    "redis.googleapis.com",
    # for Google Cloud Storage
    "storage.googleapis.com",
    # Enable API Keys (required for Reducto Vision API)
    "apikeys.googleapis.com",
    # for Google Cloud Vision
    "vision.googleapis.com",
    # for the service account's Vertex AI role
    "aiplatform.googleapis.com",
    # for Cloud SQL
    "sqladmin.googleapis.com",
  ]
}

variable "cluster_name" {
  type        = string
  description = "The name of the cluster"
  default     = "reducto-cluster"
}

variable "control_plane_allowed_cidrs" {
  type        = list(string)
  description = "The list of CIDRs allowed to access the GKE control plane"
  default     = ["0.0.0.0/0"]
}

variable "deletion_protection" {
  type        = bool
  description = "Whether to enable deletion protection on the cluster"
  default     = true
}

variable "bucket_name_prefix" {
  type        = string
  description = "The prefix for the bucket name"
  default     = "reducto"
}

variable "reducto_helm_repo_username" {
  type        = string
  description = "Username for Helm Registry for Reducto Helm Chart"
}

variable "reducto_helm_repo_password" {
  type        = string
  sensitive   = true
  description = "Password for Helm Registry for Reducto Helm Chart"
}

variable "reducto_helm_chart_version" {
  type        = string
  description = "Reducto Helm Chart version, obtain latest version from https://docs.reducto.ai/onprem/changelog"
  default     = "1.12.6"
}

variable "helm_release_timeout" {
  type        = number
  description = "Timeout in seconds for Helm release operations."
  default     = 900

  validation {
    condition     = var.helm_release_timeout >= 300
    error_message = "helm_release_timeout must be at least 300 seconds."
  }
}

variable "enable_managed_redis" {
  type        = bool
  description = "Provision a private, AUTH- and TLS-enabled Memorystore for Redis instance and wire it to Reducto."
  default     = false
}

variable "mount_managed_redis_ca" {
  type        = bool
  nullable    = true
  description = "Whether Reducto consumes managed Redis with its private CA mounted. When null, the mount is enabled only for chart versions verified to support redis.tls.*."
  default     = null
}

variable "managed_redis_tier" {
  type        = string
  description = "Memorystore service tier. Use BASIC only for disposable development environments."
  default     = "STANDARD_HA"

  validation {
    condition     = contains(["BASIC", "STANDARD_HA"], var.managed_redis_tier)
    error_message = "managed_redis_tier must be BASIC or STANDARD_HA."
  }
}

variable "managed_redis_memory_size_gb" {
  type        = number
  description = "Memory allocated to Memorystore for Redis, in GiB."
  default     = 5

  validation {
    condition     = var.managed_redis_memory_size_gb >= 1 && floor(var.managed_redis_memory_size_gb) == var.managed_redis_memory_size_gb
    error_message = "managed_redis_memory_size_gb must be a positive whole number."
  }
}

variable "managed_redis_version" {
  type        = string
  description = "Memorystore Redis engine version."
  default     = "REDIS_7_2"
}

variable "reducto_helm_chart_oci" {
  type        = string
  description = "Path to Helm Chart on OCI registry"
  default     = "oci://registry.reducto.ai/reducto-api/reducto"
}

variable "reducto_extra_values_files" {
  description = "Paths to additional Helm values files layered last. Use this for deployment-specific queue worker settings."
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for values_path in var.reducto_extra_values_files : can(file(values_path))])
    error_message = "Every reducto_extra_values_files entry must be a readable file path."
  }
}

variable "reducto_host" {
  type        = string
  description = "Host for Reducto Ingress"
}

variable "reducto_service_account_name" {
  type    = string
  default = "reducto-sa"
}

variable "db_availability_type" {
  type        = string
  description = "Availability type for the database"
  default     = "REGIONAL"
}

variable "db_tier" {
  type        = string
  description = "Tier for the database"
  default     = "db-custom-4-8192"
}

variable "database_password" {
  type        = string
  description = "Existing Cloud SQL application password to preserve during migration. Null generates a sensitive password for a fresh deployment."
  default     = null
  nullable    = true
  sensitive   = true
}

variable "primary_machine_type" {
  type        = string
  description = "Machine type for primary node pool (c2d-highcpu-8 equivalent)"
  default     = "c2d-highcpu-8"
}

variable "secondary_machine_type" {
  type        = string
  description = "Machine type for secondary node pool (c2d-highcpu-16 equivalent)"
  default     = "c2d-highcpu-16"
}

variable "extra_node_pools" {
  # see node pool options at https://github.com/terraform-google-modules/terraform-google-kubernetes-engine/blob/main/examples/simple_regional_private/main.tf
  type        = list(map(any))
  description = "List of maps containing extra node pools"

  default = []
}

# Configuration for Datadog

variable "datadog_site" {
  type        = string
  description = "Datadog site"
  default     = "us3.datadoghq.com"
}

variable "datadog_api_key" {
  type        = string
  description = "Datadog API key"
  sensitive   = true
  default     = ""
}
