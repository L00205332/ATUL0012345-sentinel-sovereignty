mock "tfplan/v2" {
  module {
    source = "mock-tfplan-fail-public-trust.sentinel"
  }
}

test {
  rules = {
    main = false
    no_external_admin_trust = false
  }
}
