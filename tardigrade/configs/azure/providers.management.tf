
provider "azurerm" {
  features {}
  /*
  environment = var.environment

  # Note, you can comment out the block below if you would like to logon interactively through the cmdline instead
  client_id = var.client_id
  client_secret = var.client_secret
  subscription_id = var.subscription_id
  tenant_id = var.tenant_id
  */
}
/*
variable "environment" {
  description = "The environment to deploy into. Public is default, other options are usgovernment, german, and china"
  type = string  
}

variable "client_id" {
  description = "The client id of the Azure service principal or identity used to call the API. Must have Contributor to Tenant"
  type = string  
}

variable "client_secret" {
  description = "The client secret of the client_id identity"
  type = string  
}

variable "subscription_id" {
  description = "The ID of the subscription to authenticate into"
  type = string  
}

variable "tenant_id" {
  description = "The Tenant which the above subscription and client_id exist in"
  type = string  
}*/