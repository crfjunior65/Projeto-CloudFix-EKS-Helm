terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0" #  5.94.1"
    }
  }

  #backend "s3" {
  #  bucket  = "cloudfix-bucket"
  #  key     = "terraform.tfstate"
  #  region  = "us-east-1"
  #  encrypt = true
  #  #dynamodb_table = "terraform-locks"
  #}
}

provider "aws" {
  region = var.region
}

variable "region" {
  type        = string
  description = "The AWS region to deploy to"
  default     = "us-east-1"
}
