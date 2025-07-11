##############################################################################
# Input Variables
##############################################################################

# variable "ibmcloud_api_key" {
#   description = "APIkey that's associated with the account to use, set via environment variable TF_VAR_ibmcloud_api_key"
#   type        = string
#   sensitive   = true
#   default     = null
# }

variable "cluster_id" {
  type        = string
  description = "Id of the target IBM Cloud OpenShift Cluster"
}

variable "deploy_operator" {
  type        = bool
  description = "Enable installing RedHat Service Mesh Operator"
  default     = true
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
