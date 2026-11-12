mock "tfplan/v2" {
  module {
    source = "mock-tfplan-fail-provider-no-constraint.sentinel"
  }
}

mock "tfconfig/v2" {
  module {
    source = "mock-tfconfig-fail-provider-no-constraint.sentinel"
  }
}

test {
  rules = {
    main = false
    providers_from_approved_sources = true
    provider_versions_approved = false
  }
}
