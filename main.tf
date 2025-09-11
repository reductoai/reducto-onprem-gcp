terraform {
  required_version = ">= 1.3"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 6.43.0, < 7"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 3.0"
    }
    kubectl = {
      source  = "alekc/kubectl"
      version = ">= 2.0.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0.0"
    }
  }
}

data "google_client_config" "current" {
}

provider "helm" {
  kubernetes = {
    host  = "https://${module.gke.endpoint}"
    token = data.google_client_config.current.access_token
    cluster_ca_certificate = base64decode(
    module.gke.ca_certificate)
    exec = {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "gke-gcloud-auth-plugin"
    }
  }
}

provider "kubectl" {
  host                   = module.gke.endpoint
  cluster_ca_certificate = base64decode(module.gke.ca_certificate)
  token                  = data.google_client_config.current.access_token
  load_config_file       = false
}

provider "kubernetes" {
  host = "https://${module.gke.endpoint}"

  token                  = data.google_client_config.current.access_token
  cluster_ca_certificate = base64decode(module.gke.ca_certificate)
}

provider "google" {
  project               = var.project_id
  region                = var.region
  user_project_override = true
  billing_project       = var.billing_project_id != "" ? var.billing_project_id : var.project_id
}