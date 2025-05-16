terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  required_version = ">= 1.0.0"

  backend "s3" {
    bucket  = "gamestoretfstate"
    key     = "env/dev/terraform.tfstate"
    region  = "eu-north-1"
    encrypt = true
  }
}

provider "aws" {
  region = var.aws_region
}
