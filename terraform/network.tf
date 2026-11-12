# VPC from the public Terraform Registry.
# Supply chain control point 2: a third-party module is only allowed from an
# approved namespace and with an EXACT version (no ranges), so the code that
# runs is the code that was reviewed. Checked by supply_chain.sentinel.
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 6.0"

  name = "${local.name}-vpc"
  cidr = var.vpc_cidr

  # One AZ and one public subnet keep the cost near zero. The instance gets a
  # public IP only for outbound HTTPS to SSM. No inbound rule exists (see below).
  azs                     = ["${var.primary_region}a"]
  public_subnets          = [cidrsubnet(var.vpc_cidr, 8, 1)]
  map_public_ip_on_launch = true

  enable_nat_gateway = false
  enable_vpn_gateway = false

  # Lock down the VPC's default security group: no ingress, no egress.
  manage_default_security_group  = true
  default_security_group_ingress = []
  default_security_group_egress  = []
}

# Security group for the instance. Administrative access uses SSM Session
# Manager, so there is NO inbound rule at all: no SSH, no RDP.
resource "aws_security_group" "app" {
  name        = "${local.name}-app"
  description = "App instance: no inbound access, outbound HTTPS only"
  vpc_id      = module.vpc.vpc_id
}

# Outbound HTTPS only: enough for SSM, OS package repositories and AWS APIs.
resource "aws_vpc_security_group_egress_rule" "app_https_out" {
  security_group_id = aws_security_group.app.id
  description       = "HTTPS to AWS endpoints (SSM) and package repositories"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
}
