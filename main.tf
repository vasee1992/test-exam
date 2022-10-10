provider "aws" {
  region = local.region
}

locals {
  name                = "test-exam"
  region              = "eu-west-2"
  cidr                = "10.0.0.0/16"
  private_subnets     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets      = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
  ssl_certificate_arn = "arn:aws:acm:eu-west-1:235367859451:certificate/6c270328-2cd5-4b2d-8dfd-ae8d0004ad31"
  domain_name         = "hello_world.com"

  tags = {
    Managed = "Terraform"
  }
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "${local.name}-vpc"
  cidr = local.cidr

  azs             = ["${local.region}a", "${local.region}b", "${local.region}c"]
  private_subnets = local.private_subnets
  public_subnets  = local.public_subnets

  tags = local.tags
}

module "sg" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "allow-access"
  description = "Allow access 80 and 443 from internet"
  vpc_id      = module.vpc.vpc_id

  ingress_with_cidr_blocks = [
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      description = "http"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      description = "https"
      cidr_blocks = "0.0.0.0/0"
    }
  ]
}

module "elb" {
  source  = "terraform-aws-modules/elb/aws"
  version = "~> 3.0.1"

  name = "elb"

  subnets         = local.public_subnets
  security_groups = [module.sg.security_group_id]
  internal        = false

  listener = [
    {
      instance_port     = 80
      instance_protocol = "HTTP"
      lb_port           = 80
      lb_protocol       = "HTTP"
    },
    {
      instance_port      = 443
      instance_protocol  = "https"
      lb_port            = 443
      lb_protocol        = "https"
      ssl_certificate_id = local.ssl_certificate_arn
    },
  ]

  health_check = {
    target              = "HTTP:80/"
    interval            = 30
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
  }

  tags = local.tags
}

resource "aws_route53_zone" "primary" {
  name = local.domain_name
  tags = local.tags
}


resource "aws_route53_record" "www" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = "www.${local.domain_name}"
  type    = "CNAME"
  records = [module.elb.elb_dns_name]
}
