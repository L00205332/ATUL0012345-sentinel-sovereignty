mock "tfplan/v2" {
  module {
    source = "mock-tfplan-pass.sentinel"
  }
}

mock "tfconfig/v2" {
  module {
    source = "mock-tfconfig-pass.sentinel"
  }
}

test {
  rules = {
    main = true
  }
}
