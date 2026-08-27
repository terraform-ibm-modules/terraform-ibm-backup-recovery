// Tests in this file are run in the PR pipeline and the continuous testing pipeline
package test

import (
	"os"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/common"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/testhelper"
)

// Use existing resource group
const resourceGroup = "E2E Test"
const existingBrsInstanceCRN = "crn:v1:bluemix:public:backup-recovery:au-syd:a/0f628e88c6594675bbefa097a63b9293:e0c89382-56e2-453f-906e-a2b91a60f19a::"

// Current supported regions
var validRegions = []string{
	"us-south",
	"us-east",
	"eu-de",
	"eu-gb",
	"eu-es",
	"jp-tok",
	"jp-osa",
	"ca-tor",
	"br-sao",
}

// Ensure every example directory has a corresponding test
const basicExampleDir = "examples/basic"
const existingBrsExampleDir = "examples/existing-brs"

// TestMain will be run before any parallel tests, used to read data from yaml for use with tests
func TestMain(m *testing.M) {
	os.Exit(m.Run())
}

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

// Consistency test for the basic example
func TestRunBasicExample(t *testing.T) {
	t.Parallel()

	options := setupOptions(t, "brs-basic", basicExampleDir, map[string]interface{}{})

	output, err := options.RunTestConsistency()
	assert.Nil(t, err, "This should not have errored")
	assert.NotNil(t, output, "Expected some output")
}

// Upgrade test (using basic example)
func TestRunUpgradeExample(t *testing.T) {
	t.Parallel()

	options := setupOptions(t, "brs-upg", basicExampleDir, map[string]interface{}{})

	output, err := options.RunTestUpgrade()
	if !options.UpgradeTestSkipped {
		assert.Nil(t, err, "This should not have errored")
		assert.NotNil(t, output, "Expected some output")
	}
}

func TestRunExistingInstance(t *testing.T) {
	t.Parallel()

	existingBrsVars := map[string]interface{}{
		"existing_brs_instance_crn": existingBrsInstanceCRN,
		"region":                    "au-syd",
	}

	existingBrsOptions := setupOptions(t, "brs-exist-adv", existingBrsExampleDir, existingBrsVars)

	output, err := existingBrsOptions.RunTestConsistency()
	assert.Nil(t, err, "existing-brs example with existing instance should succeed")
	assert.NotNil(t, output, "Expected output from existing-brs example")
}
