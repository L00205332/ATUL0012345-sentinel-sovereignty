mock "tfplan/v2" {
  module {
    source = "mock-tfplan-fail-ipv6.sentinel"
  }
}

test {
  rules = {
    main = false
  }
}
