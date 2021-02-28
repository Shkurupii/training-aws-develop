data "aws_route53_zone" "public" {
  provider = aws.develop
  name = var.domain_name
  private_zone = false
}

module "acm" {
  source = "terraform-aws-modules/acm/aws"
  version = "2.12.0"
  create_certificate = true
  domain_name = var.domain_name
  zone_id = data.aws_route53_zone.public.zone_id
  subject_alternative_names = [
    "api.${var.domain_name}",
    "www.${var.domain_name}",
    "app.${var.domain_name}",
  ]
  tags = module.tags.all_tags
}
