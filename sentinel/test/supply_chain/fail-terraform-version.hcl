mock "tfplan/v2" {
  module {
    source = "mock-tfplan-fail-terraform-version.sentinel"
  }
}

mock "tfconfig/v2" {
  module {
    source = "mock-tfconfig-fail-terraform-version.sentinel"
  }
}

test {
  rules = {
    main = false
    terraform_version_approved = false
  }
}
