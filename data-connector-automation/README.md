# IKS/ROKS Backup and Recovery Terraform Deployment

This repository contains Terraform configuration (`main.tf`, `provider.tf`, `variables.tf`, `outputs.tf`, `iks.tf`, `roks.tf`) to deploy a backup and recovery solution on IBM Cloud. The configuration provisions a Virtual Private Cloud (VPC), IBM Kubernetes Service (IKS) and Red Hat OpenShift on IBM Cloud (ROKS) clusters, a Backup and Recovery Service (BRS) instance, a Virtual Private Endpoint (VPE) gateway, security groups, and containerized data connectors for a comprehensive backup solution.

## Overview

The Terraform configuration automates the deployment of:
- A resource group (existing or new)
- A VPC with subnets (existing or new)
- A BRS instance for backup and recovery
- A VPE gateway for private connectivity
- IKS and ROKS clusters for containerized workloads
- Security group rules to manage network traffic (ports 443, 29991, 50001 outbound; 3000 inbound)
- Containerized data connectors deployed via Helm charts
- Backup integration with Velero for IKS and ROKS clusters

## Prerequisites

Before using this Terraform configuration, ensure you have:
- **IBM Cloud Account**: An active account with permissions to create resources like VPC, IKS/ROKS clusters, and BRS instances.
- **Terraform**: Installed on your local machine (version >= 1.12.0, as specified in `provider.tf`).
- **IBM Cloud API Key**: A valid API key for authentication, provided via `terraform.tfvars`.

## Installing Terraform

To install Terraform on your local machine, follow these steps based on your operating system:

### **Windows**
1. Download the Terraform binary from the [official Terraform website](https://www.terraform.io/downloads.html).
2. Extract the downloaded ZIP file to a directory (e.g., `C:\Terraform`).
3. Add the directory to your system's PATH environment variable:
   - Right-click 'This PC' > Properties > Advanced system settings > Environment Variables.
   - Under "System Variables," edit `Path` and add the Terraform directory (e.g., `C:\Terraform`).
4. Open a Command Prompt and verify the installation by running:
   ```bash
   terraform -version
   ```

### **macOS**
1. Install Terraform using Homebrew:
   ```bash
   brew tap hashicorp/tap
   brew install hashicorp/tap/terraform
   ```
2. Verify the installation:
   ```bash
   terraform -version
   ```

### **Linux**
1. Download the Terraform binary for your Linux distribution from the [official Terraform website](https://www.terraform.io/downloads.html).
2. Extract the binary:
   ```bash
   unzip terraform_<version>_linux_amd64.zip
   ```
3. Move the binary to a directory in your PATH (e.g., `/usr/local/bin`):
   ```bash
   sudo mv terraform /usr/local/bin/
   ```
4. Verify the installation:
   ```bash
   terraform -version
   ```

For more detailed instructions, refer to the [official Terraform installation guide](https://learn.hashicorp.com/tutorials/terraform/install-cli).

## Repository Contents

- **`main.tf`**: Defines the resource group, VPC, BRS instance, and VPE gateway.
- **`iks.tf`**: Configures the IKS cluster, security group rules, data connectors, and backup integration.
- **`roks.tf`**: Configures the ROKS cluster, security group rules, data connectors, and backup integration.
- **`provider.tf`**: Specifies Terraform providers (`ibm`, `kubernetes`, `helm`) and configures authentication.
- **`variables.tf`**: Defines input variables with defaults and validations.
- **`outputs.tf`**: Defines output values such as resource group ID, VPC ID, subnet list, BRS instance details, and cluster details.
- **`terraform.tfvars.example`**: Example variable file (rename to `terraform.tfvars` and customize).

## Setup Instructions

### Step 1: Clone the Repository

```bash
git clone <repository-url>
cd data-connector-automation
```

### Step 2: Configure Variables

Create a `terraform.tfvars` file based on the example below:

```hcl
ibmcloud_api_key = "<your-ibm-cloud-api-key>"

resource_group = {
  name       = "E2E Test"
  create_new = false
}

vpc = {
  name                       = "roks-iks-integration-vpc"
  create_new                 = false
  create_subnet_gateway      = false
  auto_assign_address_prefix = false
  prefix                     = "brsiksroks"
}

region = "us-east"


brs_service = {
  name                  = "backup-recovery-tests"
  provision_code        = "brs-brt-us-east-0103"
  instance_name         = "brs109tfav3"
  create_new            = false
  region                = "us-east"
  vpeg = {
    service_endpoints = "private"
    create_new        = false
    name              = "vpe-roks-iks-integration-vpc-backup-recovery-tests"
  }
}

iks_cluster = {
  name             = "brs109tfav3-iks"
  iks_version      = "1.32.9"
  workers_per_zone = 1
  machine_type     = "bx2.4x16"
  operating_system = "Ubuntu 24"
  pool_name        = "default"
  create_new       = true
  connection = {
    create_new      = true
    endpoint_type   = "public"
    connection_name = "brs109tfav3-iks"
  }
  protection = {
    source_name = "brs109tfav3-iks"
    policy_name = "brs109tfav3-iks"
    images = {
      data_mover              = "icr.io/ext/brs/cohesity-datamover:7.2.15-p2"
      velero                  = "icr.io/ext/brs/velero:7.2.15-p2"
      velero_aws_plugin       = "icr.io/ext/brs/velero-plugin-for-aws:7.2.15-p2"
      velero_openshift_plugin = "icr.io/ext/brs/velero-plugin-for-openshift:7.2.15-p2"
      init_container          = ""
    }
    connector = {
      release_name     = "dsc"
      chart_name       = "cohesity-dsc-chart"
      chart_repository = "oci://icr.io/ext/brs/"
      namespace        = "brs-dsc"
      chart_version    = "7.2.15-release-20250721-6aa24701"
      image = {
        namespace  = "ext"
        repository = "brs/cohesity-data-source-connector_7.2.15-release-20250721"
        tag        = "6aa24701"
        pullPolicy = "IfNotPresent"
      }
      replica_count    = 3
      timeout          = 1200
      create_namespace = true
    }
  }
}

roks_cluster = {
  name             = "brs109tfav3-roks"
  ocp_version      = "4.18"
  workers_per_zone = 1
  machine_type     = "bx2.4x16"
  operating_system = "RHCOS"
  pool_name        = "default"
  create_new       = true
  connection = {
    create_new      = true
    endpoint_type   = "public"
    connection_name = "brs109tfav3-roks"
  }
  protection = {
    source_name = "brs109tfav3-roks"
    policy_name = "brs109tfav3-roks"
    images = {
      data_mover              = "icr.io/ext/brs/cohesity-datamover:7.2.15-p2"
      velero                  = "icr.io/ext/brs/velero:7.2.15-p2"
      velero_aws_plugin       = "icr.io/ext/brs/velero-plugin-for-aws:7.2.15-p2"
      velero_openshift_plugin = "icr.io/ext/brs/velero-plugin-for-openshift:7.2.15-p2"
      init_container          = ""
    }
    connector = {
      release_name     = "dsc"
      chart_name       = "cohesity-dsc-chart"
      chart_repository = "oci://icr.io/ext/brs/"
      namespace        = "brs-dsc"
      chart_version    = "7.2.15-release-20250721-6aa24701"
      image = {
        namespace  = "ext"
        repository = "brs/cohesity-data-source-connector_7.2.15-release-20250721"
        tag        = "6aa24701"
        pullPolicy = "IfNotPresent"
      }
      replica_count    = 3
      timeout          = 1200
      create_namespace = true
    }
  }
}

registry_creds = [
  { url = "oci://icr.io", username = "iamapikey", password = "<your-ibm-cloud-api-key>" }
]
```

Replace `<your-ibm-cloud-api-key>` with your actual IBM Cloud API key. Modify other values as needed, ensuring compliance with `variables.tf` validations.

### Step 3: Deploy the Infrastructure

Run the following commands to deploy:

```bash
terraform init
terraform validate
terraform apply -auto-approve
```

### Step 4: Verify Deployment

- Check the IBM Cloud console for the resource group, VPC, subnets, IKS/ROKS clusters, BRS instance, and VPE gateway.
- Verify security group rules allow traffic on TCP ports 443, 29991, 50001 (outbound) and 3000 (inbound).
- Confirm data connectors are running in the `brs-dsc` namespace of the IKS/ROKS clusters.
- Check the BRS console to ensure the clusters are registered and backups are configured.

## Variables

See `variables.tf` for all variables, defaults, and validations. Key variables include:
- `ibmcloud_api_key`: IBM Cloud API key (sensitive, required).
- `resource_group`: Resource group configuration (`name`, `create_new`).
- `vpc`: VPC configuration (`name`, `create_new`, `create_subnet_gateway`, `auto_assign_address_prefix`, `prefix`).
- `region`: IBM Cloud region (e.g., `us-east`).
- `tenant_name`: Tenant name for naming and tagging (e.g., `nitish`).
- `brs_service`: BRS instance configuration (`name`, `provision_code`, `instance_name`, `connection_name`, `protection_group_name`, `policy_name`, `source_reg_name`, `create_new`, `region`, `vpeg`).
- `iks_cluster`: IKS cluster configuration (`name`, `iks_version`, `workers_per_zone`, `machine_type`, `operating_system`, `pool_name`, `create_new`, `connection`, `protection`).
  - `connection`: Defines connection settings (`create_new`, `endpoint_type`, `connection_name`).
  - `protection`: Configures backup settings (`source_name`, `policy_name`, `images`, `connector`).
  - `images`: Specifies container images for data mover, Velero, and plugins.
  - `connector`: Configures Helm chart deployment (`release_name`, `chart_name`, `chart_repository`, `namespace`, `chart_version`, `image`, `replica_count`, `timeout`, `create_namespace`).
- `roks_cluster`: ROKS cluster configuration (`name`, `ocp_version`, `workers_per_zone`, `machine_type`, `operating_system`, `pool_name`, `create_new`, `connection`, `protection`).
  - `connection`: Defines connection settings (`create_new`, `endpoint_type`, `connection_name`).
  - `protection`: Configures backup settings (`source_name`, `policy_name`, `images`, `connector`).
  - `images`: Specifies container images for data mover, Velero, and plugins.
  - `connector`: Configures Helm chart deployment (`release_name`, `chart_name`, `chart_repository`, `namespace`, `chart_version`, `image`, `replica_count`, `timeout`, `create_namespace`).
- `registry_creds`: Container registry credentials for pulling Helm charts (`url`, `username`, `password`).

## Notes

- **Dependencies**: Uses IBM Cloud Terraform modules (e.g., `terraform-ibm-modules/vpc`) and custom modules (`./modules/*`).
- **Cleanup**: To destroy resources, run:
  ```bash
  terraform destroy -auto-approve
  ```

## Troubleshooting

- **Terraform Apply Fails**:
  - Verify `ibmcloud_api_key` is valid.
  - Ensure `resource_group.name` and `vpc.name` exist if `create_new = false`.
  - Check `iks_cluster.iks_version` and `roks_cluster.ocp_version` are supported (e.g., `4.14`, `4.15`, `4.16`, `4.17`, `4.18`, or `default` for ROKS).
  - Ensure `roks_cluster.operating_system` is valid (`REDHAT_8_64`, `RHEL_9_64`, `RHCOS`) and compatible (RHCOS requires OpenShift 4.15 or later).
- **Data Connector Issues**:
  - Verify Helm chart deployment in the `brs-dsc` namespace.
  - Ensure `registry_creds` are correct for `icr.io`.
- **Security Group Rules**:
  - Confirm rules allow required traffic (ports 443, 29991, 50001, 3000).

