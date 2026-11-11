mock "tfplan/v2" {
  module {
    source = "mock-tfplan-fail-dlm-cross-region.sentinel"
  }
}

test {
  rules = {
    main = false
    resources_in_approved_regions = true
    replication_targets_approved = false
  }
}
