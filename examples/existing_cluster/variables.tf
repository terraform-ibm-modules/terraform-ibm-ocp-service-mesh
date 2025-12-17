variable "ibmcloud_api_key" {
  type        = string
  description = "IBM Cloud API Key for a user / serviceId with write access to the corresponding namespace in the OCP cluster"
  sensitive   = true
}

variable "prefix" {
  type        = string
  description = "Prefix for name of all resource created by this example"
  default     = "ocpsm-excluster"
}

variable "region" {
  type        = string
  description = "Region where resources are created"
}

variable "existing_cluster_id" {
  type        = string
  description = "Existing cluster ID to deploy the ServiceMesh"
  nullable    = false
}

variable "resource_group" {
  type        = string
  description = "Optionally pass an existing resource group name to be used. If not passed a new one will be created"
  default     = null
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
    error_message = "Invalid Endpoint Type! Valid values are 'default', 'private', 'vpe', or 'link'"
    condition     = contains(["default", "private", "vpe", "link"], var.cluster_config_endpoint_type)
  }
}
