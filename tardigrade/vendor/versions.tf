terraform {
  required_version = "1.16.6" # terraform-version

  required_providers {
    aws = {
      source  = "registry.terraform.io/hashicorp/aws"
      version = "6.65.0"
    }

    external = {
      source  = "registry.terraform.io/hashicorp/external"
      version = "2.4.2"
    }

    local = {
      source  = "registry.terraform.io/hashicorp/local"
      version = "2.9.1"
    }

    null = {
      source  = "registry.terraform.io/hashicorp/null"
      version = "3.3.2"
    }

    random = {
      source  = "registry.terraform.io/hashicorp/random"
      version = "3.9.1"
    }
  }
}
