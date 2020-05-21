terraform {
  required_version = "~> 0.12.0"
  required_providers {
    aws = "~> 2.62"
  }
}

provider "aws" {
  alias   = "aws-west"
  region  = "us-west-1"
}

provider "aws" {
  alias   = "aws-eu"
  region  = "eu-central-1"
}
