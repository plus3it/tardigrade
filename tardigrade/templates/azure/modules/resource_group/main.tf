resource "azurerm_resource_group" "example" {
  name     = var.resource_group
  location = var.location
  tags = var.tags
}

output "rg_name" {
  value = azurerm_resource_group.example.name
}

output "rg_location" {
  value = azurerm_resource_group.example.location
}

output "rg_id" {
  value = azurerm_resource_group.example.id
}