mock "tfplan/v2" {
  module {
    source = "mock-tfplan-fail-module-no-version.sentinel"
  }
}

mock "tfconfig/v2" {
  module {
    source = "mock-tfconfig-fail-module-no-version.sentinel"
  }
}

test {
  rules = {
    main = false
    modules_pinned = false
  }
}
