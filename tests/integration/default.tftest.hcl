# Integration tests — requires real Power Platform credentials via OIDC.
#
# Prerequisites (set as environment variables before running):
#   ARM_USE_OIDC=true
#   POWER_PLATFORM_TENANT_ID=<your-tenant-id>
#   POWER_PLATFORM_CLIENT_ID=<your-client-id>
#
# These tests create real resources against a Power Platform tenant.
# Resources are automatically destroyed after test completion by the
# Terraform test framework. Do NOT run locally without valid credentials.
# Intended for CI use only.
#
# Each run block uses state_key to isolate state and avoid force-replace
# cascades when variable changes span multiple scenarios.

provider "powerplatform" {}

run "creates_basic_environment" {
  command   = apply
  state_key = "basic"

  variables {
    environment = {
      display_name = "tftest-basic-env"
      location     = "unitedstates"
    }
    dataverse = {
      currency_code     = "USD"
      security_group_id = "00000000-0000-0000-0000-000000000000"
    }
    managed_environment_enabled = false
  }

  assert {
    condition     = output.environment_display_name == "tftest-basic-env"
    error_message = "Output 'environment_display_name' should match the input display_name."
  }

  assert {
    condition     = output.environment_id != ""
    error_message = "Output 'environment_id' should be a non-empty string after apply."
  }

  assert {
    condition     = output.environment_url != null
    error_message = "Output 'environment_url' should not be null — all environments now have Dataverse."
  }

  assert {
    condition     = output.managed_environment_id == null
    error_message = "Output 'managed_environment_id' should be null when managed_environment_enabled = false."
  }
}

run "creates_environment_with_custom_dataverse" {
  command   = apply
  state_key = "custom-dataverse"

  variables {
    environment = {
      display_name     = "tftest-custom-dv-env"
      location         = "unitedstates"
      environment_type = "Sandbox"
    }
    dataverse = {
      currency_code     = "EUR"
      security_group_id = "00000000-0000-0000-0000-000000000000"
      language_code     = 1033
    }
    managed_environment_enabled = false
  }

  assert {
    condition     = output.environment_display_name == "tftest-custom-dv-env"
    error_message = "Output 'environment_display_name' should match the input display_name."
  }

  assert {
    condition     = output.dataverse_organization_id != null
    error_message = "Output 'dataverse_organization_id' should not be null when Dataverse is configured."
  }

  assert {
    condition     = output.environment_url != null
    error_message = "Output 'environment_url' should not be null when Dataverse is configured."
  }
}

run "creates_managed_environment" {
  command   = apply
  state_key = "managed"

  variables {
    environment = {
      display_name = "tftest-managed-env"
      location     = "unitedstates"
    }
    dataverse = {
      currency_code     = "USD"
      security_group_id = "00000000-0000-0000-0000-000000000000"
    }
    managed_environment = {
      solution_checker_rule_overrides = []
    }
    managed_environment_enabled = true
  }

  assert {
    condition     = output.environment_display_name == "tftest-managed-env"
    error_message = "Output 'environment_display_name' should match the input display_name."
  }

  assert {
    condition     = output.managed_environment_id != null
    error_message = "Output 'managed_environment_id' should be non-null when managed_environment_enabled = true."
  }

  assert {
    condition     = output.environment_url != null
    error_message = "Output 'environment_url' should not be null — all environments now have Dataverse."
  }
}
run "creates_managed_environment_with_firewall" {
  command   = apply
  state_key = "managed"

  variables {
    environment = {
      display_name = "tftest-managed-env"
      location     = "unitedstates"
    }
    dataverse = {
      currency_code     = "USD"
      security_group_id = "00000000-0000-0000-0000-000000000000"
    }
    managed_environment_enabled = true
    security_settings = {
      enable_ip_based_firewall_rule = true
      allowed_ip_range_for_firewall = ["10.0.0.0/24"]
    }
  }

  assert {
    condition     = output.environment_id != ""
    error_message = "Output 'environment_id' should be a non-empty string after apply."
  }

  assert {
    condition     = output.managed_environment_id != null
    error_message = "Output 'managed_environment_id' should be non-null when managed_environment_enabled = true and firewall settings are provided."
  }
}



run "creates_environment_with_application_admin" {
  command   = apply
  state_key = "application-admin"

  variables {
    environment = {
      display_name = "tftest-app-admin-env"
      location     = "unitedstates"
    }
    dataverse = {
      currency_code     = "USD"
      security_group_id = "00000000-0000-0000-0000-000000000000"
    }
    managed_environment_enabled = true
    application_admin_id        = "ef1fe61c-6544-488a-b99b-784922c9198a"
  }

  assert {
    condition     = output.environment_id != ""
    error_message = "Output 'environment_id' should be a non-empty string after apply."
  }

  assert {
    condition     = output.managed_environment_id != null
    error_message = "Output 'managed_environment_id' should be non-null when managed_environment_enabled = true."
  }

  assert {
    condition     = output.environment_display_name == "tftest-app-admin-env"
    error_message = "Output 'environment_display_name' should match the input display_name."
  }
}




