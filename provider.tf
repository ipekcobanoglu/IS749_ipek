terraform {
  backend "s3" {
    key = "IS749-project.json"
  }
}

terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.51.0"
    }

     archive = {
      source  = "hashicorp/archive"
      version = "~> 2.4.2"
    }

    external = {
      source = "hashicorp/external"
      version = "2.3.3"
    }

    local = {
      source = "hashicorp/local"
      version = "2.5.1"
    }

    null = {
      source = "hashicorp/null"
      version = "3.2.2"
    }
  }
}

provider "aws" {
  region = var.region
}

data "aws_caller_identity" "current" {}