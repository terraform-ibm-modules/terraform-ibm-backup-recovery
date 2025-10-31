#!/bin/bash

# Exit on any error
set -eou pipefail


# Initialize Terraform
echo "Initializing Terraform..."
terraform init -upgrade || { echo "Terraform init failed"; exit 1; }

# Format and validate configuration
echo "Formatting and validating Terraform configuration..."
terraform fmt -recursive
terraform validate || { echo "Terraform validate failed"; exit 1; }

# # Apply the brs_instance resource first
# echo "Applying BRS instance..."
# terraform apply -target=module.network -auto-approve 
# terraform apply -target=module.brs_instance -auto-approve || { echo "BRS instance apply failed"; exit 1; }

# Retrieve the public endpoint
# echo "Retrieving BRS public endpoint..."
# BRS_ENDPOINT=$(terraform output -raw brs_public_endpoint 2>/dev/null) || { echo "Failed to retrieve brs_public_endpoint"; exit 1; }
# export IBMCLOUD_BACKUP_RECOVERY_ENDPOINT="https://${BRS_ENDPOINT}/v2"
# echo "Set IBMCLOUD_BACKUP_RECOVERY_ENDPOINT to $IBMCLOUD_BACKUP_RECOVERY_ENDPOINT"


# Run a full apply
echo "Applying full Terraform configuration..."
terraform apply -auto-approve || { echo "Full apply failed"; exit 1; }