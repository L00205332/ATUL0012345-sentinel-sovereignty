# Supply chain control point 1: everything Terraform downloads is declared here.
#   - required_version   : which Terraform core may run this code
#   - required_providers : provider SOURCE (who publishes it) + VERSION constraint
# The exact provider build and its checksums are then pinned in .terraform.lock.hcl.
# Sentinel (supply_chain.sentinel) re-checks these values in every run, so they
# cannot be silently loosened in a pull request.

terraform {
  required_version = ">= 1.17.0, < 2.0.0"

  # HCP Terraform runs the plan, the Sentinel policy check and the apply.
  cloud {
    organization = "L00205332"

    workspaces {
      name = "atul0012345-sovereignty"
    }
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws" # official HashiCorp provider from registry.terraform.io
      version = "~> 6.0"        # any 6.x, never 7.x (breaking changes need review)
    }
  }
}
