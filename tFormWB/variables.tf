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

variable "project_zones" {
  description = "The zones that the project will reside in."

  type = object({
    zone_a = string
    zone_b = string
    zone_c = string
  })

  default = {
    zone_a = "northamerica-northeast1-a"
    zone_b = "northamerica-northeast1-b"
    zone_c = "northamerica-northeast1-c"
  }
}
