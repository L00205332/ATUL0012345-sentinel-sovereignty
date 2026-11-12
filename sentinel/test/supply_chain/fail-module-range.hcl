mock "tfplan/v2" {
  module {
    source = "mock-tfplan-fail-module-range.sentinel"
  }
}

mock "tfconfig/v2" {
  module {
    source = "mock-tfconfig-fail-module-range.sentinel"
  }
}

test {
  rules = {
    main = false
    modules_from_trusted_sources = true
    modules_pinned = false
  }
}
