terraform {
  required_version = ">= 1.9.0"
  required_providers {
    # Pin to the lowest provider version of the range defined in the main module to ensure lowest version still works
    ibm = {
      source  = "IBM-Cloud/ibm"
      version = "= 1.79.2"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "= 3.0.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "= 2.38.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "= 0.9.1"
    }
  }
}
