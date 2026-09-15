// Tests in this file are NOT run in the PR pipeline. They are run in the continuous testing pipeline along with the ones in pr_test.go
package test

import (
	"os/exec"
	"strings"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// TestIstioChartTrustDomain validates that trustDomain is rendered into the Istio CR
// when var.mesh_config_trust_domain is set.
func TestIstioChartTrustDomain(t *testing.T) {
	t.Parallel()

	cmd := exec.Command("helm", "template", "test-trust-domain", "../chart/istio",
		"--set", "istioconfiguration.meshConfig.trustDomain=my-company.com",
	)
	out, err := cmd.CombinedOutput()
	require.NoError(t, err, "helm template failed: %s", string(out))

	rendered := string(out)
	assert.Contains(t, rendered, `trustDomain: "my-company.com"`,
		"trustDomain should be rendered in the Istio CR meshConfig")
}

// TestIstioChartTrustDomainAliases validates that trustDomainAliases list is rendered
// into the Istio CR when var.mesh_config_trust_domain_aliases is set.
func TestIstioChartTrustDomainAliases(t *testing.T) {
	t.Parallel()

	cmd := exec.Command("helm", "template", "test-trust-domain-aliases", "../chart/istio",
		"--set", "istioconfiguration.meshConfig.trustDomain=my-company.com",
		"--set", "istioconfiguration.meshConfig.trustDomainAliases[0]=cluster.local",
		"--set", "istioconfiguration.meshConfig.trustDomainAliases[1]=old-domain.com",
	)
	out, err := cmd.CombinedOutput()
	require.NoError(t, err, "helm template failed: %s", string(out))

	rendered := string(out)
	assert.Contains(t, rendered, "trustDomainAliases:",
		"trustDomainAliases key should be rendered in the Istio CR meshConfig")
	assert.Contains(t, rendered, "- cluster.local",
		"trustDomainAliases should contain 'cluster.local'")
	assert.Contains(t, rendered, "- old-domain.com",
		"trustDomainAliases should contain 'old-domain.com'")
}

// TestIstioChartTrustDomainNotRenderedByDefault validates that neither trustDomain nor
// trustDomainAliases appear in the rendered output when the values are not set,
// preserving the Istio default (cluster.local) without explicit override.
func TestIstioChartTrustDomainNotRenderedByDefault(t *testing.T) {
	t.Parallel()

	cmd := exec.Command("helm", "template", "test-trust-domain-default", "../chart/istio")
	out, err := cmd.CombinedOutput()
	require.NoError(t, err, "helm template failed: %s", string(out))

	rendered := string(out)
	assert.False(t, strings.Contains(rendered, "trustDomain:"),
		"trustDomain should NOT be rendered when not set — Istio default (cluster.local) must be preserved")
	assert.False(t, strings.Contains(rendered, "trustDomainAliases:"),
		"trustDomainAliases should NOT be rendered when not set")
}
