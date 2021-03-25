provider "aws" {
  region = var.region
}

variable "region" {
  description = "Region for the aws providers"
  type        = string
}
