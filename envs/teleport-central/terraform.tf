terraform {
  required_version = ">= 1.10.0"

  backend "gcs" {
    bucket = "teleport-my-organization-tfstate"
    prefix = "teleport-central/"
  }

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "7.16.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "3.0.1"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "3.1.1"
    }
  }
}
