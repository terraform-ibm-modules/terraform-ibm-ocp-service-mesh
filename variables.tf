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

# CUSTOM CATALOG SOURCE VARIABLES FOR SERVICE MESH OPERATOR

variable "sm_operator_custom_catalog_name" {
  type        = string
  description = "Name of the custom Catalog Source for the Service Mesh Operator"
  default     = null
}

variable "sm_operator_custom_catalog_namespace" {
  type        = string
  description = "Namespace of the custom Catalog Source for the Service Mesh Operator"
  default     = "openshit-marketplace"
}

variable "sm_operator_custom_catalog_description" {
  type        = string
  description = "Description of the custom Catalog Source for the Service Mesh Operator"
  default     = null
}

variable "sm_operator_custom_catalog_publisher" {
  type        = string
  description = "Publisher of the custom Catalog Source for the Service Mesh Operator"
  default     = null
}

variable "sm_operator_custom_catalog_registry_url" {
  type        = string
  description = "Registry URL for the mirrored Service Mesh Operator images"
  default     = "icr.io"
}

variable "sm_operator_custom_catalog_registry_pullsecret_name" {
  type        = string
  description = "Name of the cluster secret to store the pull secret to access the registry for the mirrored Service Mesh Operator images"
  default     = null
}

variable "sm_operator_custom_catalog_registry_pullsecret_value" {
  type        = string
  description = "Value of the pull secret to access the registry for the mirrored Service Mesh Operator images"
  default     = null
  sensitive   = true
}

variable "sm_operator_custom_catalog_index_name" {
  type        = string
  description = "Name of the catalog index for the custom Catalog Source for the Service Mesh Operator"
  default     = null
}

variable "sm_operator_custom_catalog_image_digest" {
  type        = string
  description = "Digest of the catalog index image for the custom Catalog Source for the Service Mesh Operator"
  default     = null
}

variable "clean_servicemesh_on_undeploy" {
  type        = bool
  description = "Flag to perform a cleanup of ServiceMesh operator custom resources when undeploying the module. Default to true. For more details refer to https://docs.redhat.com/en/documentation/red_hat_openshift_service_mesh/3.1/html-single/uninstalling/index ."
  default     = true
  nullable    = false
}
