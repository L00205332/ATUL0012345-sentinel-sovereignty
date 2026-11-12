mock "tfplan/v2" {
  module {
    source = "mock-tfplan-fail-unknown-type.sentinel"
  }
}

mock "tfconfig/v2" {
  module {
    source = "mock-tfconfig-fail-unknown-type.sentinel"
  }
}

test {
  rules = {
    main = false
    instance_types_approved = false
  }
}
