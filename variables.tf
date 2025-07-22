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
    # for GKE
    "container.googleapis.com",
    # for accessing postgres on private network
    "servicenetworking.googleapis.com",
    # for Google Cloud Storage
    "storage.googleapis.com",
    # Enable API Keys (required for Reducto Vision API)
    "apikeys.googleapis.com",
    # for Google Cloud Vision
    "vision.googleapis.com",
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
  description = "Username for Helm Registry for Reducto Helm Chart"
}

variable "reducto_helm_repo_password" {
  sensitive   = true
  description = "Password for Helm Registry for Reducto Helm Chart"
}

variable "reducto_helm_chart_version" {
  description = "Reducto Helm Chart version"
  default     = "1.9.93"
}

variable "reducto_helm_chart_oci" {
  description = "Path to Helm Chart on OCI registry"
  default     = "oci://registry.reducto.ai/reducto-api/reducto"
}

variable "reducto_host" {
  description = "Host for Reducto Ingress"
}

variable "db_availability_type" {
  description = "Availability type for the database"
  default     = "REGIONAL"
}

variable "db_tier" {
  description = "Tier for the database"
  default     = "db-custom-4-8192"
}