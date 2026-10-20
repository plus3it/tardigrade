module "this" {
  source = "git::https://github.com/plus3it/terraform-aws-tardigrade-cloudtrail.git?ref=6.3.0"

  cloudtrail_name   = null
  cloudtrail_bucket = null
}
