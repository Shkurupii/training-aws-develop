resource "aws_default_vpc" "default" {}

data "aws_subnet_ids" "default_subnets" {
  vpc_id = aws_default_vpc.default.id
}

data "aws_security_group" "default" {
  vpc_id = aws_default_vpc.default.id
  name = "default"
}

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}
