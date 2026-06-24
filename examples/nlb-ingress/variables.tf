variable "ibmcloud_api_key" {
  type        = string
  description = "IBM Cloud API Key for a user / serviceId with write access to the corresponding namespace in the OCP cluster"
  sensitive   = true
}

variable "prefix" {
  type        = string
  description = "Prefix for name of all resource created by this example"
  default     = "ocpsm-nlb"
}

variable "region" {
  type        = string
  description = "Region where resources are created"
}

variable "resource_group_id" {
  type        = string
  description = "Resource group ID to use for the cluster and resources"
}

variable "resource_tags" {
  type        = list(string)
  description = "Optional list of tags to be added to created resources"
  default     = []
}

variable "develop_mode" {
  type        = bool
  description = "If true, output more logs, and reduce some wait periods"
  default     = false
}

variable "cluster_config_endpoint_type" {
  description = "Specify which type of endpoint to use for for cluster config access: 'default', 'private', 'vpe', 'link'. 'default' value will use the default endpoint of the cluster."
  type        = string
  default     = "default"
  nullable    = false
  validation {
    error_message = "Invalid Endpoint Type. Valid values are 'default', 'private', 'vpe', or 'link'"
    condition     = contains(["default", "private", "vpe", "link"], var.cluster_config_endpoint_type)
  }
}

variable "service_mesh_operator_version" {
  description = "Version of the ServiceMesh v3 operator to deploy. If null the default one will be installed"
  type        = string
  default     = null
}

##############################################################################
# External VPC and Subnet Variables
##############################################################################

variable "vpc_id" {
  type        = string
  description = "ID of the existing VPC to use for the cluster"
}

variable "cluster_vpc_subnets" {
  description = "Map of subnet lists for cluster creation. Each key represents a subnet group, and each value is a list of subnet objects with id, zone, and cidr_block"
  type = map(list(object({
    id         = string
    zone       = string
    cidr_block = string
  })))
}

variable "ingress_nlb_zones_subnets" {
  description = "Map of subnet IDs to zone names for NLB ingress configuration. Key is subnet ID, value is zone name (e.g., 'us-south-1')"
  type        = map(string)
}