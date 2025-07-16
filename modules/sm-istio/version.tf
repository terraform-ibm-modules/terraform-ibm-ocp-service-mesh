terraform {
  required_version = ">= 1.9.0"
  required_providers {
    # Use "greater than or equal to" range in modules
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.8.0"
    }
  }
}
