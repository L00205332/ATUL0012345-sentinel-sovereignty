variable "organisation" {
  description = "Organisation identifier, used in names and tags."
  type        = string
  default     = "ATUL0012345"
}

variable "project" {
  description = "Project name, used in names and tags."
  type        = string
  default     = "sentinel-sovereignty"
}

variable "primary_region" {
  description = "Primary region for compute, network and data (Ireland)."
  type        = string
  default     = "eu-west-1"
}

variable "dr_region" {
  description = "Disaster recovery region for backup copies only. Must stay inside the EU."
  type        = string
  default     = "eu-central-1"
}

variable "vpc_cidr" {
  description = "CIDR block of the VPC."
  type        = string
  default     = "10.20.0.0/16"
}

variable "instance_type" {
  description = "EC2 instance type. Must be on the approved list in instance_type.sentinel."
  type        = string
  default     = "t3.micro"
}

variable "data_volume_size" {
  description = "Size in GiB of the sensitive data volume."
  type        = number
  default     = 1
}
