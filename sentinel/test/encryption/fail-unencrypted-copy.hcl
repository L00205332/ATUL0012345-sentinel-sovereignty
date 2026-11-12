mock "tfplan/v2" {
  module {
    source = "mock-tfplan-fail-unencrypted-copy.sentinel"
  }
}

mock "tfconfig/v2" {
  module {
    source = "mock-tfconfig-fail-unencrypted-copy.sentinel"
  }
}

test {
  rules = {
    main = false
    ebs_encrypted = false
  }
}
