resource "powerplatform_environment" "this" {
  display_name     = var.environment.display_name
  environment_type = var.environment.environment_type
  location         = var.environment.location

  allow_bing_search                = var.environment.allow_bing_search
  allow_moving_data_across_regions = var.environment.allow_moving_data_across_regions
  azure_region                     = var.environment.azure_region
  billing_policy_id                = var.environment.billing_policy_id
  cadence                          = var.environment.cadence
  dataverse = {
    currency_code = var.dataverse.currency_code
    language_code = var.dataverse.language_code

    administration_mode_enabled  = var.dataverse.administration_mode_enabled
    background_operation_enabled = var.dataverse.background_operation_enabled
    domain                       = local.final_domain
    security_group_id            = var.dataverse.security_group_id
    template_metadata            = var.dataverse.template_metadata
    templates                    = var.dataverse.templates
  }
  description          = var.environment.description
  environment_group_id = var.environment.environment_group_id
  release_cycle        = var.environment.release_cycle
  timeouts = {
    create = "30m"
    delete = "15m"
    update = "15m"
  }

  lifecycle {
    precondition {
      condition     = !(var.dataverse.administration_mode_enabled && var.dataverse.background_operation_enabled)
      error_message = "dataverse.background_operation_enabled must be false when dataverse.administration_mode_enabled is true."
    }

    precondition {
      condition     = var.security_settings == null || var.managed_environment_enabled
      error_message = "security_settings requires managed_environment_enabled = true."
    }

    precondition {
      condition     = var.environment.environment_type != "Production" || var.managed_environment_enabled
      error_message = "Production environments require managed_environment_enabled = true. Managed Environments provide governance controls (solution checker enforcement, sharing limits, IP firewall capability) that are required for production workloads."
    }

    precondition {
      condition     = !(var.managed_environment_enabled && var.environment.environment_group_id != null)
      error_message = "managed_environment_enabled cannot be true when environment_group_id is set. Governance for group-member environments is controlled at the group level; set managed_environment_enabled = false when joining an environment group."
    }
  }
}

resource "powerplatform_managed_environment" "this" {
  count = var.managed_environment_enabled ? 1 : 0

  environment_id = powerplatform_environment.this.id

  copilot_allow_grant_editor_permissions_when_shared = var.managed_environment.copilot_allow_grant_editor_permissions_when_shared
  copilot_limit_sharing_mode                         = var.managed_environment.copilot_limit_sharing_mode
  copilot_max_limit_user_sharing                     = var.managed_environment.copilot_max_limit_user_sharing
  is_group_sharing_disabled                          = var.managed_environment.is_group_sharing_disabled
  is_usage_insights_disabled                         = var.managed_environment.is_usage_insights_disabled
  limit_sharing_mode                                 = var.managed_environment.limit_sharing_mode
  max_limit_user_sharing                             = var.managed_environment.max_limit_user_sharing
  power_automate_is_sharing_disabled                 = var.managed_environment.power_automate_is_sharing_disabled
  solution_checker_mode                              = var.managed_environment.solution_checker_mode
  solution_checker_rule_overrides                    = try(length(var.managed_environment.solution_checker_rule_overrides), 0) == 0 ? null : var.managed_environment.solution_checker_rule_overrides
  suppress_validation_emails                         = var.managed_environment.suppress_validation_emails
  timeouts = {
    create = "10m"
    delete = "10m"
    update = "10m"
  }
}

resource "powerplatform_environment_application_admin" "this" {
  count = var.application_admin_id != null ? 1 : 0

  application_id = var.application_admin_id
  environment_id = powerplatform_environment.this.id
  timeouts = {
    create = "5m"
  }
}

resource "powerplatform_environment_settings" "this" {
  environment_id = powerplatform_environment.this.id

  audit_and_logs = {
    audit_settings = {
      is_audit_enabled             = var.audit_and_logs.is_audit_enabled
      is_read_audit_enabled        = var.audit_and_logs.is_read_audit_enabled
      is_user_access_audit_enabled = var.audit_and_logs.is_user_access_audit_enabled
      log_retention_period_in_days = var.audit_and_logs.log_retention_period_in_days
    }
    plugin_trace_log_setting = var.audit_and_logs.plugin_trace_log_setting
  }
  email = {
    email_settings = {
      max_upload_file_size_in_bytes = var.email_settings.max_upload_file_size_in_bytes
    }
  }
  product = {
    behavior_settings = {
      show_dashboard_cards_in_expanded_state = var.behavior_settings.show_dashboard_cards_in_expanded_state
    }
    features = {
      ai_form_fill_automatic_suggestions                            = var.feature_settings.ai_form_fill_automatic_suggestions
      ai_form_fill_smart_paste_and_file_suggestions                 = var.feature_settings.ai_form_fill_smart_paste_and_file_suggestions
      ai_form_fill_toolbar                                          = var.feature_settings.ai_form_fill_toolbar
      allow_ai_to_generate_charts                                   = var.feature_settings.allow_ai_to_generate_charts
      enable_access_to_session_transcripts_for_copilot_studio       = var.feature_settings.enable_access_to_session_transcripts_for_copilot_studio
      enable_ai_powered_chat                                        = var.feature_settings.enable_ai_powered_chat
      enable_ai_prompts                                             = var.feature_settings.enable_ai_prompts
      enable_copilot_answer_control                                 = var.feature_settings.enable_copilot_answer_control
      enable_copilot_studio_cross_geo_share_data_with_viva_insights = var.feature_settings.enable_copilot_studio_cross_geo_share_data_with_viva_insights
      enable_copilot_studio_share_data_with_viva_insights           = var.feature_settings.enable_copilot_studio_share_data_with_viva_insights
      enable_powerapps_maker_bot                                    = var.feature_settings.enable_powerapps_maker_bot
      enable_preview_and_experimental_ai_models                     = var.feature_settings.enable_preview_and_experimental_ai_models
      enable_transcript_recording_for_copilot_studio                = var.feature_settings.enable_transcript_recording_for_copilot_studio
      natural_language_grid_and_view_search                         = var.feature_settings.natural_language_grid_and_view_search
      power_apps_component_framework_for_canvas_apps                = var.feature_settings.power_apps_component_framework_for_canvas_apps
    }
    security = var.managed_environment_enabled && var.security_settings != null ? {
      allow_application_user_access               = var.security_settings.allow_application_user_access
      allow_microsoft_trusted_service_tags        = var.security_settings.allow_microsoft_trusted_service_tags
      allowed_ip_range_for_firewall               = var.security_settings.allowed_ip_range_for_firewall
      allowed_service_tags_for_firewall           = var.security_settings.allowed_service_tags_for_firewall
      enable_ip_based_cookie_binding              = var.security_settings.enable_ip_based_cookie_binding
      enable_ip_based_firewall_rule               = var.security_settings.enable_ip_based_firewall_rule
      enable_ip_based_firewall_rule_in_audit_mode = var.security_settings.enable_ip_based_firewall_rule_in_audit_mode
      reverse_proxy_ip_addresses                  = var.security_settings.reverse_proxy_ip_addresses
    } : null
  }
  timeouts = {
    create = "10m"
    update = "10m"
  }

  depends_on = [powerplatform_managed_environment.this]
}




