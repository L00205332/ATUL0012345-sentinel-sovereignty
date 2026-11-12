mock "tfplan/v2" {
  module {
    source = "mock-tfplan-pass-float-ports.sentinel"
  }
}

test {
  rules = {
    main = true
  }
}
