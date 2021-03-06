provider "aws" {
  region = var.region

  assume_role {
    role_arn = "arn:${var.partition}:iam::${var.account_id}:role/${var.role_name}"
  }
}

provider "aws" {
  alias  = "managment"
  region = var.region
}

variable "account_id" {
  description = "ID of the account"
  type        = number
}

variable "region" {
  description = "Region for the aws providers"
  type        = string
}

variable "partition" {
  description = "AWS partition hosting the account"
  type        = string
}

variable "role_name" {
  description = "Name of the role that will be assumed by terraform"
  type        = string
}
