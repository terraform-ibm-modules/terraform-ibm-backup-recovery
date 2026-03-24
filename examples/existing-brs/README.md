# existing-brs example

<!-- BEGIN SCHEMATICS DEPLOY HOOK -->
<p>
  <a href="https://cloud.ibm.com/schematics/workspaces/create?workspace_name=backup-recovery-existing-brs-example&repository=https://github.com/terraform-ibm-modules/terraform-ibm-backup-recovery/tree/main/examples/existing-brs">
    <img src="https://img.shields.io/badge/Deploy%20with%20IBM%20Cloud%20Schematics-0f62fe?style=flat&logo=ibm&logoColor=white&labelColor=0f62fe" alt="Deploy with IBM Cloud Schematics">
  </a><br>
  ℹ️ Ctrl/Cmd+Click or right-click on the Schematics deploy button to open in a new tab.
</p>
<!-- END SCHEMATICS DEPLOY HOOK -->

An end-to-end existing-brs example that will demonstrate the following:
- Using an existing resource group (or creating a new one if not provided).
- Using an existing Backup and Recovery instance (by passing `existing_brs_instance_crn`) or creating a new one if not provided.
- Creating a new data source connection in that Backup and Recovery instance.
