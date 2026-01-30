# Advanced example

<!-- BEGIN SCHEMATICS DEPLOY HOOK -->
<a href="https://cloud.ibm.com/schematics/workspaces/create?workspace_name=backup-recovery-advanced-example&repository=https://github.com/terraform-ibm-modules/terraform-ibm-backup-recovery/tree/main/examples/advanced"><img src="https://img.shields.io/badge/Deploy%20with IBM%20Cloud%20Schematics-0f62fe?logo=ibm&logoColor=white&labelColor=0f62fe" alt="Deploy with IBM Cloud Schematics" style="height: 16px; vertical-align: text-bottom;"></a>
<!-- END SCHEMATICS DEPLOY HOOK -->


An end-to-end advanced example that will demonstrate the following:
- Using an existing resource group (or creating a new one if not provided).
- Using an existing Backup and Recovery instance (by passing `brs_instance_crn`) or creating a new one if not provided.
- Creating a new data source connection in that existing instance.

<!-- BEGIN SCHEMATICS DEPLOY TIP HOOK -->
:information_source: Ctrl/Cmd+Click or right-click on the Schematics deploy button to open in a new tab
<!-- END SCHEMATICS DEPLOY TIP HOOK -->
