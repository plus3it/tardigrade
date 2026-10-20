provider "aws" {
  region = var.region

  assume_role {
    role_arn     = "arn:${var.partition}:iam::${var.account_id}:role/${var.role_name}"
    session_name = var.session_name
  }

  default_tags {
    tags = var.default_tags
  }
}

provider "aws" {
  alias  = "management"
  region = var.region

  assume_role {
    role_arn     = "arn:${var.partition}:iam::${var.management_account_id}:role/${var.role_name}"
    session_name = var.session_name
  }

  default_tags {
    tags = var.default_tags
  }
}

variable "account_id" {
  description = "ID of the account"
  type        = string
}

variable "region" {
  description = "Region for the aws providers"
  type        = string
}

variable "partition" {
  description = "AWS partition hosting the account"
  type        = string
  default     = "aws"
}

variable "session_name" {
  description = "Name of the session when assuming a role"
  type        = string
  default     = null
}

variable "role_name" {
  description = "Name of the role that will be assumed by terraform"
  type        = string
  default     = "OrganizationAccountAccessRole"
}

variable "management_account_id" {
  description = "ID of the management account"
  type        = string
}

variable "default_tags" {
  description = "Map of default tags to apply to all resources"
  type        = map(string)
  default     = {}
}
