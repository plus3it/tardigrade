resource "azurerm_storage_account" "example" {
  name                     = var.storage_account
  resource_group_name      = var.resource_group
  location                 = var.resource_group_location
  account_tier             = "Standard"
  account_replication_type = "GRS"

  tags = var.tags
}