data "aws_partition" "this" {}

data "aws_caller_identity" "this" {}

locals {
  account_id = data.aws_caller_identity.this.account_id
  partition  = data.aws_partition.this.partition


  account_name = lower(replace(var.account_name, "_", "-"))
  namespace    = lower(replace("${var.namespace}-${var.account_name}", "_", "-"))
  tags         = merge(var.tags, local.mandatory_tags)

  mandatory_tags = {
    TardigradeManaged = "true"
  }

  buckets = [for bucket in [
    {
      label = "cloudtrail"
      name  = "${local.namespace}-cloudtrail"
      policy = templatefile("${path.module}/policy_templates/cloudtrail-bucket-policy.json.hcl.template", {
        partition = local.partition
        bucket    = "${local.namespace}-cloudtrail"
      })
    },
    {
      label = "config"
      name  = "${local.namespace}-config"
      policy = templatefile("${path.module}/policy_templates/config-bucket-policy.json.hcl.template", {
        partition = local.partition
        bucket    = "${local.namespace}-config"
      })
    },
  ] : merge(local.bucket_defaults, bucket)]

  bucket_defaults = {
    tags       = local.tags
    versioning = true
    public_access_block = {
      block_public_acls       = true
      block_public_policy     = true
      ignore_public_acls      = true
      restrict_public_buckets = true
    }
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
    ]
  }
}
