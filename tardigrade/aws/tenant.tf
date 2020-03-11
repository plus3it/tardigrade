terraform {
  required_version = "0.12.23"

  backend "s3" {}
}

provider aws {
  version = "~> 2.52"
  region  = "${var.region}"
}

provider null {
  version = "~> 2.1"
}

provider random {
  version = "~> 2.2"
}

provider template {
  version = "~> 2.1"
}

provider external {
  version = "~> 1.2"
}

variable "partition" {
  description = "AWS Partition where account exists"
  type        = string
}

variable "region" {
  description = "The region where resources are being deployed"
  type        = string
}
