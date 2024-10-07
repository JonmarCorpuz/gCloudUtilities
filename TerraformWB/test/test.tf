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
  project     = "PROJECT_ID"
  region      = "northamerica-northeast1"
  credentials = "keys.json"
}

provider "google-beta" {
  project     = "PROJECT_ID"
  region      = "northamerica-northeast1"
  credentials = "keys.json"
}

// Virtual Private Cloud 
resource "google_compute_network" "test-network" {
  project                 = "PROJECT_ID"
  name                    = "test-vpc"
  auto_create_subnetworks = false
}
