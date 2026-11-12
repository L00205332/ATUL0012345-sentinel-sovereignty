mock "tfplan/v2" {
  module {
    source = "mock-tfplan-fail-module-untrusted-namespace.sentinel"
  }
}

mock "tfconfig/v2" {
  module {
    source = "mock-tfconfig-fail-module-untrusted-namespace.sentinel"
  }
}

test {
  rules = {
    main = false
    modules_from_trusted_sources = false
  }
}
