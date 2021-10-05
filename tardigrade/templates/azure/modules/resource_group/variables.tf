variable "tags" {
  description = "The tags applied to the RG"
  type        = map(string)
  default     = {}
}

variable "location" {
    description = "the region location to deploy the RG into"
    type = string
}

variable "resource_group" {
    description = "the name of the RG"
    type = string
}