// Tests in this file are run in the PR pipeline and the continuous testing pipeline
package test

import (
	"fmt"
	"strings"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/common"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/testhelper"

	"github.com/gruntwork-io/terratest/modules/files"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/require"
)

// Use existing resource group
const resourceGroup = "geretain-test-resources"

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

func setupOptions(t *testing.T, prefix string, dir string) *testhelper.TestOptions {
	options := testhelper.TestOptionsDefaultWithVars(&testhelper.TestOptions{
		Testing:       t,
		TerraformDir:  dir,
		Prefix:        prefix,
		ResourceGroup: resourceGroup,
		Region:        validRegions[common.CryptoIntn(len(validRegions))],
	})
	return options
}

// Consistency test for the basic example
func TestRunBasicExample(t *testing.T) {
	t.Parallel()

	options := setupOptions(t, "brs-basic", basicExampleDir)

	output, err := options.RunTestConsistency()
	assert.Nil(t, err, "This should not have errored")
	assert.NotNil(t, output, "Expected some output")
}

// Upgrade test (using advanced example)
func TestRunUpgradeExample(t *testing.T) {
	t.Parallel()

	options := setupOptions(t, "brs-upg", basicExampleDir)

	output, err := options.RunTestUpgrade()
	if !options.UpgradeTestSkipped {
		assert.Nil(t, err, "This should not have errored")
		assert.NotNil(t, output, "Expected some output")
	}
}

func setupTerraform(t *testing.T, prefix, realTerraformDir, region string) *terraform.Options {
	tempTerraformDir, err := files.CopyTerraformFolderToTemp(realTerraformDir, prefix)
	require.NoError(t, err, "Failed to create temporary Terraform folder")

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
func TestRunAdvancedExampleExistingInstance(t *testing.T) {
	t.Parallel()

	prefix := fmt.Sprintf("brs-%s", strings.ToLower(random.UniqueId()))
	options := setupOptions(t, "brs-adv-import", advancedExampleDir)
	existingTerraformOptions := setupTerraform(t, prefix, "./resources", options.Region)
	options.TerraformVars = map[string]interface{}{
		"prefix":           prefix,
		"brs_instance_crn": terraform.Output(t, existingTerraformOptions, "brs_instance_crn"),
		"resource_group":   resourceGroup,
	}

	output, err := options.RunTestConsistency()
	assert.Nil(t, err, "This should not have errored")
	assert.NotNil(t, output, "Expected some output")
}

func TestRunAdvancedExampleCreation(t *testing.T) {
	t.Parallel()

	options := setupOptions(t, "brs-adv-create", advancedExampleDir)
	options.TerraformVars = map[string]interface{}{
		"prefix":         options.Prefix,
		"resource_group": resourceGroup,
	}

	output, err := options.RunTestConsistency()
	assert.Nil(t, err, "This should not have errored")
	assert.NotNil(t, output, "Expected some output")
}
