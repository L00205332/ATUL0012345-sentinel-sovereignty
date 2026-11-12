mock "tfplan/v2" {
  module {
    source = "mock-tfplan-pass-float-hop.sentinel"
  }
}

test {
  rules = {
    main = true
  }
}
