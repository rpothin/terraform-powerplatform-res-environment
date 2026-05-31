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

variables {
  environment = {
    display_name = "tftest-shared"
    location     = "unitedstates"
    description  = substr(replace(uuid(), "-", ""), 0, 8)
  }
}

run "creates_basic_environment" {
  command   = apply
  state_key = "basic"

  variables {
    environment = {
      display_name = "tftest-basic-env-${var.environment.description}"
      location     = "unitedstates"
    }
    dataverse = {
      currency_code     = "USD"
      security_group_id = "00000000-0000-0000-0000-000000000000"
    }
    managed_environment_enabled = false
  }

  assert {
    condition     = output.environment_display_name == var.environment.display_name
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
      display_name     = "tftest-custom-dv-env-${var.environment.description}"
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
    condition     = output.environment_display_name == var.environment.display_name
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
      display_name = "tftest-managed-env-${var.environment.description}"
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
    condition     = output.environment_display_name == var.environment.display_name
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
  command   = plan
  state_key = "managed"

  variables {
    environment = {
      display_name = "tftest-managed-env-${var.environment.description}"
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
    condition     = powerplatform_environment_settings.this[0].product.security.enable_ip_based_firewall_rule == true
    error_message = "Firewall setting should be enabled in plan when security_settings.enable_ip_based_firewall_rule = true."
  }

  assert {
    condition     = length(powerplatform_environment_settings.this[0].product.security.allowed_ip_range_for_firewall) == 1
    error_message = "allowed_ip_range_for_firewall should contain one CIDR value in plan."
  }
}

run "creates_environment_with_application_admin" {
  command   = apply
  state_key = "application-admin"

  variables {
    environment = {
      display_name = "tftest-app-admin-env-${var.environment.description}"
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
    condition     = output.environment_display_name == var.environment.display_name
    error_message = "Output 'environment_display_name' should match the input display_name."
  }
}

run "creates_environment_without_dataverse" {
  command   = apply
  state_key = "no-dataverse"

  variables {
    environment = {
      display_name = "tftest-no-dv-env-${var.environment.description}"
      location     = "unitedstates"
    }
    dataverse                   = null
    managed_environment_enabled = false
  }

  assert {
    condition     = output.environment_id != ""
    error_message = "Output 'environment_id' should be a non-empty string after apply."
  }

  assert {
    condition     = output.environment_url == null
    error_message = "Output 'environment_url' should be null when no Dataverse is provisioned."
  }

  assert {
    condition     = output.managed_environment_id == null
    error_message = "Output 'managed_environment_id' should be null when managed_environment_enabled = false."
  }
}

