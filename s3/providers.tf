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
  region  = var.regionProject
  profile = var.awsProfile
}

variable "awsProfile" {
  description = "AWS Profile"
  type        = string
  default     = "crfjunior-outlook"
}

#variable "regionProject" {
#  description = "Define a região de execuçaõ do projeto"
#  default     = "us-east-1"
#}
