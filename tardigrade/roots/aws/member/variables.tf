variable "name" {
  description = "Name of the account"
  type        = string
}

variable "stage" {
  description = "Stage for the account"
  type        = string
}

variable "handsoff" {
  description = "Toggle controlling whether to create only the `handsoff` resources"
  type        = bool
  default     = false
}

variable "tags" {
  description = "A map of tags to add to all managed resources that support tags"
  type        = map(string)
  default     = {}
}

##### VPC VARIABLES #####
variable "vpc_cidr" {
  description = "The CIDR block of the VPC to create"
  type        = string
  default     = null
}

variable "private_subnets" {
  description = "A list of private subnets inside the VPC"
  type        = list(string)
  default     = []
}

variable "public_subnets" {
  description = "A list of public subnets inside the VPC"
  type        = list(string)
  default     = []
}

variable "enable_dns_hostnames" {
  description = "Boolean to control the VPC option to enable DNS hostnames"
  default     = true
}

variable "enable_dns_support" {
  description = "Boolean to control the VPC option to enable DNS support"
  default     = true
}

variable "dhcp_options_domain_name" {
  description = "Domain name to use with the DHCP Option Set"
  type        = string
  default     = "ec2.internal"
}

variable "dhcp_options_domain_name_servers" {
  description = "List of DNS server IP address to use with the DHCP Option Set"
  type        = list(string)

  default = [
    "AmazonProvidedDNS",
  ]
}

##### KEYSTORE VARIABLES #####
variable "keystore_bucket" {
  description = "Name of the S3 keystore bucket in the account"
  type        = string
}

variable "keystore_prefix" {
  description = "Path prefix to the keystore in the keystore bucket"
  type        = string
  default     = "vars"
}

variable "keystore_bucket_versioning" {
  description = "Whether versioning is enabled on keystore bucket"
  default     = true
}

##### VPC FLOW LOG VARIABLES #####
variable "vpcflowlog_bucket" {
  description = "Name of the S3 vpcflowlog bucket in parent account"
  type        = string
}

variable "vpcflowlog_bucket_versioning" {
  description = "Whether versioning is enabled on keystore bucket"
  default     = true
}

##### CLOUDTRAIL VARIABLES #####
variable "cloudtrail_bucket" {
  description = "Name of S3 bucket to send cloudtrail logs"
  type        = string
}

variable "cloudtrail_bucket_versioning" {
  description = "Whether versioning is enabled on parent cloudtrail bucket"
  default     = false
}

##### CONFIG VARIABLES #####
variable "config_bucket" {
  description = "Name of S3 bucket to send config inventory"
  type        = string
}

variable "config_bucket_versioning" {
  description = "Whether versioning is enabled on parent config bucket"
  default     = false
}

##### SECURITY GROUP VARIABLES #####
variable "default_vpc_sg_ingress_rules" {
  description = "A schema list of ingress rules for the default vpc's default security group, see https://www.terraform.io/docs/providers/aws/r/security_group.html#ingress"
  type        = list(any)
  default     = []
}

variable "default_vpc_sg_egress_rules" {
  description = "A schema list of egress rules for the default vpc's default security group, see https://www.terraform.io/docs/providers/aws/r/security_group.html#egress"
  type        = list(any)
  default     = []
}

variable "default_vpc_revoke_rules_on_delete" {
  description = "Determines whether to forcibly remove rules when destroying the default vpc's default security group"
  type        = string
  default     = false
}

variable "vpc_module_sg_ingress_rules" {
  description = "A schema list of ingress rules for the vpc module's default security group, see https://www.terraform.io/docs/providers/aws/r/security_group.html#ingress"
  type        = list(any)
  default     = []
}

variable "vpc_module_sg_egress_rules" {
  description = "A schema list of egress rules for the vpc module's default security group, see https://www.terraform.io/docs/providers/aws/r/security_group.html#egress"
  type        = list(any)
  default     = []
}

variable "vpc_module_revoke_rules_on_delete" {
  description = "Determines whether to forcibly remove rules when destroying the vpc module's default security group"
  type        = string
  default     = false
}
