mock "tfplan/v2" {
  module {
    source = "mock-tfplan-fail-all-protocols.sentinel"
  }
}

test {
  rules = {
    main = false
  }
}
