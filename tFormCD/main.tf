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
#  alias       = "google-beta"
}

################################## FIREWALL POLICIES ###################################

# Allow Health Check Traffic
resource "google_compute_firewall" "allow_health_check" {
  name          = "${var.project_id}-lb-fw-allow-hc"
  direction     = "INGRESS"
  network       = google_compute_network.vpc-network.id
  source_ranges = ["35.191.0.0/16", "130.211.0.0/22"]
  allow {
    protocol = "tcp"
  }
  target_tags = ["allow-health-check"]

  depends_on = [
    google_compute_network.vpc-network
  ]

}
