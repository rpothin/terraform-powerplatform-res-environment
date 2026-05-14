# terraform-powerplatform-res-environment

A composite [AVM-aligned](https://azure.github.io/Azure-Verified-Modules/) Terraform module that provisions a fully-configured Power Platform environment end-to-end.

## What this module creates

| Resource | Condition | Purpose |
|---|---|---|
| `powerplatform_environment` | Always | Core Power Platform environment |
| `powerplatform_managed_environment` | `managed_environment_enabled = true` (default) | Premium governance features |
| `powerplatform_environment_settings` | Always | Audit, features, email, security configuration |
| `powerplatform_environment_application_admin` | `application_admin_id` is set | Service principal as System Administrator |

## Secure defaults

This module applies a **secure-by-default, zero-trust posture**:

- **Managed Environment enabled** — governance controls are on by default
- **All AI features disabled** — Copilot, form-fill AI, and generative features default to `Off` or `false`
- **Restricted sharing** — canvas app and cloud flow sharing limited to security groups
- **Auditing enabled** — general and user-access audit logs on by default
- **Bing search disabled** — cross-tenant data access disabled by default
- **Data residency enforced** — `allow_moving_data_across_regions` defaults to `false`

## Prerequisites

- Power Platform tenant with appropriate licensing (Managed Environments requires Power Platform premium licensing)
- Service principal with Power Platform admin permissions, authenticated via OIDC
- `POWER_PLATFORM_TENANT_ID` and `POWER_PLATFORM_CLIENT_ID` environment variables set

## Known limitations

- **`Developer` environment type** is not supported — the `microsoft/power-platform` provider cannot create Developer environments using service principal authentication
- **Environment group membership** — when `environment.environment_group_id` is set, Managed Environment settings are inherited from the group and individual settings in `var.managed_environment` are ignored (provider warning expected)
- **Security settings require Managed Environment** — `var.security_settings` is only applied when `managed_environment_enabled = true`; the provider causes state inconsistencies if security settings are applied to standard environments
- **Tags not supported** — the `powerplatform_environment` resource does not support Azure resource tags

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->
