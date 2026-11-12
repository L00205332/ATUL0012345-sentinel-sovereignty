mock "tfplan/v2" {
  module {
    source = "mock-tfplan-fail-no-metadata-options.sentinel"
  }
}

mock "tfconfig/v2" {
  module {
    source = "mock-tfconfig-fail-no-metadata-options.sentinel"
  }
}

test {
  rules = {
    main = false
    imdsv2_required = false
  }
}
