terraform {

  required_version = ">= 1.3"

  required_providers {
    google = {
      source  = "hashicorp/google"
    }
    
    google-beta = {
      source  = "hashicorp/google-beta"
    }
  }
}

provider "google" {
  project     = var.project_id
  region      = var.project_region
  credentials = "keys.json"
}

provider "google-beta" {
  project     = var.project_id
  region      = var.project_region
  credentials = "keys.json"
}

variable "project_id" {
  description = "The project's ID."
  type        = string
  default     = "PROJECT_ID"
}

variable "project_region" {
  description = "The region that the project resides in."
  type        = string
  default     = "northamerica-northeast1"
}

// Virtual Private Cloud 
resource "google_compute_network" "test-network" {
  project                 = var.project_id
  name                    = "test-vpc"
  auto_create_subnetworks = false
}