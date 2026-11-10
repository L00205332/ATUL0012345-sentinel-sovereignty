mock "tfplan/v2" {
  module {
    source = "mock-tfplan-fail-inline-sg.sentinel"
  }
}

test {
  rules = {
    main = false
  }
}
