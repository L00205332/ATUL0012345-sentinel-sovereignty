mock "tfplan/v2" {
  module {
    source = "mock-tfplan-fail-typosquat-provider.sentinel"
  }
}

mock "tfconfig/v2" {
  module {
    source = "mock-tfconfig-fail-typosquat-provider.sentinel"
  }
}

test {
  rules = {
    main = false
    providers_from_approved_sources = false
  }
}
