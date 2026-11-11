# Real plan data downloaded from HCP run run-Xz7zmhMJKXVNHwa3
# ("First compliant run: baseline stack with network policy").
mock "tfplan/v2" {
  module {
    source = "../../mocks/compliant-baseline/mock-tfplan-v2.sentinel"
  }
}

test {
  rules = {
    main = true
  }
}
