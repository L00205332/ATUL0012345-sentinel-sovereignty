# The single HCP Terraform policy set for ATUL0012345 (Free tier: 1 policy set).
# HCP reads this file from the repo's sentinel/ folder on every run. Each policy
# gets its own enforcement level:
#   advisory        - failure is reported, run continues
#   soft-mandatory  - failure blocks the run unless an authorised user overrides it
#   hard-mandatory  - failure blocks the run, no override possible
# Policies are added here as they are built.

policy "sovereignty" {
  source            = "./sovereignty.sentinel"
  enforcement_level = "hard-mandatory"
}

policy "network" {
  source            = "./network.sentinel"
  enforcement_level = "hard-mandatory"
}

policy "encryption" {
  source            = "./encryption.sentinel"
  enforcement_level = "hard-mandatory"
}

policy "metadata" {
  source            = "./metadata.sentinel"
  enforcement_level = "hard-mandatory"
}

policy "supply_chain" {
  source            = "./supply_chain.sentinel"
  enforcement_level = "hard-mandatory"
}

# Standards/cost control: warns, does not block. Deployed as its own advisory
# policy, outside the hard-mandatory bundle.
policy "instance_type" {
  source            = "./instance_type.sentinel"
  enforcement_level = "advisory"
}
