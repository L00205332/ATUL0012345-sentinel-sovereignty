# One AWS provider, pinned to the primary (Irish) region.
#
# AWS provider v6 added a per-resource "region" argument, so the DR resources in
# backup.tf set region = var.dr_region instead of needing a second, aliased
# provider. This also puts the region of every resource directly into the plan,
# where sovereignty.sentinel can read it.

provider "aws" {
  region = var.primary_region

  # Applied to every taggable resource. Tags are what make data residency
  # auditable: owner, jurisdiction and how the resource was created.
  default_tags {
    tags = {
      Organisation = var.organisation
      Project      = var.project
      ManagedBy    = "Terraform"
      Jurisdiction = "EU-IE"
    }
  }
}
