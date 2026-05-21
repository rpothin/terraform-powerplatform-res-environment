module "environment" {
  source  = "rpothin/res-environment/powerplatform"
  version = "~> 0.1"

  environment = {
    display_name     = var.display_name
    location         = var.location
    environment_type = var.environment_type
    description      = var.description
  }

  dataverse = {
    currency_code     = var.dataverse_currency_code
    security_group_id = var.dataverse_security_group_id
    language_code     = var.dataverse_language_code
  }

  application_admin_id = var.application_admin_id

  managed_environment_enabled = var.managed_environment_enabled

  managed_environment = {
    solution_checker_mode              = "Block"
    suppress_validation_emails         = true
    power_automate_is_sharing_disabled = true
  }

  audit_and_logs = {
    is_audit_enabled             = true
    is_user_access_audit_enabled = true
    log_retention_period_in_days = 180
    plugin_trace_log_setting     = "Exception"
  }
}
