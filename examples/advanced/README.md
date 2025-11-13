# Basic example

An end-to-end basic example that will provision the following:
- A new resource group if one is not passed in.
- A Key Protect instance, a key ring, and a root key in the given resource group and region.
- A new premium plan Backup and Recovery instance using the root level module with KMS encryption.
