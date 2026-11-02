variable "account_name" {
  description = "Name of the account"
  type        = string
}

variable "email_address" {
  description = "Email address of the account"
  type        = string
}

variable "namespace" {
  description = "Namespace to uniquely identify global resources. In use, this will be prepended to `account_name`"
  type        = string
}

variable "cloudtrail_bucket" {
  description = "Name of S3 bucket to send cloudtrail data; bucket must already exist"
  type        = string
}

variable "config_bucket" {
  description = "Name of S3 bucket to send config data; bucket must already exist"
  type        = string
}

variable "global_region" {
  description = "Primary region for the partition where global resources are deployed"
  type        = string
}
