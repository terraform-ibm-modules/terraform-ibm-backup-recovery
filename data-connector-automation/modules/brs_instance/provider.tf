terraform {
  required_version = ">= 1.12.0"
  required_providers {
    ibm = {
      source  = "IBM-Cloud/ibm"
      version = "1.85.0-beta0"
    }
  }
}