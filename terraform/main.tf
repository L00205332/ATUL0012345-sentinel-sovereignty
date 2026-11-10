locals {
  name = lower("${var.organisation}-${var.project}")
}

# Latest Amazon Linux 2023 AMI, from AWS's public SSM parameter (published by
# AWS itself, so the image source is trusted and never hard-coded).
data "aws_ssm_parameter" "al2023_ami" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

# Customer-managed KMS key in the primary region.
# Sovereignty: the organisation controls the key, its policy and its lifetime.
# Scheduling the key for deletion makes every copy of the data unreadable
# (crypto-shredding).
resource "aws_kms_key" "primary" {
  description             = "${local.name} EBS encryption key (${var.primary_region})"
  enable_key_rotation     = true
  deletion_window_in_days = 7
}

resource "aws_kms_alias" "primary" {
  name          = "alias/${local.name}-ebs"
  target_key_id = aws_kms_key.primary.key_id
}

# --- Administrative access: SSM Session Manager instead of SSH -------------
# Every session is authenticated with IAM and logged by AWS. No key pairs, no
# open ports.

resource "aws_iam_role" "ssm" {
  name = "${local.name}-ssm"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.ssm.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ssm" {
  name = "${local.name}-ssm"
  role = aws_iam_role.ssm.name
}

# --- EC2 instance ------------------------------------------------------------

resource "aws_instance" "app" {
  ami                    = data.aws_ssm_parameter.al2023_ami.value
  instance_type          = var.instance_type # instance_type.sentinel
  subnet_id              = module.vpc.public_subnets[0]
  vpc_security_group_ids = [aws_security_group.app.id] # network.sentinel
  iam_instance_profile   = aws_iam_instance_profile.ssm.name

  # IMDSv2 only (metadata.sentinel). Session tokens are required and the hop
  # limit of 1 stops containers or proxies on the host from reaching the
  # metadata service. This blocks the SSRF credential-theft path.
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  # Encrypted root disk with the customer-managed key (encryption.sentinel).
  root_block_device {
    volume_type = "gp3"
    volume_size = 8
    encrypted   = true
    kms_key_id  = aws_kms_key.primary.arn
  }

  tags = {
    Name = "${local.name}-app"
  }
}
