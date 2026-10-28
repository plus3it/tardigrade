variable "account_name" {
  description = "Name of the account"
  type        = string
}

variable "namespace" {
  description = "Namespace to uniquely identify global resources. In use, this will be prepended to `account_name`"
  type        = string
}

variable "saml_providers" {
  description = "List of SAML identity providers"
  type = list(object({
    name     = string
    metadata = string
  }))
  default = []
}

variable "global_region" {
  description = "Primary region for the partition where global resources are deployed"
  type        = string
}
