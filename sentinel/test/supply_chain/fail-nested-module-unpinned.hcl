mock "tfplan/v2" {
  module {
    source = "mock-tfplan-fail-nested-module-unpinned.sentinel"
  }
}

mock "tfconfig/v2" {
  module {
    source = "mock-tfconfig-fail-nested-module-unpinned.sentinel"
  }
}

test {
  rules = {
    main = false
    modules_pinned = false
  }
}
