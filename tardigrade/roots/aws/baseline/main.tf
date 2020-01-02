module "validate_stage" {
  source = "git::https://github.com/plus3it/terraform-null-validate-list-item.git?ref=1.0.0"

  providers = {
    aws = aws
  }

  name = "Stage"
  item = var.stage

  valid_items = [
    "dev",
    "test",
    "prod",
  ]
}

locals {
  # associate account baselines to services/features
  handsoff = var.handsoff == true

  # services common to all account baselines
  create_keystore          = true
  create_iam_account       = true
  create_vpc               = ! local.handsoff
  create_vpc_flow_log      = ! local.handsoff
  create_cloudtrail        = true
  create_config_bucket     = true
  create_cloudtrail_bucket = true
  create_keystore_bucket   = true
  create_config            = ! local.handsoff
  create_config_rules      = ! local.handsoff
  create_iam_roles         = true
  create_vpc_endpoints     = false
  create_saml_provider     = true
  create_inspector         = true
  create_tgw_attachment    = ! local.handsoff

  # services only in aws partition
  #   peering connection
  #   bastion sg
  #   route53 subzone
  #   codebuild
  #   ram resource share

  create_peering_connection        = ! local.handsoff && var.partition == "aws"
  create_bastion_sg                = ! local.handsoff && var.partition == "aws"
  create_route53_subzone           = ! local.handsoff && var.partition == "aws"
  create_route53_query_log         = ! local.handsoff && var.partition == "aws"
  create_config_authorization      = ! local.handsoff && var.partition == "aws"
  create_guardduty_member          = ! local.handsoff && var.partition == "aws"
  create_ram_principal_association = ! local.handsoff && var.partition == "aws"
  create_resolver_rule_association = ! local.handsoff && var.partition == "aws"
  excluded_config_rules = {
    "handsoff"   = []
    "aws"        = []
    "aws-us-gov" = []
  }
  iam_service_url_suffix = {
    "aws"        = "amazonaws.com"
    "aws-us-gov" = "amazonaws.com"
  }
  iam_saml_audience = {
    "aws"        = "https://signin.aws.amazon.com/saml"
    "aws-us-gov" = "https://signin.amazonaws-us-gov.com/saml"
  }
}

locals {
  name_tag             = "${var.name}-${var.stage}"
  name_tag_capitalized = upper(replace(local.name_tag, "-", "_"))
  tags = {
    BrokerManaged = true
    Stage         = var.stage
    Tenant        = var.name
  }
}

data "aws_caller_identity" "this" {}

data "aws_availability_zones" "all" {}

##### KEYSTORE #####
# Keys to be stored in the `keystore` and `keystore_ssm` modules
locals {
  # setup the keystore keys and values
  keys = [
    "name",
    "private_subnets",
    "public_subnets",
    "stage",
    "vpc_cidr",
  ]

  values = [
    var.name,
    var.private_subnets,
    var.public_subnets,
    var.stage,
    format("%v", var.vpc_cidr),
  ]

  values_encoded = [for value in local.values : jsonencode(value)]
}

data "template_file" "keystore_bucket_policy" {
  count = local.create_keystore_bucket ? 1 : 0

  template = file("${path.module}/templates/keystore-bucket-policy.json")

  vars = {
    bucket     = var.keystore_bucket
    prefix     = var.keystore_prefix
    partition  = var.partition
    account_id = data.aws_caller_identity.this.account_id
  }
}

module "keystore_bucket" {
  source = "git::https://github.com/plus3it/terraform-aws-tardigrade-s3-bucket.git?ref=1.0.4"

  providers = {
    aws = aws
  }

  create_bucket = local.create_keystore_bucket
  bucket        = var.keystore_bucket
  region        = var.region
  policy        = join("", data.template_file.keystore_bucket_policy.*.rendered)
  versioning    = var.keystore_bucket_versioning
  tags          = local.tags
  force_destroy = true
}

module "keystore_s3" {
  source = "git::https://github.com/plus3it/terraform-aws-tardigrade-keystore.git?ref=1.0.0"

  providers = {
    aws = aws
  }

  create_keystore = local.create_keystore
  bucket_name     = var.keystore_bucket
  tags            = local.tags

  # Map of `vars/<account_id>/<var>: <encoded value>`
  key_value_map = zipmap(
    formatlist(
      "${var.keystore_prefix}/${data.aws_caller_identity.this.account_id}/%s",
      local.keys,
    ),
    local.values_encoded,
  )
}

module "keystore_ssm" {
  source = "git::https://github.com/plus3it/terraform-aws-tardigrade-keystore.git?ref=1.0.0"

  providers = {
    aws = aws
  }

  create_keystore = local.create_keystore
  backend         = "ssm"
  bucket_name     = var.keystore_bucket
  tags            = local.tags

  # Map of `vars/<account_id>: <encoded map of <var>: <value>>`
  key_value_map = {
    "${var.keystore_prefix}/${data.aws_caller_identity.this.account_id}" = jsonencode(zipmap(local.keys, local.values_encoded))
  }
}

##### IAM ALIAS #####
module "iam_account" {
  source = "git::https://github.com/plus3it/terraform-aws-tardigrade-iam-account.git?ref=1.0.1"

  providers = {
    aws = aws
  }

  create_iam_account = local.create_iam_account
  account_alias      = local.name_tag
  max_password_age   = "60"
}

##### IAM USERS #####
locals {
  # setup user template with required keys
  user_base = {
    policy_arns          = []
    inline_policies      = []
    force_destroy        = null
    path                 = null
    permissions_boundary = null
    tags                 = {}
  }

  # setup users to be created
  users = [{
    name = "alpha",
    }, {
    name = "beta",
  }]
}

module "iam_users" {
  source = "git::https://github.com/plus3it/terraform-aws-tardigrade-iam-principals.git?ref=3.0.0"

  providers = {
    aws = aws
  }

  create_policies = false
  create_roles    = false
  create_users    = true
  force_destroy   = true

  # merge users to be created with user template to ensure all required keys are being defined
  users = [for user in local.users : merge(local.user_base, user)]

  template_paths = []
}

##### VPC #####
module "vpc" {
  source = "github.com/plus3it/terraform-aws-vpc?ref=v2.15.0"

  providers = {
    aws = aws
  }

  create_vpc               = local.create_vpc
  name                     = local.name_tag
  tags                     = local.tags
  cidr                     = var.vpc_cidr
  azs                      = data.aws_availability_zones.all.names
  private_subnets          = var.private_subnets
  public_subnets           = var.public_subnets
  enable_dns_hostnames     = var.enable_dns_hostnames
  enable_dns_support       = var.enable_dns_support
  enable_nat_gateway       = true
  single_nat_gateway       = true
  map_public_ip_on_launch  = false
  enable_s3_endpoint       = true
  enable_dynamodb_endpoint = true

  enable_dhcp_options              = true
  dhcp_options_domain_name         = var.dhcp_options_domain_name
  dhcp_options_domain_name_servers = var.dhcp_options_domain_name_servers
}

module "vpc_endpoints" {
  source = "git::https://github.com/plus3it/terraform-aws-tardigrade-vpc-endpoints.git?ref=1.0.0"

  providers = {
    aws = aws
  }

  create_vpc_endpoints    = local.create_vpc_endpoints
  subnet_ids              = module.vpc.private_subnets
  vpc_endpoint_interfaces = []
  tags                    = local.tags
}

##### VPC FLOW LOGS #####
data "template_file" "vpcflowlog_bucket_policy" {
  count = local.create_keystore_bucket ? 1 : 0

  template = file("${path.module}/templates/vpcflowlog-bucket-policy.json")

  vars = {
    bucket    = var.vpcflowlog_bucket
    partition = var.partition
  }
}

module "vpcflowlog_bucket" {
  source = "git::https://github.com/plus3it/terraform-aws-tardigrade-s3-bucket.git?ref=1.0.4"

  providers = {
    aws = aws
  }

  create_bucket = local.create_keystore_bucket
  bucket        = var.vpcflowlog_bucket
  region        = var.region
  policy        = join("", data.template_file.vpcflowlog_bucket_policy.*.rendered)
  versioning    = var.vpcflowlog_bucket_versioning
  tags          = local.tags
  force_destroy = true
}

module "vpc_flow_log" {
  source = "git::https://github.com/plus3it/terraform-aws-tardigrade-vpc-flow-log.git?ref=1.0.0"

  providers = {
    aws = aws
  }

  create_vpc_flow_log  = local.create_vpc_flow_log
  log_destination_type = "s3"
  log_destination      = module.vpcflowlog_bucket.bucket_arn
  vpc_id               = module.vpc.vpc_id
  tags                 = local.tags
}

##### CLOUDTRAIL #####
data "template_file" "cloudtrail_bucket_policy" {
  count = local.create_cloudtrail_bucket ? 1 : 0

  template = file("${path.module}/templates/cloudtrail-bucket-policy.json")

  vars = {
    bucket    = var.cloudtrail_bucket
    partition = var.partition
  }
}

module "cloudtrail_bucket" {
  source = "git::https://github.com/plus3it/terraform-aws-tardigrade-s3-bucket.git?ref=1.0.4"

  providers = {
    aws = aws
  }

  create_bucket = local.create_cloudtrail_bucket
  bucket        = var.cloudtrail_bucket
  region        = var.region
  policy        = join("", data.template_file.cloudtrail_bucket_policy.*.rendered)
  versioning    = var.cloudtrail_bucket_versioning
  tags          = local.tags
  force_destroy = true
}

module "cloudtrail" {
  source = "git::https://github.com/plus3it/terraform-aws-tardigrade-cloudtrail.git?ref=2.2.2"

  providers = {
    aws = aws
  }

  create_cloudtrail = local.create_cloudtrail
  cloudtrail_name   = "${local.name_tag}-cloudtrail"
  cloudtrail_bucket = var.cloudtrail_bucket
  tags              = local.tags
}

##### CONFIG #####
data "template_file" "config_bucket_policy" {
  count = local.create_config_bucket ? 1 : 0

  template = file("${path.module}/templates/config-bucket-policy.json")

  vars = {
    bucket    = var.config_bucket
    partition = var.partition
  }
}

module "config_bucket" {
  source = "git::https://github.com/plus3it/terraform-aws-tardigrade-s3-bucket.git?ref=1.0.4"

  providers = {
    aws = aws
  }

  create_bucket = local.create_config_bucket
  bucket        = var.config_bucket
  region        = var.region
  policy        = join("", data.template_file.config_bucket_policy.*.rendered)
  versioning    = var.config_bucket_versioning
  tags          = local.tags
  force_destroy = true
}

module "config" {
  source = "git::https://github.com/plus3it/terraform-aws-tardigrade-config.git?ref=1.0.4"

  providers = {
    aws = aws
  }

  create_config = local.create_config
  account_id    = data.aws_caller_identity.this.account_id
  config_bucket = var.config_bucket
  tags          = local.tags
}

module "config_rules" {
  source = "git::https://github.com/plus3it/terraform-aws-tardigrade-config-rules.git?ref=1.0.5"

  providers = {
    aws = aws
  }

  create_config_rules  = local.create_config_rules
  cloudtrail_bucket    = var.cloudtrail_bucket
  config_recorder      = module.config.config_recorder_id
  exclude_rules        = local.excluded_config_rules[var.partition]
  config_bucket        = var.config_bucket
  config_sns_topic_arn = module.config.config_sns_topic_arn
  tags                 = local.tags
}

##### INSPECTOR #####
module "inspector" {
  source = "git::https://github.com/plus3it/terraform-aws-tardigrade-inspector.git?ref=1.0.5"

  providers = {
    aws = aws
  }

  # Member
  create_inspector = local.create_inspector
  name             = "${local.name_tag}-inspector"
  schedule         = "rate(7 days)"
  tags             = local.tags
}

##### MANAGING DEFAULT RESOURCES #####
### DEFAULT VPC ###
data "aws_vpc" "default" {
  default = true
}

### DEFAULT SECURITY GROUPS ###
#default vpc security group
resource "aws_default_security_group" "default" {
  vpc_id = data.aws_vpc.default.id

  dynamic "ingress" {
    for_each = var.default_vpc_sg_ingress_rules
    content {
      cidr_blocks      = lookup(ingress.value, "cidr_blocks", null)
      description      = lookup(ingress.value, "description", null)
      from_port        = lookup(ingress.value, "from_port", null)
      ipv6_cidr_blocks = lookup(ingress.value, "ipv6_cidr_blocks", null)
      prefix_list_ids  = lookup(ingress.value, "prefix_list_ids", null)
      protocol         = lookup(ingress.value, "protocol", null)
      security_groups  = lookup(ingress.value, "security_groups", null)
      self             = lookup(ingress.value, "self", null)
      to_port          = lookup(ingress.value, "to_port", null)
    }
  }

  dynamic "egress" {
    for_each = var.default_vpc_sg_egress_rules
    content {
      cidr_blocks      = lookup(egress.value, "cidr_blocks", null)
      description      = lookup(egress.value, "description", null)
      from_port        = lookup(egress.value, "from_port", null)
      ipv6_cidr_blocks = lookup(egress.value, "ipv6_cidr_blocks", null)
      prefix_list_ids  = lookup(egress.value, "prefix_list_ids", null)
      protocol         = lookup(egress.value, "protocol", null)
      security_groups  = lookup(egress.value, "security_groups", null)
      self             = lookup(egress.value, "self", null)
      to_port          = lookup(egress.value, "to_port", null)
    }
  }
  revoke_rules_on_delete = var.default_vpc_revoke_rules_on_delete
  tags                   = var.tags
}

resource "aws_default_security_group" "this" {
  vpc_id = module.vpc.vpc_id

  dynamic "ingress" {
    for_each = var.vpc_module_sg_ingress_rules
    content {
      cidr_blocks      = lookup(ingress.value, "cidr_blocks", null)
      description      = lookup(ingress.value, "description", null)
      from_port        = lookup(ingress.value, "from_port", null)
      ipv6_cidr_blocks = lookup(ingress.value, "ipv6_cidr_blocks", null)
      prefix_list_ids  = lookup(ingress.value, "prefix_list_ids", null)
      protocol         = lookup(ingress.value, "protocol", null)
      security_groups  = lookup(ingress.value, "security_groups", null)
      self             = lookup(ingress.value, "self", null)
      to_port          = lookup(ingress.value, "to_port", null)
    }
  }

  dynamic "egress" {
    for_each = var.vpc_module_sg_egress_rules
    content {
      cidr_blocks      = lookup(egress.value, "cidr_blocks", null)
      description      = lookup(egress.value, "description", null)
      from_port        = lookup(egress.value, "from_port", null)
      ipv6_cidr_blocks = lookup(egress.value, "ipv6_cidr_blocks", null)
      prefix_list_ids  = lookup(egress.value, "prefix_list_ids", null)
      protocol         = lookup(egress.value, "protocol", null)
      security_groups  = lookup(egress.value, "security_groups", null)
      self             = lookup(egress.value, "self", null)
      to_port          = lookup(egress.value, "to_port", null)
    }
  }
  revoke_rules_on_delete = var.vpc_module_revoke_rules_on_delete
  tags                   = var.tags
}
