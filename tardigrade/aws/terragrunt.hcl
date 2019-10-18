remote_state {
  backend = "s3"

  config = {
    profile        = "tardigrade"
    region         = "us-east-1"
    bucket         = "tardigrade-tfstate"
    key            = "tfstate/${path_relative_to_include()}/terraform.tfstate"
    encrypt        = true
    dynamodb_table = "tardigrade-tfstate-lock"
  }
}
