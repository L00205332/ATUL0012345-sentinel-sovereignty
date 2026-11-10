mock "tfplan/v2" {
  module {
    source = "mock-tfplan-fail-legacy-rule.sentinel"
  }
}

test {
  rules = {
    main = false
  }
}
