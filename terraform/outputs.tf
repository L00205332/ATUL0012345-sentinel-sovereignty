output "instance_id" {
  description = "EC2 instance ID (connect with: aws ssm start-session --target <id>)."
  value       = aws_instance.app.id
}

output "data_volume_id" {
  description = "Sensitive data volume ID."
  value       = aws_ebs_volume.data.id
}

output "primary_snapshot_id" {
  description = "Backup snapshot in the primary region."
  value       = aws_ebs_snapshot.data.id
}

output "dr_snapshot_id" {
  description = "Backup copy in the DR region."
  value       = aws_ebs_snapshot_copy.data_dr.id
}

output "regions" {
  description = "Regions used by this stack."
  value = {
    primary = var.primary_region
    dr      = var.dr_region
  }
}
