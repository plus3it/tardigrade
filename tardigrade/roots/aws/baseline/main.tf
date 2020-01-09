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
  create_vpc_endpoints     = false
  create_inspector         = true
  create_metric_filter     = true
  create_metric_alarm      = true

  excluded_config_rules = {
    "handsoff"   = []
    "aws"        = []
    "aws-us-gov" = []
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
    name        = "support-user",
    policy_arns = [data.aws_iam_policy.this.arn]
  }]
}

# get ARN for AWSSupportAccess AWS Managed policy
data "aws_iam_policy" "this" {
  arn = "arn:${data.aws_partition.this.partition}:iam::${data.aws_partition.this.partition}:policy/AWSSupportAccess"
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
  source = "git::https://github.com/plus3it/terraform-aws-tardigrade-cloudtrail.git?ref=2.2.3"

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

##### METRIC FILTERS #####
locals {
  # due to limitations in prowlers checking of filter_patterns within metric filters, very long strings
  # are being used as opposed to heredocs
  metric_filters = [
    {
      name           = "terraform-cis-unauthorized-operations"
      filter_pattern = "{ ($.errorCode = \"*UnauthorizedOperation\") || ($.errorCode = \"AccessDenied*\") }"
      log_group_name = module.cloudtrail.log_group.name
      metric_transformation = {
        name          = "Unauthorized Operations"
        namespace     = "CISBenchmark"
        value         = 1
        default_value = 0
      }
    },
    {
      name           = "terraform-cis-console-login-without-mfa"
      filter_pattern = "{ ($.eventName = \"ConsoleLogin\") && ($.additionalEventData.MFAUsed != \"Yes\") }"
      log_group_name = module.cloudtrail.log_group.name
      metric_transformation = {
        name          = "Console Logins w/o MFA"
        namespace     = "CISBenchmark"
        value         = 1
        default_value = 0
      }
    },
    {
      name           = "terraform-cis-root-account-usage"
      filter_pattern = "{ $.userIdentity.type = \"Root\" && $.userIdentity.invokedBy NOT EXISTS && $.eventType != \"AwsServiceEvent\" }"
      log_group_name = module.cloudtrail.log_group.name
      metric_transformation = {
        name          = "Root Account Usage"
        namespace     = "CISBenchmark"
        value         = 1
        default_value = 0
      }
    },
    {
      name           = "terraform-cis-iam-policy-changes"
      filter_pattern = "{($.eventName=DeleteGroupPolicy)||($.eventName=DeleteRolePolicy)|| ($.eventName=DeleteUserPolicy) ||($.eventName=PutGroupPolicy) || ($.eventName=PutRolePolicy)|| ($.eventName=PutUserPolicy) ||($.eventName=CreatePolicy) || ($.eventName=DeletePolicy) || ($.eventName=CreatePolicyVersion) ||($.eventName=DeletePolicyVersion) || ($.eventName=AttachRolePolicy) || ($.eventName=DetachRolePolicy) ||($.eventName=AttachUserPolicy) || ($.eventName=DetachUserPolicy) || ($.eventName=AttachGroupPolicy) ||($.eventName=DetachGroupPolicy)}"
      log_group_name = module.cloudtrail.log_group.name
      metric_transformation = {
        name          = "IAM Policy Changes"
        namespace     = "CISBenchmark"
        value         = 1
        default_value = 0
      }
    },
    {
      name           = "terraform-cis-cloudtrail-configuration-changes"
      filter_pattern = "{($.eventName = CreateTrail) || ($.eventName = UpdateTrail) || ($.eventName = DeleteTrail) ||($.eventName = StartLogging) || ($.eventName = StopLogging)}"

      log_group_name = module.cloudtrail.log_group.name
      metric_transformation = {
        name          = "CloudTrail Configuration Changes"
        namespace     = "CISBenchmark"
        value         = 1
        default_value = 0
      }
    },
    {
      name           = "terraform-cis-console-authentication-failures"
      filter_pattern = "{ ($.eventName = ConsoleLogin) && ($.errorMessage = \"Failed authentication\") }"
      log_group_name = module.cloudtrail.log_group.name
      metric_transformation = {
        name          = "Console Authentication Failures"
        namespace     = "CISBenchmark"
        value         = 1
        default_value = 0
      }
    },
    {
      name           = "terraform-cis-removing-cmks"
      filter_pattern = "{($.eventSource = kms.amazonaws.com) && (($.eventName=DisableKey)||($.eventName=ScheduleKeyDeletion)) }"
      log_group_name = module.cloudtrail.log_group.name
      metric_transformation = {
        name          = "Disabling/Scheduled Deletion of CMKs"
        namespace     = "CISBenchmark"
        value         = 1
        default_value = 0
      }
    },
    {
      name           = "terraform-cis-s3-bucket-policy-changes"
      filter_pattern = "{ ($.eventSource = s3.amazonaws.com) && (($.eventName = PutBucketAcl) || ($.eventName = PutBucketPolicy) ||($.eventName = PutBucketCors) || ($.eventName = PutBucketLifecycle) || ($.eventName = PutBucketReplication) ||($.eventName = DeleteBucketPolicy) || ($.eventName = DeleteBucketCors) || ($.eventName = DeleteBucketLifecycle) ||($.eventName = DeleteBucketReplication)) }"
      log_group_name = module.cloudtrail.log_group.name
      metric_transformation = {
        name          = "S3 Bucket Policy Changes"
        namespace     = "CISBenchmark"
        value         = 1
        default_value = 0
      }
    },
    {
      name           = "terraform-cis-aws-config-configuration-changes"
      filter_pattern = "{ ($.eventSource = config.amazonaws.com) && (($.eventName=StopConfigurationRecorder) ||($.eventName=DeleteDeliveryChannel) || ($.eventName=PutDeliveryChannel) ||($.eventName=PutConfigurationRecorder)) }"
      log_group_name = module.cloudtrail.log_group.name
      metric_transformation = {
        name          = "AWS Config Configuration Changes"
        namespace     = "CISBenchmark"
        value         = 1
        default_value = 0
      }
    },
    {
      name           = "terraform-cis-security-group-changes"
      filter_pattern = "{ ($.eventName = AuthorizeSecurityGroupIngress) || ($.eventName = AuthorizeSecurityGroupEgress) ||($.eventName = RevokeSecurityGroupIngress) || ($.eventName = RevokeSecurityGroupEgress) ||($.eventName = CreateSecurityGroup) || ($.eventName = DeleteSecurityGroup) }"
      log_group_name = module.cloudtrail.log_group.name
      metric_transformation = {
        name          = "Security Group Changes"
        namespace     = "CISBenchmark"
        value         = 1
        default_value = 0
      }
    },
    {
      name           = "terraform-cis-nacl-changes"
      filter_pattern = "{ ($.eventName = CreateNetworkAcl) || ($.eventName = CreateNetworkAclEntry) ||($.eventName = DeleteNetworkAcl) || ($.eventName = DeleteNetworkAclEntry) ||($.eventName = ReplaceNetworkAclEntry) || ($.eventName = ReplaceNetworkAclAssociation) }"
      log_group_name = module.cloudtrail.log_group.name
      metric_transformation = {
        name          = "NACL Changes"
        namespace     = "CISBenchmark"
        value         = 1
        default_value = 0
      }
    },
    {
      name           = "terraform-cis-network-gateway-changes"
      filter_pattern = "{ ($.eventName = CreateCustomerGateway) || ($.eventName = DeleteCustomerGateway) ||($.eventName = AttachInternetGateway) ||  ($.eventName = CreateInternetGateway) ||($.eventName = DeleteInternetGateway) || ($.eventName = DetachInternetGateway) }"
      log_group_name = module.cloudtrail.log_group.name
      metric_transformation = {
        name          = "Network Gateway Changes"
        namespace     = "CISBenchmark"
        value         = 1
        default_value = 0
      }
    },
    {
      name           = "terraform-cis-route-table-changes"
      filter_pattern = "{ ($.eventName = CreateRoute) || ($.eventName = CreateRouteTable) || ($.eventName = ReplaceRoute) ||($.eventName = ReplaceRouteTableAssociation) || ($.eventName = DeleteRouteTable) ||($.eventName = DeleteRoute) || ($.eventName = DisassociateRouteTable) }"

      log_group_name = module.cloudtrail.log_group.name
      metric_transformation = {
        name          = "Route Table Changes"
        namespace     = "CISBenchmark"
        value         = 1
        default_value = 0
      }
    },
    {
      name           = "terraform-cis-vpc-changes"
      filter_pattern = "{ ($.eventName = CreateVpc) || ($.eventName = DeleteVpc) || ($.eventName = ModifyVpcAttribute) ||($.eventName = AcceptVpcPeeringConnection) || ($.eventName = CreateVpcPeeringConnection) ||($.eventName = DeleteVpcPeeringConnection) || ($.eventName = RejectVpcPeeringConnection) ||($.eventName = AttachClassicLinkVpc) || ($.eventName = DetachClassicLinkVpc) ||($.eventName = DisableVpcClassicLink) || ($.eventName = EnableVpcClassicLink) }"
      log_group_name = module.cloudtrail.log_group.name
      metric_transformation = {
        name          = "VPC Changes"
        namespace     = "CISBenchmark"
        value         = 1
        default_value = 0
      }
    }
  ]
}

module "metric_filters" {
  source = "git::https://github.com/plus3it/terraform-aws-tardigrade-cloudwatch-log-metric-filter.git?ref=0.0.0"

  providers = {
    aws = aws
  }

  # Member
  create_metric_filter = local.create_metric_filter
  metric_filters       = local.metric_filters
}

##### METRIC ALARMS #####
locals {
  alarms = [
    for metric in module.metric_filters.metric_filters :
    {
      alarm_name          = metric.name,
      comparison_operator = "GreaterThanOrEqualToThreshold",
      evaluation_periods  = "1",
      metric_name         = metric.metric_transformation[0].name,
      namespace           = metric.metric_transformation[0].namespace,
      period              = "300",
      statistic           = "Sum",
      threshold           = "1"
    }
  ]
}

module "metric_alarms" {
  source = "git::https://github.com/plus3it/terraform-aws-tardigrade-cloudwatch-metric-alarm.git?ref=0.0.0"

  providers = {
    aws = aws
  }

  create_metric_alarm = local.create_metric_alarm
  metric_alarms       = local.alarms
}

##### DATA SOURCES #####
data "aws_caller_identity" "this" {}

data "aws_partition" "this" {}

data "aws_availability_zones" "all" {}

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
