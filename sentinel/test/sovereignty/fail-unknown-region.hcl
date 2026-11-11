mock "tfplan/v2" {
  module {
    source = "mock-tfplan-fail-unknown-region.sentinel"
  }
}

test {
  rules = {
    main = false
    resources_in_approved_regions = false
  }
}
