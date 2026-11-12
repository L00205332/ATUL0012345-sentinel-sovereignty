mock "tfplan/v2" {
  module {
    source = "mock-tfplan-fail-launch-template-unencrypted.sentinel"
  }
}

mock "tfconfig/v2" {
  module {
    source = "mock-tfconfig-fail-launch-template-unencrypted.sentinel"
  }
}

test {
  rules = {
    main = false
    ebs_encrypted = false
    ebs_customer_managed_key = false
  }
}
