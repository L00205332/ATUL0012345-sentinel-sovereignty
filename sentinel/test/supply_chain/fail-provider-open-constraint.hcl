mock "tfplan/v2" {
  module {
    source = "mock-tfplan-fail-provider-open-constraint.sentinel"
  }
}

mock "tfconfig/v2" {
  module {
    source = "mock-tfconfig-fail-provider-open-constraint.sentinel"
  }
}

test {
  rules = {
    main = false
    provider_versions_approved = false
  }
}
