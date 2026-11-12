mock "tfplan/v2" {
  module {
    source = "mock-tfplan-fail-hop-limit-2.sentinel"
  }
}

mock "tfconfig/v2" {
  module {
    source = "mock-tfconfig-fail-hop-limit-2.sentinel"
  }
}

test {
  rules = {
    main = false
    imdsv2_required = true
    imds_hop_limit_restricted = false
  }
}
