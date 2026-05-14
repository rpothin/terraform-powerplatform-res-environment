# Unit tests — uses mock provider, no credentials required.

mock_provider "powerplatform" {}

# ---------------------------------------------------------------------------
# Variable validation — environment
# ---------------------------------------------------------------------------

run "validates_display_name_too_short" {
  command = plan

  variables {
    environment = {
      display_name = "AB"
      location     = "unitedstates"
    }
    dataverse = { currency_code = "USD", security_group_id = "00000000-0000-0000-0000-000000000000" }
  }

  expect_failures = [var.environment]
}

run "validates_display_name_too_long" {
  command = plan

  variables {
    environment = {
      display_name = "AAAAAAAAAABBBBBBBBBBCCCCCCCCCCDDDDDDDDDDEEEEEEEEEEFFFFF123456789012"
      location     = "unitedstates"
    }
    dataverse = { currency_code = "USD", security_group_id = "00000000-0000-0000-0000-000000000000" }
  }

  expect_failures = [var.environment]
}

run "validates_display_name_invalid_chars" {
  command = plan

  variables {
    environment = {
      display_name = "Test@Env!"
      location     = "unitedstates"
    }
    dataverse = { currency_code = "USD", security_group_id = "00000000-0000-0000-0000-000000000000" }
  }

  expect_failures = [var.environment]
}

run "validates_environment_type_invalid" {
  command = plan

  variables {
    environment = {
      display_name     = "Test Environment"
      location         = "unitedstates"
      environment_type = "Developer"
    }
    dataverse = { currency_code = "USD", security_group_id = "00000000-0000-0000-0000-000000000000" }
  }

  expect_failures = [var.environment]
}

run "validates_location_invalid" {
  command = plan

  variables {
    environment = {
      display_name = "Test Environment"
      location     = "mars"
    }
    dataverse = { currency_code = "USD", security_group_id = "00000000-0000-0000-0000-000000000000" }
  }

  expect_failures = [var.environment]
}

# ---------------------------------------------------------------------------
# Variable validation — application_admin_id
# ---------------------------------------------------------------------------

run "validates_application_admin_id_invalid_uuid" {
  command = plan

  variables {
    environment = {
      display_name = "Test Environment"
      location     = "unitedstates"
    }
    dataverse            = { currency_code = "USD", security_group_id = "00000000-0000-0000-0000-000000000000" }
    application_admin_id = "not-a-uuid"
  }

  expect_failures = [var.application_admin_id]
}

# ---------------------------------------------------------------------------
# Variable validation — dataverse
# ---------------------------------------------------------------------------

run "validates_dataverse_currency_code_invalid" {
  command = plan

  variables {
    environment = {
      display_name = "Test Environment"
      location     = "unitedstates"
    }
    dataverse = {
      currency_code     = "FAKE"
      security_group_id = "00000000-0000-0000-0000-000000000000"
    }
  }

  expect_failures = [var.dataverse]
}

run "validates_dataverse_security_group_id_invalid_uuid" {
  command = plan

  variables {
    environment = {
      display_name = "Test Environment"
      location     = "unitedstates"
    }
    dataverse = {
      currency_code     = "USD"
      security_group_id = "not-a-uuid"
    }
  }

  expect_failures = [var.dataverse]
}

# ---------------------------------------------------------------------------
# Variable validation — audit_and_logs
# ---------------------------------------------------------------------------

run "validates_audit_log_retention_out_of_range" {
  command = plan

  variables {
    environment = {
      display_name = "Test Environment"
      location     = "unitedstates"
    }
    dataverse = { currency_code = "USD", security_group_id = "00000000-0000-0000-0000-000000000000" }
    audit_and_logs = {
      log_retention_period_in_days = 10
    }
  }

  expect_failures = [var.audit_and_logs]
}

run "validates_plugin_trace_log_setting_invalid" {
  command = plan

  variables {
    environment = {
      display_name = "Test Environment"
      location     = "unitedstates"
    }
    dataverse = { currency_code = "USD", security_group_id = "00000000-0000-0000-0000-000000000000" }
    audit_and_logs = {
      plugin_trace_log_setting = "Verbose"
    }
  }

  expect_failures = [var.audit_and_logs]
}

# ---------------------------------------------------------------------------
# Variable validation — email_settings
# ---------------------------------------------------------------------------

run "validates_email_max_upload_too_large" {
  command = plan

  variables {
    environment = {
      display_name = "Test Environment"
      location     = "unitedstates"
    }
    dataverse = { currency_code = "USD", security_group_id = "00000000-0000-0000-0000-000000000000" }
    email_settings = {
      max_upload_file_size_in_bytes = 200000000
    }
  }

  expect_failures = [var.email_settings]
}

# ---------------------------------------------------------------------------
# Variable validation — managed_environment
# ---------------------------------------------------------------------------

run "validates_solution_checker_mode_invalid" {
  command = plan

  variables {
    environment = {
      display_name = "Test Environment"
      location     = "unitedstates"
    }
    dataverse = { currency_code = "USD", security_group_id = "00000000-0000-0000-0000-000000000000" }
    managed_environment = {
      solution_checker_mode = "Enforce"
    }
  }

  expect_failures = [var.managed_environment]
}

# ---------------------------------------------------------------------------
# Resource count assertions
# ---------------------------------------------------------------------------

run "managed_environment_created_by_default" {
  command = plan

  variables {
    environment = {
      display_name = "Test Environment"
      location     = "unitedstates"
    }
    dataverse = { currency_code = "USD", security_group_id = "00000000-0000-0000-0000-000000000000" }
  }

  assert {
    condition     = length(powerplatform_managed_environment.this) == 1
    error_message = "powerplatform_managed_environment should be created when managed_environment_enabled defaults to true."
  }
}

run "managed_environment_empty_solution_checker_overrides_normalized_to_null" {
  command = plan

  variables {
    environment = {
      display_name = "Test Environment"
      location     = "unitedstates"
    }
    dataverse = { currency_code = "USD", security_group_id = "00000000-0000-0000-0000-000000000000" }
    managed_environment = {
      solution_checker_rule_overrides = []
    }
  }

  assert {
    condition     = length(powerplatform_managed_environment.this) == 1
    error_message = "powerplatform_managed_environment should be created when managed_environment_enabled defaults to true."
  }


}

run "managed_environment_not_created_when_disabled" {
  command = plan

  variables {
    environment = {
      display_name = "Test Environment"
      location     = "unitedstates"
    }
    dataverse                   = { currency_code = "USD", security_group_id = "00000000-0000-0000-0000-000000000000" }
    managed_environment_enabled = false
  }

  assert {
    condition     = length(powerplatform_managed_environment.this) == 0
    error_message = "powerplatform_managed_environment should not be created when managed_environment_enabled = false."
  }
}

run "application_admin_not_created_when_null" {
  command = plan

  variables {
    environment = {
      display_name = "Test Environment"
      location     = "unitedstates"
    }
    dataverse = { currency_code = "USD", security_group_id = "00000000-0000-0000-0000-000000000000" }
  }

  assert {
    condition     = length(powerplatform_environment_application_admin.this) == 0
    error_message = "powerplatform_environment_application_admin should not be created when application_admin_id is null."
  }
}

run "application_admin_created_when_set" {
  command = plan

  variables {
    environment = {
      display_name = "Test Environment"
      location     = "unitedstates"
    }
    dataverse            = { currency_code = "USD", security_group_id = "00000000-0000-0000-0000-000000000000" }
    application_admin_id = "12345678-1234-1234-1234-123456789012"
  }

  assert {
    condition     = length(powerplatform_environment_application_admin.this) == 1
    error_message = "powerplatform_environment_application_admin should be created when application_admin_id is set."
  }
}

# ---------------------------------------------------------------------------
# Lifecycle preconditions
# ---------------------------------------------------------------------------

run "precondition_admin_mode_background_ops_conflict" {
  command = plan

  variables {
    environment = {
      display_name = "Test Environment"
      location     = "unitedstates"
    }
    dataverse = {
      currency_code                = "USD"
      security_group_id            = "00000000-0000-0000-0000-000000000000"
      administration_mode_enabled  = true
      background_operation_enabled = true
    }
  }

  expect_failures = [powerplatform_environment.this]
}

run "security_settings_applied_by_default_when_managed_enabled" {
  command = apply

  variables {
    environment = {
      display_name = "Test Environment"
      location     = "unitedstates"
    }
    dataverse = { currency_code = "USD", security_group_id = "00000000-0000-0000-0000-000000000000" }
  }

  assert {
    condition     = powerplatform_environment_settings.this.product.security != null
    error_message = "product.security should be set by default when managed_environment_enabled = true."
  }
}

run "security_settings_applied_when_explicit_and_managed_enabled" {
  command = apply

  variables {
    environment = {
      display_name = "Test Environment"
      location     = "unitedstates"
    }
    dataverse                   = { currency_code = "USD", security_group_id = "00000000-0000-0000-0000-000000000000" }
    managed_environment_enabled = true
    security_settings = {
      enable_ip_based_firewall_rule = true
    }
  }

  assert {
    condition     = powerplatform_environment_settings.this.product.security.enable_ip_based_firewall_rule == true
    error_message = "Custom security settings should propagate to product.security when managed_environment_enabled = true."
  }
}
run "managed_environment_disabled_with_default_security_settings_plans" {
  command = plan

  variables {
    environment                 = { display_name = "Test Environment", location = "unitedstates" }
    dataverse                   = { currency_code = "USD", security_group_id = "00000000-0000-0000-0000-000000000000" }
    managed_environment_enabled = false
  }

  assert {
    condition     = length(powerplatform_managed_environment.this) == 0
    error_message = "Plan should succeed with managed_environment_enabled = false when security_settings remain at defaults."
  }
}


# ---------------------------------------------------------------------------
# Output assertions
# ---------------------------------------------------------------------------

run "output_environment_id_is_non_empty" {
  command = plan

  variables {
    environment = {
      display_name = "Test Environment"
      location     = "unitedstates"
    }
    dataverse = { currency_code = "USD", security_group_id = "00000000-0000-0000-0000-000000000000" }
  }

  # Override the computed id so it is known at plan time with a mock provider.
  override_resource {
    target          = powerplatform_environment.this
    override_during = plan
    values = {
      id = "mock-environment-id-00000000"
    }
  }

  assert {
    condition     = output.environment_id != ""
    error_message = "Output 'environment_id' should be a non-empty string."
  }
}

run "managed_environment_id_null_when_disabled" {
  command = plan

  variables {
    environment = {
      display_name = "Test Environment"
      location     = "unitedstates"
    }
    dataverse                   = { currency_code = "USD", security_group_id = "00000000-0000-0000-0000-000000000000" }
    managed_environment_enabled = false
  }

  assert {
    condition     = output.managed_environment_id == null
    error_message = "Output 'managed_environment_id' should be null when managed_environment_enabled = false."
  }
}

# ---------------------------------------------------------------------------
# Domain auto-calculation
# ---------------------------------------------------------------------------

run "domain_auto_calculated_from_display_name" {
  command = plan

  variables {
    environment = {
      display_name = "My Test Env"
      location     = "unitedstates"
    }
    dataverse = {
      currency_code     = "USD"
      security_group_id = "00000000-0000-0000-0000-000000000000"
    }
  }

  assert {
    condition     = powerplatform_environment.this.dataverse.domain == "my-test-env"
    error_message = "Domain should be auto-calculated as 'my-test-env' from display_name 'My Test Env'."
  }
}

run "domain_respects_explicit_value" {
  command = plan

  variables {
    environment = {
      display_name = "My Test Env"
      location     = "unitedstates"
    }
    dataverse = {
      currency_code     = "USD"
      security_group_id = "00000000-0000-0000-0000-000000000000"
      domain            = "my-custom-domain"
    }
  }

  assert {
    condition     = powerplatform_environment.this.dataverse.domain == "my-custom-domain"
    error_message = "Explicit domain should override the auto-calculated value."
  }
}

# ---------------------------------------------------------------------------
# Variable validation — feature_settings
# ---------------------------------------------------------------------------

run "validates_ai_form_fill_invalid_value" {
  command = plan

  variables {
    environment      = { display_name = "Test Environment", location = "unitedstates" }
    dataverse        = { currency_code = "USD", security_group_id = "00000000-0000-0000-0000-000000000000" }
    feature_settings = { ai_form_fill_toolbar = "Invalid" }
  }

  expect_failures = [var.feature_settings]
}

run "validates_allow_ai_to_generate_charts_invalid" {
  command = plan

  variables {
    environment      = { display_name = "Test Environment", location = "unitedstates" }
    dataverse        = { currency_code = "USD", security_group_id = "00000000-0000-0000-0000-000000000000" }
    feature_settings = { allow_ai_to_generate_charts = "Yes" }
  }

  expect_failures = [var.feature_settings]
}

run "validates_natural_language_search_invalid" {
  command = plan

  variables {
    environment      = { display_name = "Test Environment", location = "unitedstates" }
    dataverse        = { currency_code = "USD", security_group_id = "00000000-0000-0000-0000-000000000000" }
    feature_settings = { natural_language_grid_and_view_search = "Everyone" }
  }

  expect_failures = [var.feature_settings]
}

# ---------------------------------------------------------------------------
# Variable validation — managed_environment sharing modes
# ---------------------------------------------------------------------------

run "validates_limit_sharing_mode_invalid" {
  command = plan

  variables {
    environment         = { display_name = "Test Environment", location = "unitedstates" }
    dataverse           = { currency_code = "USD", security_group_id = "00000000-0000-0000-0000-000000000000" }
    managed_environment = { limit_sharing_mode = "Restricted" }
  }

  expect_failures = [var.managed_environment]
}

run "validates_copilot_limit_sharing_mode_invalid" {
  command = plan

  variables {
    environment         = { display_name = "Test Environment", location = "unitedstates" }
    dataverse           = { currency_code = "USD", security_group_id = "00000000-0000-0000-0000-000000000000" }
    managed_environment = { copilot_limit_sharing_mode = "Restricted" }
  }

  expect_failures = [var.managed_environment]
}

# ---------------------------------------------------------------------------
# Variable validation — dataverse domain format
# ---------------------------------------------------------------------------

run "validates_domain_invalid_format" {
  command = plan

  variables {
    environment = { display_name = "Test Environment", location = "unitedstates" }
    dataverse   = { currency_code = "USD", security_group_id = "00000000-0000-0000-0000-000000000000", domain = "INVALID DOMAIN!" }
  }

  expect_failures = [var.dataverse]
}

# ---------------------------------------------------------------------------
# Variable validation — display_name alphanumeric requirement
# ---------------------------------------------------------------------------

run "validates_display_name_no_alphanumeric" {
  command = plan

  variables {
    environment = { display_name = "___", location = "unitedstates" }
    dataverse   = { currency_code = "USD", security_group_id = "00000000-0000-0000-0000-000000000000" }
  }

  expect_failures = [var.environment]
}

# ---------------------------------------------------------------------------
# Lifecycle preconditions — security_settings requires managed_environment
# ---------------------------------------------------------------------------

run "precondition_fails_when_managed_environment_disabled_and_security_customized" {
  command = plan

  variables {
    environment                 = { display_name = "Test Environment", location = "unitedstates" }
    dataverse                   = { currency_code = "USD", security_group_id = "00000000-0000-0000-0000-000000000000" }
    managed_environment_enabled = false
    security_settings           = { enable_ip_based_firewall_rule = true }
  }

  expect_failures = [powerplatform_environment.this]
}







