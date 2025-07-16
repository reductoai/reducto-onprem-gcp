# Reducto

Deploy Reducto on Google Kubernetes Engine using Terraform

![Reducto on-prem Architecture for GCP](./reducto-architecture-on-gcp.png)


### Credentials 

For Terraform to use your [gcloud credentials](https://registry.terraform.io/providers/hashicorp/google/latest/docs/guides/provider_reference#access_token-1), run:

```
gcloud auth login
export GOOGLE_OAUTH_ACCESS_TOKEN=$(gcloud auth print-access-token)
```

### Quota

In your region, ensure there's sufficient quota for [Performance](https://cloud.google.com/kubernetes-engine/docs/concepts/autopilot-compute-classes) compute (CPUs per region, CPUs per region family), and Cloud Vision API
https://console.cloud.google.com/iam-admin/quotas


### Security

A GKE autopilot cluster is provisioned with private nodes without public IP. Postgres instance is provisioned in private network without public IP. 

GKE control plane is provisioned with both public and private IP - but access is limited to VPC and CIDR provided in `var.control_plane_allowed_cidrs`

### Terraform 

At a minimum create a `terraform.tfvars` with following configuration:

```terraform
project_id                 = "your-gcp-project"
reducto_host               = "reducto.yourdomain.com"
reducto_helm_chart_version = "..."
reducto_helm_repo_username = "your-username"
reducto_helm_repo_password = "your-password"
```

And then:

```sh
terraform init
terraform plan
terraform apply
```

### DNS 

Ensure that domain name in `var.reducto_host` resolves to IP of internal load balancer of Reducto Ingress.