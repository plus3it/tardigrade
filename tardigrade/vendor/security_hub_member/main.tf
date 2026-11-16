module "this" {
  source = "git::https://github.com/plus3it/terraform-aws-tardigrade-security-hub.git//modules/cross-account-member?ref=5.0.0"

  providers = {
    aws               = aws
    aws.administrator = aws
  }
}
