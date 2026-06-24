// Tests in this file are run in the PR pipeline and the continuous testing pipeline
package test

import (
	"context"
	"fmt"
	"os"
	"strings"
	"testing"

	"github.com/gruntwork-io/terratest/modules/files"
	"github.com/gruntwork-io/terratest/modules/logger"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/testhelper"
)

// Use existing resource group
const resourceGroup = "geretain-test-ocp-service-mesh"

// Ensure every example directory has a corresponding test
const basicExampleDir = "examples/basic"

// Ensure every example directory has a corresponding test
const advExampleDir = "examples/advanced"

// Ensure every example directory has a corresponding test
const nlbIngressDir = "examples/nlb-ingress"

func setupOptions(t *testing.T, prefix string, dir string) *testhelper.TestOptions {
	options := testhelper.TestOptionsDefaultWithVars(&testhelper.TestOptions{
		Testing:       t,
		TerraformDir:  dir,
		Prefix:        prefix,
		ResourceGroup: resourceGroup,
		IgnoreUpdates: testhelper.Exemptions{ // Ignore for consistency check
			List: []string{
				"module.service_mesh_operator.terraform_data.undeploy_servicemesh[0]",
			},
		},
	})
	return options
}

// Consistency test for the basic example
func TestRunBasicExample(t *testing.T) {
	t.Parallel()

	options := setupOptions(t, "ocpsm-basic", basicExampleDir)

	output, err := options.RunTestConsistency()
	assert.Nil(t, err, "This should not have errored")
	assert.NotNil(t, output, "Expected some output")
}

// Consistency test for the advanced example
func TestRunAdvancedExample(t *testing.T) {
	t.Parallel()

	options := setupOptions(t, "ocpsm-adv", advExampleDir)

	output, err := options.RunTestConsistency()
	assert.Nil(t, err, "This should not have errored")
	assert.NotNil(t, output, "Expected some output")
}

// Upgrade test (using advanced example)
func TestRunUpgradeExample(t *testing.T) {
	t.Parallel()

	options := setupOptions(t, "ocpsm-basic-upg", basicExampleDir)

	output, err := options.RunTestUpgrade()
	if !options.UpgradeTestSkipped {
		assert.Nil(t, err, "This should not have errored")
		assert.NotNil(t, output, "Expected some output")
	}
}

// Helper function to setup and apply terraform for existing resources
func setupTerraform(t *testing.T, prefix, realTerraformDir string) *terraform.Options {
	tempTerraformDir, err := files.CopyTerraformFolderToTemp(realTerraformDir, prefix)
	require.NoError(t, err, "Failed to create temporary Terraform folder")

	apiKey := validateEnvVariable(t, "TF_VAR_ibmcloud_api_key") // pragma: allowlist secret
	region, err := testhelper.GetBestVpcRegion(apiKey, "../common-dev-assets/common-go-assets/cloudinfo-region-vpc-gen2-prefs.yaml", "eu-de")
	require.NoError(t, err, "Failed to get best VPC region")

	existingTerraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: tempTerraformDir,
		Vars: map[string]interface{}{
			"prefix": prefix,
			"region": region,
		},
		// Set Upgrade to true to ensure latest version of providers and modules are used by terratest.
		// This is the same as setting the -upgrade=true flag with terraform.
		Upgrade: true,
	})

	terraform.WorkspaceSelectOrNewContext(t, context.Background(), existingTerraformOptions, prefix)
	_, err = terraform.InitAndApplyContextE(t, context.Background(), existingTerraformOptions)
	require.NoError(t, err, "Init and Apply of temp existing resource failed")

	return existingTerraformOptions
}

// Helper function to cleanup terraform resources
func cleanupTerraform(t *testing.T, options *terraform.Options, prefix string) {
	if t.Failed() && strings.ToLower(os.Getenv("DO_NOT_DESTROY_ON_FAILURE")) == "true" {
		fmt.Println("Terratest failed. Debug the test and delete resources manually.")
		return
	}
	logger.Log(t, "START: Destroy (existing resources)")
	terraform.DestroyContext(t, context.Background(), options)
	terraform.WorkspaceDeleteContext(t, context.Background(), options, prefix)
	logger.Log(t, "END: Destroy (existing resources)")
}

// Helper function to validate environment variable
func validateEnvVariable(t *testing.T, varName string) string {
	value := os.Getenv(varName)
	require.NotEmpty(t, value, fmt.Sprintf("Environment variable %s must be set", varName))
	return value
}

// Test for NLB Ingress example with existing resources
func TestRunNLBIngressExample(t *testing.T) {
	t.Parallel()

	prefix := fmt.Sprintf("ocpsm-nlb-%s", strings.ToLower(random.UniqueID()))
	// Step 1: Setup existing resources (VPC, subnets, etc.)
	logger.Log(t, "Setting up existing resources...")
	existingTerraformOptions := setupTerraform(t, prefix, "./existing-resources")
	defer cleanupTerraform(t, existingTerraformOptions, prefix)

	// Step 2: Get outputs from existing resources
	logger.Log(t, "Fetching outputs from existing resources...")
	resourceGroupID := terraform.OutputContext(t, context.Background(), existingTerraformOptions, "resource_group_id")
	vpcID := terraform.OutputContext(t, context.Background(), existingTerraformOptions, "vpc_id")
	region := terraform.OutputContext(t, context.Background(), existingTerraformOptions, "region")

	// Get JSON-encoded string outputs (these are already JSON strings from jsonencode())
	clusterVpcSubnetsJSON := terraform.OutputContext(t, context.Background(), existingTerraformOptions, "cluster_vpc_subnets_json")
	nlbZonesSubnetsJSON := terraform.OutputContext(t, context.Background(), existingTerraformOptions, "nlb_zones_subnets_json")

	logger.Log(t, fmt.Sprintf("cluster_vpc_subnets_json: %s", clusterVpcSubnetsJSON))
	logger.Log(t, fmt.Sprintf("nlb_zones_subnets_json: %s", nlbZonesSubnetsJSON))

	// Step 3: Setup NLB Ingress example with testhelper
	// Pass the JSON strings directly - Terraform will parse them
	logger.Log(t, "Setting up NLB Ingress example with testhelper...")
	options := testhelper.TestOptionsDefaultWithVars(&testhelper.TestOptions{
		Testing:      t,
		TerraformDir: nlbIngressDir,
		Prefix:       prefix,
		TerraformVars: map[string]interface{}{
			"prefix":                    prefix,
			"region":                    region,
			"resource_group_id":         resourceGroupID,
			"vpc_id":                    vpcID,
			"cluster_vpc_subnets":       clusterVpcSubnetsJSON,
			"ingress_nlb_zones_subnets": nlbZonesSubnetsJSON,
		},
		IgnoreUpdates: testhelper.Exemptions{ // Ignore for consistency check
			List: []string{
				"module.service_mesh_operator.terraform_data.undeploy_servicemesh[0]",
			},
		},
	})

	// Step 4: Run test consistency
	output, err := options.RunTestConsistency()
	assert.Nil(t, err, "NLB Ingress test should not have errored")
	assert.NotNil(t, output, "Expected some output from NLB Ingress test")

	logger.Log(t, "NLB Ingress test completed successfully")
}
