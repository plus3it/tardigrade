variable "storage_account" {
    description = "the name of the storage account to be created"
    type = string(12)
}
variable "resource_group" {
    description = "the name of the RG to deploy the SA into"
    type = string
}

variable "resource_group_location" {
    description = "the location of the RG to deploy the SA into"
    type = string
}

variable "tags" {
  description = "The tags applied to the SA"
  type        = map(string)
  default     = {}
}