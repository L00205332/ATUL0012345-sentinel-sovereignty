mock "tfplan/v2" {
  module {
    source = "mock-tfplan-fail-offregion-snapshot-copy.sentinel"
  }
}

test {
  rules = {
    main = false
    resources_in_approved_regions = false
    sensitive_data_resident = false
  }
}
