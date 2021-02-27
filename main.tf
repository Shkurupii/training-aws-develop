terraform {
  required_version = "0.14.5"
  # terraform init -backend-config=backend.hcl
  backend "remote" {}
}

provider "aws" {
}

variable "bucket_name" {
  type = string
  description = "Bucket Name"
}

resource "aws_s3_bucket" "test-bucket" {
  bucket = var.bucket_name
}