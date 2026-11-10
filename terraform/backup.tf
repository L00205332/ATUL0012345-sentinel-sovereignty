# Backup and disaster recovery.
#
#   1. Snapshot of the sensitive volume in the primary region (eu-west-1).
#   2. Encrypted copy of that snapshot in the DR region (eu-central-1).
#
# Frankfurt is approved because it keeps the data inside EU jurisdiction.
# Changing var.dr_region to a non-EU region (e.g. us-east-1) is the
# sovereignty test case: sovereignty.sentinel must block that plan.

resource "aws_ebs_snapshot" "data" {
  volume_id   = aws_ebs_volume.data.id
  description = "${local.name} sensitive data backup (${var.primary_region})"

  tags = {
    Name                = "${local.name}-data-backup"
    data_classification = "sensitive"
  }
}

# DR copies are encrypted with a key that lives in the DR region, so the copy
# never depends on a key outside the jurisdiction it is stored in.
resource "aws_kms_key" "dr" {
  region                  = var.dr_region
  description             = "${local.name} DR snapshot key (${var.dr_region})"
  enable_key_rotation     = true
  deletion_window_in_days = 7
}

resource "aws_kms_alias" "dr" {
  region        = var.dr_region
  name          = "alias/${local.name}-dr"
  target_key_id = aws_kms_key.dr.key_id
}

resource "aws_ebs_snapshot_copy" "data_dr" {
  region             = var.dr_region
  source_region      = var.primary_region
  source_snapshot_id = aws_ebs_snapshot.data.id
  encrypted          = true
  kms_key_id         = aws_kms_key.dr.arn
  description        = "${local.name} sensitive data DR copy (${var.dr_region})"

  tags = {
    Name                = "${local.name}-data-dr"
    data_classification = "sensitive"
  }
}
