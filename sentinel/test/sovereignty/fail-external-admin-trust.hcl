mock "tfplan/v2" {
  module {
    source = "mock-tfplan-fail-external-admin-trust.sentinel"
  }
}

test {
  rules = {
    main = false
    resources_in_approved_regions = true
    no_external_admin_trust = false
  }
}
