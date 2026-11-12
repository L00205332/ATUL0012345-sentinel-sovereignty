mock "tfplan/v2" {
  module {
    source = "mock-tfplan-fail-float-hop-2.sentinel"
  }
}

test {
  rules = {
    main = false
    imdsv2_required = true
    imds_hop_limit_restricted = false
  }
}
