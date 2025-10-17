variable "ibmcloud_api_key" {
  type        = string
  description = "IBM Cloud API Key for a user / serviceId with write access to the corresponding namespace in the OCP cluster"
  sensitive   = true
}

variable "prefix" {
  type        = string
  description = "Prefix for name of all resource created by this example"
  default     = "ocp-smv3"
}

variable "region" {
  type        = string
  description = "Region where resources are created"
}

variable "resource_group" {
  type        = string
  description = "Optionally pass an existing resource group name to be used. If not passed a new one will be created"
  default     = null
}

variable "resource_tags" {
  type        = list(string)
  description = "Optional list of tags to be added to created resources"
  default     = []
}
