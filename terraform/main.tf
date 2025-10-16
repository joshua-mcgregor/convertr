terraform {
  required_version = ">= 1.5.0"

  backend "s3" {
    bucket = "convertr-terraform-statefiles"
    key    = "convertr.tfstate"
    region = "eu-west-2"
  }
}

provider "aws" {
  region = "eu-west-2"

  default_tags {
    tags = {
      Project = "Convertr"
    }
  }
}

provider "aws" {
  region = "us-east-1"
  alias  = "us_east_1"
}