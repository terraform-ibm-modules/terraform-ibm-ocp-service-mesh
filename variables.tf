##############################################################################
# Input Variables
##############################################################################

variable "cluster_id" {
  type        = string
  description = "Id of the target IBM Cloud OpenShift Cluster"
}

variable "resource_group_id" {
  type        = string
  description = "The ID of the resource group for the OpenShift Cluster."
}

variable "develop_mode" {
  type        = bool
  description = "If true raise time waited for operator deployment and undeployment to allow to debug the cluster"
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
