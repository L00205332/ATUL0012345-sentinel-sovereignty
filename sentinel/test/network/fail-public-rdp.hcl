mock "tfplan/v2" {
  module {
    source = "mock-tfplan-fail-public-rdp.sentinel"
  }
}

test {
  rules = {
    main                      = false
    no_public_ssh             = true
    public_ingress_restricted = false
  }
}
