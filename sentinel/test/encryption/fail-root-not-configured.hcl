mock "tfplan/v2" {
  module {
    source = "mock-tfplan-fail-root-not-configured.sentinel"
  }
}

mock "tfconfig/v2" {
  module {
    source = "mock-tfconfig-fail-root-not-configured.sentinel"
  }
}

test {
  rules = {
    main = false
    ebs_encrypted = false
    ebs_customer_managed_key = false
  }
}
