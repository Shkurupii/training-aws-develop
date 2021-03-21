terraform {
  required_version = "0.14.5"
  # terraform init -backend-config=backend.hcl
  backend "remote" {}
}

provider "aws" {
  assume_role {
    role_arn = "arn:aws:iam::${var.develop_account_id}:role/OrganizationAccountAccessRole"
  }
}

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

variable "develop_account_id" {
  type = string
  description = "Account ID"
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

resource "aws_s3_bucket" "dev-bucket" {
  force_destroy = true
  bucket_prefix = "${var.workspace}-bucket-"
  tags = module.tags.all_tags
}
