module "this" {
  source = "git::https://github.com/plus3it/terraform-aws-tardigrade-iam-identity-provider.git?ref=3.0.0"

  iam_identity_provider = null
}
