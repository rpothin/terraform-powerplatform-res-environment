variable "environment" {
  description = <<DESCRIPTION
Configuration for the Power Platform environment.
- `display_name` - (Required) Display name of the environment. Must be 3–64 characters; alphanumeric, spaces, hyphens, and underscores only.
- `location` - (Required) Geographic location of the environment (e.g., `unitedstates`, `europe`).
- `allow_bing_search` - (Optional) Allow Bing search integration. Defaults to `false`.
- `allow_moving_data_across_regions` - (Optional) Allow data to move across regions. Defaults to `false`.
- `azure_region` - (Optional) Specific Azure region within the location (e.g., `westeurope`). Force-replace on change.
- `billing_policy_id` - (Optional) UUID of the billing policy for pay-as-you-go linking.
- `cadence` - (Optional) Update cadence: `Frequent` or `Moderate`. Defaults to `Moderate`.
- `description` - (Optional) Description of the environment.
- `environment_group_id` - (Optional) UUID of the environment group to join. Requires Dataverse. `managed_environment_enabled = true` is strongly recommended (Power Platform design intent for group-governed environments). `managed_environment_enabled = false` is technically permitted as a temporary workaround when the provider has known issues with group-managed environments — see module documentation for details and limitations.
- `environment_type` - (Optional) Type of environment: `Sandbox`, `Production`, or `Trial`. Defaults to `Sandbox`. Note: `Developer` type is not supported with service principal authentication.
- `release_cycle` - (Optional) Release cycle participation setting.
DESCRIPTION
  nullable    = false
  type = object({
    display_name                     = string
    location                         = string
    allow_bing_search                = optional(bool, false)
    allow_moving_data_across_regions = optional(bool, false)
    azure_region                     = optional(string, null)
    billing_policy_id                = optional(string, null)
    cadence                          = optional(string, "Moderate")
    description                      = optional(string, null)
    environment_group_id             = optional(string, null)
    environment_type                 = optional(string, "Sandbox")
    release_cycle                    = optional(string, null)
  })

  validation {
    condition     = length(var.environment.display_name) >= 3 && length(var.environment.display_name) <= 64
    error_message = "environment.display_name must be between 3 and 64 characters."
  }

  validation {
    condition     = can(regex("^[a-zA-Z0-9 _-]+$", var.environment.display_name))
    error_message = "environment.display_name may only contain alphanumeric characters, spaces, hyphens, and underscores."
  }

  validation {
    condition     = can(regex("[a-zA-Z0-9]", var.environment.display_name))
    error_message = "environment.display_name must contain at least one alphanumeric character."
  }

  validation {
    condition = contains([
      "unitedstates", "europe", "asia", "australia", "japan", "india",
      "canada", "southamerica", "unitedkingdom", "france", "germany",
      "switzerland", "norway", "korea", "southafrica", "uae", "singapore",
      "sweden"
    ], var.environment.location)
    error_message = "environment.location must be a valid Power Platform geographic region."
  }

  validation {
    condition     = contains(["Sandbox", "Production", "Trial"], var.environment.environment_type)
    error_message = "environment.environment_type must be one of: Sandbox, Production, Trial. Developer type is not supported with service principal authentication."
  }

  validation {
    condition     = var.environment.cadence == null || contains(["Frequent", "Moderate"], var.environment.cadence)
    error_message = "environment.cadence must be either 'Frequent' or 'Moderate'."
  }

  validation {
    condition     = var.environment.billing_policy_id == null || can(regex("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", var.environment.billing_policy_id))
    error_message = "environment.billing_policy_id must be a valid lowercase UUID when provided."
  }

  validation {
    condition     = var.environment.environment_group_id == null || can(regex("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", var.environment.environment_group_id))
    error_message = "environment.environment_group_id must be a valid lowercase UUID when provided."
  }
}

variable "application_admin_id" {
  default     = null
  description = "Azure AD application (client) ID of the service principal to assign as System Administrator in the environment. Set to null to skip this assignment."
  type        = string

  validation {
    condition     = var.application_admin_id == null || can(regex("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", var.application_admin_id))
    error_message = "application_admin_id must be a valid lowercase UUID when provided."
  }
}

variable "audit_and_logs" {
  default     = {}
  nullable    = false
  description = <<DESCRIPTION
Audit and logging configuration for the environment.
- `is_audit_enabled` - Enable general auditing. Defaults to `true`.
- `is_read_audit_enabled` - Enable read auditing (high volume). Defaults to `false`.
- `is_user_access_audit_enabled` - Enable user access auditing. Defaults to `true`.
- `log_retention_period_in_days` - Log retention in days (31–24855, or -1 for forever). Defaults to `90`.
- `plugin_trace_log_setting` - Plugin trace log level: `Off`, `Exception`, or `All`. Defaults to `Exception`.
DESCRIPTION
  type = object({
    is_audit_enabled             = optional(bool, true)
    is_read_audit_enabled        = optional(bool, false)
    is_user_access_audit_enabled = optional(bool, true)
    log_retention_period_in_days = optional(number, 90)
    plugin_trace_log_setting     = optional(string, "Exception")
  })

  validation {
    condition     = contains(["Off", "Exception", "All"], var.audit_and_logs.plugin_trace_log_setting)
    error_message = "audit_and_logs.plugin_trace_log_setting must be one of: Off, Exception, All."
  }

  validation {
    condition     = var.audit_and_logs.log_retention_period_in_days == -1 || (var.audit_and_logs.log_retention_period_in_days >= 31 && var.audit_and_logs.log_retention_period_in_days <= 24855)
    error_message = "audit_and_logs.log_retention_period_in_days must be -1 (forever) or between 31 and 24855 days."
  }
}

variable "behavior_settings" {
  default     = {}
  nullable    = false
  description = <<DESCRIPTION
Product behavior settings for the environment.
- `show_dashboard_cards_in_expanded_state` - Show dashboard cards in expanded state by default. Defaults to `false`.
DESCRIPTION
  type = object({
    show_dashboard_cards_in_expanded_state = optional(bool, false)
  })
}

variable "dataverse" {
  default     = {}
  nullable    = true
  description = <<DESCRIPTION
Dataverse database configuration. Defaults to `{}` — Dataverse is provisioned with sensible defaults (`currency_code = "USD"`, no security group restriction). Override individual fields by passing a partial object. Pass `null` to skip Dataverse provisioning entirely (requires `managed_environment_enabled = false`).
- `currency_code` - (Optional) ISO 4217 currency code (e.g., `USD`, `EUR`, `GBP`). Defaults to `"USD"`.
- `security_group_id` - (Optional) Azure AD security group UUID for environment access control. Defaults to `"00000000-0000-0000-0000-000000000000"` (Power Platform convention for no group restriction — not a security recommendation; set an explicit group UUID for restricted access).
- `administration_mode_enabled` - (Optional) Enable administration mode. Cannot be `true` simultaneously with `background_operation_enabled = true`. Defaults to `false`.
- `background_operation_enabled` - (Optional) Enable background operations. Defaults to `true`.
- `domain` - (Optional) Custom subdomain for the environment URL. Auto-calculated from `display_name` if null. Must be 2–63 lowercase alphanumeric characters and hyphens, no leading or trailing hyphens.
- `language_code` - (Optional) LCID language code (e.g., `1033` for English). Defaults to `1033`.
- `template_metadata` - (Optional) Additional Dynamics 365 template metadata.
- `templates` - (Optional) List of Dynamics 365 template names to apply.
DESCRIPTION
  type = object({
    currency_code                = optional(string, "USD")
    security_group_id            = optional(string, "00000000-0000-0000-0000-000000000000")
    administration_mode_enabled  = optional(bool, false)
    background_operation_enabled = optional(bool, true)
    domain                       = optional(string, null)
    language_code                = optional(number, 1033)
    template_metadata            = optional(string, null)
    templates                    = optional(list(string), null)
  })

  validation {
    condition = var.dataverse == null || contains([
      "USD", "EUR", "GBP", "CAD", "AUD", "JPY", "CHF", "CNY", "SEK", "NOK",
      "DKK", "NZD", "MXN", "SGD", "HKD", "KRW", "INR", "BRL", "ZAR", "AED",
      "SAR", "PLN", "CZK", "HUF", "RON", "BGN", "HRK", "RUB", "TRY", "IDR",
      "MYR", "PHP", "THB", "VND", "UAH", "ILS", "PKR", "BDT", "EGP", "QAR",
      "KWD", "MAD", "NGN", "KES", "GHS", "TZS", "UGX", "XOF", "XAF", "CLP",
      "COP", "PEN", "ARS", "BOB", "PYG", "UYU", "GTQ", "CRC", "HNL", "NIO",
      "DOP", "JMD", "TTD", "BBD", "BZD", "AWG"
    ], var.dataverse.currency_code)
    error_message = "dataverse.currency_code must be a valid ISO 4217 currency code."
  }

  validation {
    condition     = var.dataverse == null || can(regex("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", var.dataverse.security_group_id))
    error_message = "dataverse.security_group_id must be a valid lowercase UUID."
  }

  validation {
    condition     = var.dataverse == null || (var.dataverse.language_code >= 1 && var.dataverse.language_code <= 9999)
    error_message = "dataverse.language_code must be between 1 and 9999."
  }

  validation {
    condition     = var.dataverse == null || var.dataverse.domain == null || can(regex("^[a-z0-9][a-z0-9-]{0,61}[a-z0-9]$", var.dataverse.domain))
    error_message = "dataverse.domain must be lowercase alphanumeric and hyphens only, 2–63 characters, no leading or trailing hyphens."
  }
}

variable "email_settings" {
  default     = {}
  nullable    = false
  description = <<DESCRIPTION
Email configuration for the environment.
- `max_upload_file_size_in_bytes` - Maximum email attachment size in bytes (1–131,072,000). Defaults to `5242880` (5 MB).
DESCRIPTION
  type = object({
    max_upload_file_size_in_bytes = optional(number, 5242880)
  })

  validation {
    condition     = var.email_settings.max_upload_file_size_in_bytes >= 1 && var.email_settings.max_upload_file_size_in_bytes <= 131072000
    error_message = "email_settings.max_upload_file_size_in_bytes must be between 1 and 131,072,000 bytes (125 MB)."
  }
}

variable "feature_settings" {
  default     = {}
  nullable    = false
  description = <<DESCRIPTION
Product feature flags for the environment. All AI-powered features default to disabled (zero-trust posture).
- `ai_form_fill_automatic_suggestions` - AI automatic form fill suggestions. Valid values: `On`, `Off`, `Default`. Defaults to `"Off"`.
- `ai_form_fill_smart_paste_and_file_suggestions` - AI smart paste and file suggestions. Valid values: `On`, `Off`, `Default`. Defaults to `"Off"`.
- `ai_form_fill_toolbar` - AI form fill toolbar. Valid values: `On`, `Off`, `Default`. Defaults to `"Off"`.
- `allow_ai_to_generate_charts` - Allow AI to generate charts. Valid values: `On`, `Off`, `Auto`. Defaults to `"Off"`.
- `enable_access_to_session_transcripts_for_copilot_studio` - Allow access to session transcripts. Defaults to `false`.
- `enable_ai_powered_chat` - AI-powered chat assistant. Valid values: `On`, `Off`, `Default`. Defaults to `"Off"`.
- `enable_ai_prompts` - Enable AI prompts. Defaults to `false`.
- `enable_copilot_answer_control` - Enable Copilot answer controls. Defaults to `false`.
- `enable_copilot_studio_cross_geo_share_data_with_viva_insights` - Cross-geo Viva Insights sharing. Defaults to `false`.
- `enable_copilot_studio_share_data_with_viva_insights` - Viva Insights data sharing. Defaults to `false`.
- `enable_powerapps_maker_bot` - AI-powered Copilot for makers. Defaults to `false`.
- `enable_preview_and_experimental_ai_models` - Preview AI model access. Defaults to `false`.
- `enable_transcript_recording_for_copilot_studio` - Transcript recording for Copilot Studio. Defaults to `false`.
- `natural_language_grid_and_view_search` - Natural language search scope. Valid values: `AllUsers`, `UserAsFeatureBecomesAvailable`, `NoOne`. Defaults to `"NoOne"`.
- `power_apps_component_framework_for_canvas_apps` - Enable PCF controls in canvas apps. Defaults to `false`.
DESCRIPTION
  type = object({
    ai_form_fill_automatic_suggestions                            = optional(string, "Off")
    ai_form_fill_smart_paste_and_file_suggestions                 = optional(string, "Off")
    ai_form_fill_toolbar                                          = optional(string, "Off")
    allow_ai_to_generate_charts                                   = optional(string, "Off")
    enable_access_to_session_transcripts_for_copilot_studio       = optional(bool, false)
    enable_ai_powered_chat                                        = optional(string, "Off")
    enable_ai_prompts                                             = optional(bool, false)
    enable_copilot_answer_control                                 = optional(bool, false)
    enable_copilot_studio_cross_geo_share_data_with_viva_insights = optional(bool, false)
    enable_copilot_studio_share_data_with_viva_insights           = optional(bool, false)
    enable_powerapps_maker_bot                                    = optional(bool, false)
    enable_preview_and_experimental_ai_models                     = optional(bool, false)
    enable_transcript_recording_for_copilot_studio                = optional(bool, false)
    natural_language_grid_and_view_search                         = optional(string, "NoOne")
    power_apps_component_framework_for_canvas_apps                = optional(bool, false)
  })

  validation {
    condition = alltrue([for v in [
      var.feature_settings.ai_form_fill_automatic_suggestions,
      var.feature_settings.ai_form_fill_smart_paste_and_file_suggestions,
      var.feature_settings.ai_form_fill_toolbar,
    ] : contains(["On", "Off", "Default"], v)])
    error_message = "feature_settings AI form-fill fields must be one of: On, Off, Default."
  }

  validation {
    condition     = contains(["On", "Off", "Default"], var.feature_settings.enable_ai_powered_chat)
    error_message = "feature_settings.enable_ai_powered_chat must be one of: On, Off, Default."
  }

  validation {
    condition     = contains(["On", "Off", "Auto"], var.feature_settings.allow_ai_to_generate_charts)
    error_message = "feature_settings.allow_ai_to_generate_charts must be one of: On, Off, Auto."
  }

  validation {
    condition     = contains(["AllUsers", "UserAsFeatureBecomesAvailable", "NoOne"], var.feature_settings.natural_language_grid_and_view_search)
    error_message = "feature_settings.natural_language_grid_and_view_search must be one of: AllUsers, UserAsFeatureBecomesAvailable, NoOne."
  }
}

variable "managed_environment" {
  default     = {}
  nullable    = false
  description = <<DESCRIPTION
Managed Environment governance configuration. Applied when `managed_environment_enabled = true`. All fields default to secure, governance-aligned values.

**Interaction with environment groups (Tier 1):** When `environment.environment_group_id` is set and `managed_environment_enabled = true` (recommended), the `powerplatform_managed_environment` resource is created — these settings become the env-level **initial baseline**. The group's published rule set then governs enforcement (overriding or extending individual environment settings). In practice this means you only need to customise this variable for standalone managed environments (Tier 2); group-governed environments (Tier 1) inherit policy from the group.

**Temporary workaround for provider issues:** If the provider returns invalid attributes when using group + managed=true (see Known Limitations), you may set `managed_environment_enabled = false` as a temporary escape hatch. This prevents `powerplatform_managed_environment` from being created, but the environment will be an unmanaged group member — not the intended configuration. Restore `managed_environment_enabled = true` once the provider issue is resolved.
- `copilot_allow_grant_editor_permissions_when_shared` - Allow Copilot to grant Editor permissions when shared. Defaults to `false`.
- `copilot_limit_sharing_mode` - Sharing scope for Copilot agents. Valid values: `DisableSharing`, `ExcludeSharingToSecurityGroups`, `NoLimit`. Defaults to `"ExcludeSharingToSecurityGroups"`.
- `copilot_max_limit_user_sharing` - Maximum users for Copilot agent sharing (-1 when group sharing enabled). Defaults to `10`.
- `is_group_sharing_disabled` - Restrict canvas app sharing to security groups. Defaults to `true`.
- `is_usage_insights_disabled` - Disable weekly usage insights emails. Defaults to `false` (insights are valuable for governance).
- `limit_sharing_mode` - Canvas app sharing scope. Valid values: `ExcludeSharingToSecurityGroups`, `NoLimit`. Defaults to `"ExcludeSharingToSecurityGroups"`.
- `max_limit_user_sharing` - Maximum users canvas apps can be shared with (-1 when group sharing enabled). Defaults to `10`.
- `power_automate_is_sharing_disabled` - Disable sharing of solution-aware cloud flows. Defaults to `true`.
- `solution_checker_mode` - Solution checker enforcement: `None`, `Warn`, or `Block`. Defaults to `"Warn"`.
- `solution_checker_rule_overrides` - Set of solution checker rule codes to exclude from enforcement. Defaults to `null` (unset). Empty sets are normalized to `null` for provider compatibility.
- `suppress_validation_emails` - Only send emails when solutions are blocked (not on warnings). Defaults to `true`.
DESCRIPTION
  type = object({
    copilot_allow_grant_editor_permissions_when_shared = optional(bool, false)
    copilot_limit_sharing_mode                         = optional(string, "ExcludeSharingToSecurityGroups")
    copilot_max_limit_user_sharing                     = optional(number, 10)
    is_group_sharing_disabled                          = optional(bool, true)
    is_usage_insights_disabled                         = optional(bool, false)
    limit_sharing_mode                                 = optional(string, "ExcludeSharingToSecurityGroups")
    max_limit_user_sharing                             = optional(number, 10)
    power_automate_is_sharing_disabled                 = optional(bool, true)
    solution_checker_mode                              = optional(string, "Warn")
    solution_checker_rule_overrides                    = optional(set(string), null)
    suppress_validation_emails                         = optional(bool, true)
  })

  validation {
    condition     = contains(["None", "Warn", "Block"], var.managed_environment.solution_checker_mode)
    error_message = "managed_environment.solution_checker_mode must be one of: None, Warn, Block."
  }

  validation {
    condition     = var.managed_environment.max_limit_user_sharing >= -1
    error_message = "managed_environment.max_limit_user_sharing must be -1 or a positive integer."
  }

  validation {
    condition     = var.managed_environment.copilot_max_limit_user_sharing >= -1
    error_message = "managed_environment.copilot_max_limit_user_sharing must be -1 or a positive integer."
  }

  validation {
    condition     = contains(["ExcludeSharingToSecurityGroups", "NoLimit"], var.managed_environment.limit_sharing_mode)
    error_message = "managed_environment.limit_sharing_mode must be one of: ExcludeSharingToSecurityGroups, NoLimit."
  }

  validation {
    condition     = contains(["DisableSharing", "ExcludeSharingToSecurityGroups", "NoLimit"], var.managed_environment.copilot_limit_sharing_mode)
    error_message = "managed_environment.copilot_limit_sharing_mode must be one of: DisableSharing, ExcludeSharingToSecurityGroups, NoLimit."
  }
}

variable "managed_environment_enabled" {
  default     = true
  nullable    = false
  description = <<DESCRIPTION
Whether to enable Managed Environment features for this environment. Defaults to `true` (secure-by-default posture).

Managed Environments provide premium governance capabilities including solution checker enforcement, sharing controls, usage insights, and access to IP firewall and session cookie binding security features. All active users in a Managed Environment must hold a qualifying premium licence (Power Apps Premium, Power Automate Premium, or Dynamics 365 Enterprise).

This module supports three governance tiers, in recommended order:

1. **Group-governed** (recommended): set `environment.environment_group_id` **and** keep `managed_environment_enabled = true`. Power Platform's design intent is that group members are Managed Environments. The group's published rule set governs enforcement; the env-level managed settings serve as the initial baseline. See Known Limitations if the provider returns errors for this combination.
2. **Standalone managed** (good): `managed_environment_enabled = true` with no group. The environment is governed individually.
3. **Unmanaged** (accepted, not recommended): `managed_environment_enabled = false` with no group. No premium governance features are available.

Set to `false` only for environments where premium licensing is not available, governance is not required, **or as a temporary escape hatch when the provider has known issues creating `powerplatform_managed_environment` for group-governed environments** (see Known Limitations — failure mode C). When used with `environment.environment_group_id`, `managed_environment_enabled = false` is technically permitted by the platform API but is not the intended configuration; `security_settings` will not be applied in that state.
DESCRIPTION
  type        = bool
}

variable "security_settings" {
  default     = null
  nullable    = true
  description = <<DESCRIPTION
Optional security settings for the environment. Applied only when explicitly set and `managed_environment_enabled = true`.
- `allow_application_user_access` - Allow service principal (application user) access. Defaults to `true`.
- `allow_microsoft_trusted_service_tags` - Allow Microsoft trusted service tags through the firewall. Defaults to `false`.
- `allowed_ip_range_for_firewall` - Set of CIDR IP ranges allowed through the firewall. Defaults to `[]`.
- `allowed_service_tags_for_firewall` - Set of Azure service tags allowed through the firewall. Defaults to `[]`.
- `enable_ip_based_cookie_binding` - Enable IP-based cookie binding. Defaults to `false`.
- `enable_ip_based_firewall_rule` - Enable IP-based firewall enforcement. Defaults to `false`.
- `enable_ip_based_firewall_rule_in_audit_mode` - Enable IP firewall in audit mode only. Defaults to `false`.
- `reverse_proxy_ip_addresses` - Set of trusted reverse proxy IP addresses. Defaults to `[]`.
DESCRIPTION
  type = object({
    allow_application_user_access               = optional(bool, true)
    allow_microsoft_trusted_service_tags        = optional(bool, false)
    allowed_ip_range_for_firewall               = optional(set(string), [])
    allowed_service_tags_for_firewall           = optional(set(string), [])
    enable_ip_based_cookie_binding              = optional(bool, false)
    enable_ip_based_firewall_rule               = optional(bool, false)
    enable_ip_based_firewall_rule_in_audit_mode = optional(bool, false)
    reverse_proxy_ip_addresses                  = optional(set(string), [])
  })
}






