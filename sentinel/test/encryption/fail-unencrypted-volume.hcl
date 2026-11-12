mock "tfplan/v2" {
  module {
    source = "mock-tfplan-fail-unencrypted-volume.sentinel"
  }
}

mock "tfconfig/v2" {
  module {
    source = "mock-tfconfig-fail-unencrypted-volume.sentinel"
  }
}

test {
  rules = {
    main = false
    ebs_encrypted = false
    ebs_customer_managed_key = false
  }
}
