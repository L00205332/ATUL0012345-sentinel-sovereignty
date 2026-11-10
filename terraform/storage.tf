# Sensitive data volume.
# The data_classification tag marks the resource for the data residency rules in
# sovereignty.sentinel: sensitive data and every copy of it must stay in an
# approved EU region, and must be encrypted with a customer-managed key.

resource "aws_ebs_volume" "data" {
  availability_zone = aws_instance.app.availability_zone
  size              = var.data_volume_size
  type              = "gp3"
  encrypted         = true
  kms_key_id        = aws_kms_key.primary.arn

  tags = {
    Name                = "${local.name}-data"
    data_classification = "sensitive"
  }
}

resource "aws_volume_attachment" "data" {
  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.data.id
  instance_id = aws_instance.app.id
}
