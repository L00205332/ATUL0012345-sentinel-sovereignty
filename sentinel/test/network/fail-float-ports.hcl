mock "tfplan/v2" {
  module {
    source = "mock-tfplan-fail-float-ports.sentinel"
  }
}

test {
  rules = {
    main = false
    no_public_ssh = false
    public_ingress_restricted = false
  }
}
