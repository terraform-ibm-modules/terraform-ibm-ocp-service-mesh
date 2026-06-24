variable "ibmcloud_api_key" {
  description = "IBM Cloud API key"
  type        = string
  sensitive   = true
}

variable "region" {
  description = "IBM Cloud region where resources will be created"
  type        = string
  default     = "us-south"
}

variable "resource_group" {
  description = "An existing resource group name to use for this example, if null a new one will be created"
  type        = string
  default     = null
}

variable "prefix" {
  description = "Prefix for naming resources"
  type        = string
  default     = "test-nlb"
}

variable "tags" {
  description = "List of tags to apply to resources"
  type        = list(string)
  default     = []
}