mock "tfplan/v2" {
  module {
    source = "mock-tfplan-fail-launch-template-imdsv1.sentinel"
  }
}

mock "tfconfig/v2" {
  module {
    source = "mock-tfconfig-fail-launch-template-imdsv1.sentinel"
  }
}

test {
  rules = {
    main = false
    imdsv2_required = false
  }
}
