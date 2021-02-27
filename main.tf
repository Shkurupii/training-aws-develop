terraform {
  required_version = "0.14.5"
  # terraform init -backend-config=backend.hcl
  backend "remote" {}
}

provider "aws" {
  alias = "develop"
  assume_role {
    role_arn = var.assume_role_arn
  }
}

variable "assume_role_arn" {
  type = string
  description = "Assume role ARN"
}

variable "bucket_name" {
  type = string
  description = "Bucket Name"
}

variable "workspace" {
  type = string
  description = "Terraform workspace"
}

variable "environment" {
  type = string
  description = "Environment name"
}

variable "username" {
  type = string
  description = "User name"
}

variable "domain_name" {
  type = string
  description = "Domain Name"
}

resource "aws_s3_bucket" "test-bucket" {
  provider = aws.develop
  force_destroy = true
  bucket = var.bucket_name
}

resource "aws_s3_bucket" "dev-bucket" {
  provider = aws.develop
  force_destroy = true
  bucket_prefix = "${var.workspace}-bucket-"
  tags = module.tags.all_tags
}
