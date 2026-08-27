// Tests in this file are run in the PR pipeline and the continuous testing pipeline
package test

import (
	"os"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/testhelper"
)

// Use existing resource group
const resourceGroup = "E2E Test"
const existingBrsInstanceCRN = "crn:v1:bluemix:public:backup-recovery:au-syd:a/0f628e88c6594675bbefa097a63b9293:e0c89382-56e2-453f-906e-a2b91a60f19a::"

// backup-recovery-tests is only available in us-east for this account;
// custom-prov-code is required when provisioning against the test service.
const testServiceType = "backup-recovery-tests"
const testRegion = "us-east"
const testCustomProvCode = `{"custom-prov-code": "brs-brt-us-east-0103"}`

// Ensure every example directory has a corresponding test
const basicExampleDir = "examples/basic"
const existingBrsExampleDir = "examples/existing-brs"

// TestMain will be run before any parallel tests, used to read data from yaml for use with tests
func TestMain(m *testing.M) {
	os.Exit(m.Run())
}

func setupOptions(t *testing.T, prefix string, dir string, region string, terraformVars map[string]interface{}) *testhelper.TestOptions {
	options := testhelper.TestOptionsDefaultWithVars(&testhelper.TestOptions{
		Testing:       t,
		TerraformDir:  dir,
		Prefix:        prefix,
		ResourceGroup: resourceGroup,
		Region:        region,
		TerraformVars: terraformVars,
	})
	return options
}

// Consistency test for the basic example
func TestRunBasicExample(t *testing.T) {
	t.Parallel()

	options := setupOptions(t, "brs-basic", basicExampleDir, testRegion, map[string]interface{}{
		"service_type":    testServiceType,
		"parameters_json": testCustomProvCode,
	})

	output, err := options.RunTestConsistency()
	assert.Nil(t, err, "This should not have errored")
	assert.NotNil(t, output, "Expected some output")
}

// Upgrade test (using basic example).
func TestRunUpgradeExample(t *testing.T) {
	t.Parallel()

	options := setupOptions(t, "brs-upg", basicExampleDir, testRegion, map[string]interface{}{
		"service_type":    testServiceType,
		"parameters_json": testCustomProvCode,
	})

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

	existingBrsOptions := setupOptions(t, "brs-exist-adv", existingBrsExampleDir, "au-syd", existingBrsVars)

	output, err := existingBrsOptions.RunTestConsistency()
	assert.Nil(t, err, "existing-brs example with existing instance should succeed")
	assert.NotNil(t, output, "Expected output from existing-brs example")
}
