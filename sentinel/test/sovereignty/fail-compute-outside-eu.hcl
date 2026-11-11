mock "tfplan/v2" {
  module {
    source = "mock-tfplan-fail-compute-outside-eu.sentinel"
  }
}

test {
  rules = {
    main = false
    resources_in_approved_regions = false
  }
}
