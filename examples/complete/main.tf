# TODO (before publishing): Replace the source path below with the Terraform Registry
# address once the module is published, e.g.:
#   source  = "rpothin/<module-name>/powerplatform"
#   version = "~> 0.1"
# See: https://developer.hashicorp.com/terraform/language/modules/develop/structure#examples
module "environment" {
  source = "../../" # local path for development — update to registry address before publishing

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
