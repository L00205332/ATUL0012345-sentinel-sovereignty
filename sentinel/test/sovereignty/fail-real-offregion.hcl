# Real plan data downloaded from HCP run run-kwQg5XK3EGXKwPTs: the speculative
# plan for PR #9 "TEST - non-compliant: DR snapshot copy to us-east-1".
# AWS account ID and public IP redacted (policy does not use them).
mock "tfplan/v2" {
  module {
    source = "../../mocks/offregion-snapshot/mock-tfplan-v2.sentinel"
  }
}

test {
  rules = {
    main                          = false
    resources_in_approved_regions = false
    dr_region_backup_only         = true
    sensitive_data_resident       = false
    replication_targets_approved  = true
    no_external_admin_trust       = true
  }
}
