# Real plan + config from the blocked PR #9 run (run-kwQg5XK3EGXKwPTs). That
# plan breaks sovereignty rules, but its providers, modules and Terraform
# version are all approved, so supply_chain must pass on it.
# (Not named pass-real-*: the bundle expects pass-real-* to pass EVERY policy.)
mock "tfplan/v2" {
  module {
    source = "../../mocks/offregion-snapshot/mock-tfplan-v2.sentinel"
  }
}

mock "tfconfig/v2" {
  module {
    source = "../../mocks/offregion-snapshot/mock-tfconfig-v2.sentinel"
  }
}

test {
  rules = {
    main = true
  }
}
