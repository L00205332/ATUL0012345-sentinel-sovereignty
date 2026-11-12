mock "tfplan/v2" {
  module {
    source = "mock-tfplan-fail-imdsv1-optional.sentinel"
  }
}

mock "tfconfig/v2" {
  module {
    source = "mock-tfconfig-fail-imdsv1-optional.sentinel"
  }
}

test {
  rules = {
    main = false
    imdsv2_required = false
    imds_hop_limit_restricted = true
  }
}
