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
    solution_checker_mode  = "Warn"
    limit_sharing_mode     = "ExcludeSharingToSecurityGroups"
    max_limit_user_sharing = 10
  }

  audit_and_logs = {
    is_audit_enabled             = true
    log_retention_period_in_days = 90
    plugin_trace_log_setting     = "Exception"
  }

  feature_settings = {
    power_apps_component_framework_for_canvas_apps = false
  }
}
