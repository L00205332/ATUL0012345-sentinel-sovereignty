mock "tfplan/v2" {
  module {
    source = "mock-tfplan-fail-implicit-provider.sentinel"
  }
}

mock "tfconfig/v2" {
  module {
    source = "mock-tfconfig-fail-implicit-provider.sentinel"
  }
}

test {
  rules = {
    main = false
    providers_from_approved_sources = false
    provider_versions_approved = true
  }
}
