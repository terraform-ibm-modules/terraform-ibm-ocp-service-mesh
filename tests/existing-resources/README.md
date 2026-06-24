# Existing Resources for NLB Testing

This Terraform configuration creates the prerequisite VPC infrastructure needed for testing NLB-based Istio ingress deployments.

## Resources Created

- **1 VPC**: A Virtual Private Cloud for hosting the resources
- **3 Subnets**: One subnet in each availability zone (zone-1, zone-2, zone-3)
- **3 Public Gateways**: One public gateway attached to each subnet for outbound internet connectivity

## Outputs

### `vpc_id`
The ID of the created VPC.

### `cluster_vpc_subnets`
A map of subnet lists formatted for the `ocp_base` module's `cluster_vpc_subnets` input:
```hcl
{
  subnet-1 = [{
    id         = "subnet-id-1"
    cidr_block = "10.x.x.x/24"
    zone       = "us-south-1"
  }]
  subnet-2 = [...]
  subnet-3 = [...]
}
```

### `nlb_zones_subnets`
A map of subnet IDs to zone names for NLB configuration in istio-ingress:
```hcl
{
  "subnet-id-1" = "us-south-1"
  "subnet-id-2" = "us-south-2"
  "subnet-id-3" = "us-south-3"
}
```

## Usage

1. Set required variables:
```bash
export TF_VAR_ibmcloud_api_key="your-api-key"
# Optionally set an existing resource group name, otherwise a new one will be created
# export TF_VAR_resource_group="your-resource-group-name"
```

2. Initialize and apply:
```bash
terraform init
terraform plan
terraform apply
```

3. Use outputs in your cluster and service mesh configuration:
```bash
terraform output vpc_id
terraform output cluster_vpc_subnets
terraform output nlb_zones_subnets
```

## Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| ibmcloud_api_key | IBM Cloud API key | string | - | yes |
| region | IBM Cloud region | string | us-south | no |
| resource_group | Existing resource group name (if null, creates new) | string | null | no |
| prefix | Prefix for resource names | string | test-nlb | no |
| tags | List of tags | list(string) | [] | no |

## Clean Up

To destroy all created resources:
```bash
terraform destroy