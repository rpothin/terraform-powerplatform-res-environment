locals {
  final_domain = coalesce(
    var.dataverse.domain,
    replace(
      replace(
        substr(replace(lower(var.environment.display_name), "/[^a-z0-9]+/", "-"), 0, 63),
        "/^-+/",
        ""
      ),
      "/-+$/",
      ""
    )
  )

  security_settings_defaults = {
    allow_application_user_access               = true
    allow_microsoft_trusted_service_tags        = false
    allowed_ip_range_for_firewall               = toset([])
    allowed_service_tags_for_firewall           = toset([])
    enable_ip_based_cookie_binding              = false
    enable_ip_based_firewall_rule               = false
    enable_ip_based_firewall_rule_in_audit_mode = false
    reverse_proxy_ip_addresses                  = toset([])
  }

  security_settings_are_defaults = (
    var.security_settings.allow_application_user_access == local.security_settings_defaults.allow_application_user_access &&
    var.security_settings.allow_microsoft_trusted_service_tags == local.security_settings_defaults.allow_microsoft_trusted_service_tags &&
    length(var.security_settings.allowed_ip_range_for_firewall) == 0 &&
    length(var.security_settings.allowed_service_tags_for_firewall) == 0 &&
    var.security_settings.enable_ip_based_cookie_binding == local.security_settings_defaults.enable_ip_based_cookie_binding &&
    var.security_settings.enable_ip_based_firewall_rule == local.security_settings_defaults.enable_ip_based_firewall_rule &&
    var.security_settings.enable_ip_based_firewall_rule_in_audit_mode == local.security_settings_defaults.enable_ip_based_firewall_rule_in_audit_mode &&
    length(var.security_settings.reverse_proxy_ip_addresses) == 0
  )
}
