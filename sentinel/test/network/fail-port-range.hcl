mock "tfplan/v2" {
  module {
    source = "mock-tfplan-fail-port-range.sentinel"
  }
}

test {
  rules = {
    main = false
  }
}
