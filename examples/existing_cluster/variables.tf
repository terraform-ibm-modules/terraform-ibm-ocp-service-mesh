variable "ibmcloud_api_key" {
  type        = string
  description = "IBM Cloud API Key for a user / serviceId with write access to the corresponding namespace in the OCP cluster"
  sensitive   = true
}

variable "region" {
  type        = string
  description = "Region where resources are created"
}

variable "existing_cluster_id" {
  type        = string
  nullable    = false
  description = "Existing cluster ID. Cannot be null or empty"
  validation {
    condition     = var.existing_cluster_id != ""
    error_message = "var.existing_cluster_id cannot be an empty string"
  }
}

variable "existing_resource_group" {
  type        = string
  description = "Existing resource group name to be used. Cannot be null or empty"
  nullable    = false
  validation {
    condition     = var.existing_resource_group != ""
    error_message = "var.existing_resource_group cannot be an empty string"
  }
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

variable "istio_controlplane_name" {
  description = "Name of the Istio controlplane"
  type        = string
  default     = "istio-sm-v3"
  nullable    = false
}

variable "istio_controlplane_namespace" {
  description = "Namespace to deploy the Istio controlplane"
  type        = string
  default     = "istio-system-v3"
  nullable    = false
}
