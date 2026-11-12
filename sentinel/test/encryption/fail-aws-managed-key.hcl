mock "tfplan/v2" {
  module {
    source = "mock-tfplan-fail-aws-managed-key.sentinel"
  }
}

mock "tfconfig/v2" {
  module {
    source = "mock-tfconfig-fail-aws-managed-key.sentinel"
  }
}

test {
  rules = {
    main = false
    ebs_encrypted = true
    ebs_customer_managed_key = false
  }
}
