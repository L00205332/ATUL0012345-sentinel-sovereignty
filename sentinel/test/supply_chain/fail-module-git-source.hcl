mock "tfplan/v2" {
  module {
    source = "mock-tfplan-fail-module-git-source.sentinel"
  }
}

mock "tfconfig/v2" {
  module {
    source = "mock-tfconfig-fail-module-git-source.sentinel"
  }
}

test {
  rules = {
    main = false
    modules_from_trusted_sources = false
    modules_pinned = true
  }
}
