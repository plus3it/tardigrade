/*
data "aws_partition" "this" {}

data "aws_caller_identity" "this" {} 
*/

locals {
  /*
  account_id = data.aws_caller_identity.this.account_id
  partition  = data.aws_partition.this.partition
  */


  account_name = lower(replace(var.account_name, "_", "-"))
  namespace    = lower(replace("${var.namespace}-${var.account_name}", "_", "-"))
  tags         = merge(var.tags, local.mandatory_tags)

  mandatory_tags = {
    TardigradeManaged = "true"
  }

  resource_groups = [for resource_group in [
    {
      label = "core-mgmt-rg"
      name  = "${local.namespace}-core-mgmt-rg"
      location = "East US"
      /*policy = templatefile("${path.module}/policy_templates/cloudtrail-bucket-policy.json.hcl.template", {
        partition = local.partition
        bucket    = "${local.namespace}-cloudtrail"
      })*/
    },
    /*{
      label = "config"
      name  = "${local.namespace}-config"
      policy = templatefile("${path.module}/policy_templates/config-bucket-policy.json.hcl.template", {
        partition = local.partition
        bucket    = "${local.namespace}-config"
      })
    },*/
  ] : merge(local.resource_group_defaults, resource_group)]
  resource_group_defaults = {
    tags       = local.tags
  }


  storage_accounts = [for storage_account in [
    {
      label = "azureactivity"
      name  = "${local.namespace}-azureactivity"
      /*policy = templatefile("${path.module}/policy_templates/cloudtrail-bucket-policy.json.hcl.template", {
        partition = local.partition
        bucket    = "${local.namespace}-cloudtrail"
      })*/
    },
    /*{
      label = "config"
      name  = "${local.namespace}-config"
      policy = templatefile("${path.module}/policy_templates/config-bucket-policy.json.hcl.template", {
        partition = local.partition
        bucket    = "${local.namespace}-config"
      })
    },*/
  ] : merge(local.storage_account_defaults, storage_account)]

  storage_account_defaults = {
    tags       = local.tags
    /*
    versioning = true
    public_access_block = {
      block_public_acls       = true
      block_public_policy     = true
      ignore_public_acls      = true
      restrict_public_buckets = true
    }*/
    /*
    lifecycle_rules = [
      {
        id      = "transition"
        enabled = true
        prefix  = null
        tags    = null

        abort_incomplete_multipart_upload_days = 7

        expiration = {
          date                         = null
          days                         = 365
          expired_object_delete_marker = false
        }

        transitions = [
          {
            date          = null
            days          = 30
            storage_class = "STANDARD_IA"
          },
          {
            date          = null
            days          = 180
            storage_class = "GLACIER"
          },
        ]

        noncurrent_version_expiration = {
          days = 365
        }

        noncurrent_version_transitions = [
          {
            date          = null
            days          = 30
            storage_class = "STANDARD_IA"
          },
          {
            date          = null
            days          = 180
            storage_class = "GLACIER"
          },
        ]
      },
    ]*/
  }
}
