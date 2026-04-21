// Tests in this file are run in the PR pipeline and the continuous testing pipeline
package test

import (
	"log"
	"os"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/common"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/testhelper"
)

// Use existing resource group
const resourceGroup = "geretain-test-resources"

const yamlLocation = "../common-dev-assets/common-go-assets/common-permanent-resources.yaml"

// Current supported regions
var validRegions = []string{
	"us-south",
	"us-east",
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
const existingBrsExampleDir = "examples/existing-brs"

var permanentResources map[string]interface{}

// TestMain will be run before any parallel tests, used to read data from yaml for use with tests
func TestMain(m *testing.M) {
	var err error
	permanentResources, err = common.LoadMapFromYaml(yamlLocation)
	if err != nil {
		log.Fatal(err)
	}

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

	options := setupOptions(t, "brs-basic", basicExampleDir, map[string]interface{}{
		"access_tags": permanentResources["accessTags"],
	})

	output, err := options.RunTestConsistency()
	assert.Nil(t, err, "This should not have errored")
	assert.NotNil(t, output, "Expected some output")
}

// Upgrade test (using basic example)
func TestRunUpgradeExample(t *testing.T) {
	t.Parallel()

	options := setupOptions(t, "brs-upg", basicExampleDir, map[string]interface{}{
		"access_tags": permanentResources["accessTags"],
	})

	// Ignore recreate of delete_policies resource during upgrade test
	// This resource is recreated when the instance details change
	options.IgnoreDestroys = testhelper.Exemptions{
		List: []string{
			"module.brs.terraform_data.delete_policies[0]",
		},
	}

	output, err := options.RunTestUpgrade()
	if !options.UpgradeTestSkipped {
		assert.Nil(t, err, "This should not have errored")
		assert.NotNil(t, output, "Expected some output")
	}
}

func TestRunExistingInstance(t *testing.T) {
	t.Parallel()

	// Use the permanent BRS instance CRN from common-permanent-resources.yaml
	existingBrsVars := map[string]interface{}{
		"existing_brs_instance_crn": permanentResources["brs_us_east_crn"],
		"region":                    "us-east",
	}

	existingBrsOptions := setupOptions(t, "brs-exist-adv", existingBrsExampleDir, existingBrsVars)

	output, err := existingBrsOptions.RunTestConsistency()
	assert.Nil(t, err, "existing-brs example with existing instance should succeed")
	assert.NotNil(t, output, "Expected output from existing-brs example")
}
