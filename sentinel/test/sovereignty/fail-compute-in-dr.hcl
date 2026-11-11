mock "tfplan/v2" {
  module {
    source = "mock-tfplan-fail-compute-in-dr.sentinel"
  }
}

test {
  rules = {
    main = false
    resources_in_approved_regions = true
    dr_region_backup_only = false
  }
}
