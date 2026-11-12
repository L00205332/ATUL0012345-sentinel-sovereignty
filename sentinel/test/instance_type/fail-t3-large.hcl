mock "tfplan/v2" {
  module {
    source = "mock-tfplan-fail-t3-large.sentinel"
  }
}

mock "tfconfig/v2" {
  module {
    source = "mock-tfconfig-fail-t3-large.sentinel"
  }
}

test {
  rules = {
    main = false
    instance_types_approved = false
  }
}
