# Reducto

Deploy Reducto on Google Kubernetes Engine using Terraform

![Reducto on-prem Architecture for GCP](./reducto-architecture-on-gcp.png)


### Credentials 

Use one of the methods:

#### 1. Application Default Credentials

```
gcloud auth application-default login
```

#### 2. OAuth Access Token

For Terraform to use your [gcloud credentials](https://registry.terraform.io/providers/hashicorp/google/latest/docs/guides/provider_reference#access_token-1), run:

```
gcloud auth login
export GOOGLE_OAUTH_ACCESS_TOKEN=$(gcloud auth print-access-token)
```

### Billing Project

By default `var.project_id` is also billing project. This can be overriden by `var.billing_project_id`. Billing project is required for creating Cloud Vision API key.

See [Quota Management Configuration](https://registry.terraform.io/providers/hashicorp/google/latest/docs/guides/provider_reference#quota-management-configuration) in Terraform provider configuration.

### Quota

In your region, ensure there's sufficient quota for [Compute Optimized](https://cloud.google.com/compute/docs/compute-optimized-machines) instances (CPUs per region, CPU family per region), and Cloud Vision API https://console.cloud.google.com/iam-admin/quotas


### Security

A GKE cluster is provisioned with private nodes without public IP. Postgres instance is provisioned in private network without public IP.

GKE control plane is provisioned with both public and private IP - but access is limited to VPC and CIDR provided in `var.control_plane_allowed_cidrs`

### Terraform 

#### Terraform State

To use a bucket for Terraform state, create a bucket and update `backend.tf`.

OR you can skip this to quickly run Terraform plan and apply with locally managed `terraform.tfstate` state file for testing purposes.

#### Plan and Apply

At a minimum create a `terraform.tfvars` with following configuration:

```terraform
project_id                 = "your-gcp-project"
reducto_host               = "reducto.yourdomain.com"
reducto_helm_chart_version = "..."
reducto_helm_repo_username = "your-username"
reducto_helm_repo_password = "your-password"

# Keep disabled until the Memorystore private CA is wired into the chart.
enable_managed_redis = false
```

And then:

```sh
terraform init

# Required once in a new project. GKE's module queries available versions
# during planning, so its API must be active before the first full plan.
terraform apply -target=google_project_service.services

terraform plan
terraform apply
```

For an existing deployment, preserve the current Cloud SQL application
password by supplying the sensitive `database_password` input before applying
this update. Leaving it null generates a password only for a fresh deployment.
Never rotate this value as part of adding managed Redis or changing Terraform
ownership.

The default chart version is `1.12.2`. Its Streaq workloads remain disabled by
default. When `enable_managed_redis` is true, Terraform provisions Memorystore
for Redis over Private Service Access with AUTH and in-transit encryption, then
passes its sensitive `rediss://` URL to the chart as `REDIS_URL`. The bundled
Redis deployment remains disabled.

> **Managed Redis TLS prerequisite:** Memorystore signs its endpoint with the
> private CA exposed by the sensitive `redis_server_ca_certificate` output.
> This Terraform root does not yet configure the chart's CA Secret and mount.
> Keep `enable_managed_redis = false` until that wiring is present and verified.
> Do not bypass verification or disable in-transit encryption.

### DNS 

Ensure that domain name in `var.reducto_host` resolves to IP of internal load balancer of Reducto Ingress.

### Notes on Destroy

To delete, set `deletion_protection = false` and run `terraform destroy`. You may get following error, to resolve it manually delete from VPC under "VPC network peering" tab, and rerun `terraform destroy`.

<details>
<summary>
Service Networking Connection
</summary>

```
│ Error: Unable to remove Service Networking Connection, err: Error waiting for Delete Service Networking Connection: Error code 9, message: Failed to delete connection; Producer services (e.g. CloudSQL, Cloud Memstore, etc.) are still using this connection.
```
</details>
