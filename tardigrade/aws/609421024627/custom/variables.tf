# Placeholders for "undeclared variables" from tenant-local.auto.tfvars
variable "name" {
  type    = string
  default = null
}

variable "stage" {
  type    = string
  default = null

}

variable "private_subnets" {
  type    = list
  default = []
}

variable "public_subnets" {
  type    = list
  default = []
}

variable "vpc_cidr" {
  type    = string
  default = null
}

variable "handsoff" {
  type    = string
  default = false
}
