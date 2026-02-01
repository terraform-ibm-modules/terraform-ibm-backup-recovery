// Tests in this file are run in the PR pipeline and the continuous testing pipeline
package test

import (
	"fmt"
	"os"
	"strings"
	"testing"

	"os/exec"
	"path/filepath"

	"github.com/gruntwork-io/terratest/modules/files"
	"github.com/gruntwork-io/terratest/modules/logger"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/common"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/testhelper"
)

// Use existing resource group
const resourceGroup = "BRT-General-testing"

// Current supported regions
var validRegions = []string{
	"us-south",
	// "us-east", // ignore until issues in this regions are resolved
	"eu-de",
	"eu-gb",
	"eu-es",
	"jp-tok",
	"jp-osa",
	"au-syd",
	"ca-tor",
	"br-sao",
}

// Ensure every example directory has a corresponding test
const basicExampleDir = "examples/basic"
const advancedExampleDir = "examples/advanced"

func setupOptions(t *testing.T, prefix string, dir string, terraformVars map[string]interface{}) *testhelper.TestOptions {
	options := testhelper.TestOptionsDefaultWithVars(&testhelper.TestOptions{
		Testing:       t,
		TerraformDir:  dir,
		Prefix:        prefix,
		ResourceGroup: resourceGroup,
		Region:        validRegions[common.CryptoIntn(len(validRegions))],
		TerraformVars: terraformVars,
	})
	return options
}

func setupTerraform(t *testing.T, prefix, realTerraformDir string) *terraform.Options {
	tempTerraformDir, err := files.CopyTerraformFolderToTemp(realTerraformDir, prefix)
	require.NoError(t, err, "Failed to create temporary Terraform folder")

	// Copy the scripts folder to the temporary Terraform directory so the test can find the delete_policies.sh script
	// We assume the test is running from the 'tests' directory, so the scripts are in '../scripts'
	scriptsSrc, _ := filepath.Abs("../scripts")
	scriptsDest := filepath.Join(tempTerraformDir, "scripts")

	// Create the destination directory parent if needed, though tempTerraformDir exists.
	// We use cp -r to copy the folder.
	cmd := exec.Command("cp", "-r", scriptsSrc, scriptsDest)
	err = cmd.Run()
	require.NoError(t, err, "Failed to copy scripts folder to temp dir")

	region := validRegions[common.CryptoIntn(len(validRegions))]

	existingTerraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: tempTerraformDir,
		Vars: map[string]interface{}{
			"prefix":         prefix,
			"region":         region,
			"resource_group": resourceGroup,
		},
		// Set Upgrade to true to ensure latest version of providers and modules are used by terratest.
		// This is the same as setting the -upgrade=true flag with terraform.
		Upgrade: true,
	})

	terraform.WorkspaceSelectOrNew(t, existingTerraformOptions, prefix)
	_, err = terraform.InitAndApplyE(t, existingTerraformOptions)
	require.NoError(t, err, "Init and Apply of temp existing resource failed")

	return existingTerraformOptions
}

func cleanupTerraform(t *testing.T, options *terraform.Options, prefix string) {
	if t.Failed() && strings.ToLower(os.Getenv("DO_NOT_DESTROY_ON_FAILURE")) == "true" {
		fmt.Println("Terratest failed. Debug the test and delete resources manually.")
		return
	}
	logger.Log(t, "START: Destroy (existing resources)")
	terraform.Destroy(t, options)
	terraform.WorkspaceDelete(t, options, prefix)
	logger.Log(t, "END: Destroy (existing resources)")
}

// Consistency test for the basic example
func TestRunBasicExample(t *testing.T) {
	t.Parallel()

	options := setupOptions(t, "brs-basic", basicExampleDir, nil)

	output, err := options.RunTestConsistency()
	assert.Nil(t, err, "This should not have errored")
	assert.NotNil(t, output, "Expected some output")
}

// Upgrade test (using advanced example)
func TestRunUpgradeExample(t *testing.T) {
	t.Parallel()

	options := setupOptions(t, "brs-upg", basicExampleDir, nil)

	output, err := options.RunTestUpgrade()
	if !options.UpgradeTestSkipped {
		assert.Nil(t, err, "This should not have errored")
		assert.NotNil(t, output, "Expected some output")
	}
}

func TestRunAdvancedExample(t *testing.T) {
	t.Parallel()

	options := setupOptions(t, "brs-adv", advancedExampleDir, nil)

	output, err := options.RunTestConsistency()
	assert.Nil(t, err, "This should not have errored")
	assert.NotNil(t, output, "Expected some output")
}

func TestRunExistingInstance(t *testing.T) {
	t.Parallel()

	// 1. Provision Basic Example
	basicOptions := setupTerraform(t, "brs-exist", "resources")
	defer cleanupTerraform(t, basicOptions, "brs-exist")

	// 2. Provision Advanced Example using existing CRN
	advancedVars := map[string]interface{}{
		"brs_instance_crn": terraform.Output(t, basicOptions, "brs_instance_crn"),
		"region":           basicOptions.Vars["region"],
	}

	advancedOptions := setupOptions(t, "brs-exist-adv", advancedExampleDir, advancedVars)

	// We can use the standard consistency test here, which will Apply and Destroy the advanced example.
	// The basic example will be destroyed by the defer above.
	outputAdv, errAdv := advancedOptions.RunTestConsistency()
	assert.Nil(t, errAdv, "Advanced example with existing instance should succeed")
	assert.NotNil(t, outputAdv, "Expected output from advanced example")
}
