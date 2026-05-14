# terraform-powerplatform-res-environment

A composite [AVM-aligned](https://azure.github.io/Azure-Verified-Modules/) Terraform module that provisions a fully-configured Power Platform environment with Dataverse end-to-end.

## What this module creates

| Resource | Condition | Purpose |
|---|---|---|
| `powerplatform_environment` | Always | Core Power Platform environment with Dataverse |
| `powerplatform_managed_environment` | `managed_environment_enabled = true` (default) | Premium governance features |
| `powerplatform_environment_settings` | Always | Audit, features, email, security configuration |
| `powerplatform_environment_application_admin` | `application_admin_id` is set | Service principal as System Administrator |

## Secure defaults

This module applies a **secure-by-default, zero-trust posture**:

- **Dataverse always provisioned** — this module always creates a Dataverse database; use `dataverse.currency_code` and `dataverse.security_group_id` to configure it
- **Managed Environment enabled** — governance controls are on by default
- **Immediate hardening for managed environments** — `security_settings` defaults to `{}` and security controls are applied as soon as Managed Environment is enabled
- **All AI features disabled** — Copilot, form-fill AI, and generative features default to `Off` or `false`
- **Restricted sharing** — canvas app and cloud flow sharing limited to security groups
- **Auditing enabled** — general and user-access audit logs on by default
- **Bing search disabled** — cross-tenant data access disabled by default
- **Data residency enforced** — `allow_moving_data_across_regions` defaults to `false`

## Prerequisites

- Power Platform tenant with appropriate licensing (Managed Environments requires Power Platform premium licensing)
- Service principal with Power Platform admin permissions, authenticated via OIDC
- `POWER_PLATFORM_TENANT_ID` and `POWER_PLATFORM_CLIENT_ID` environment variables set
- CI prerequisite for application-admin integration tests: configure `POWER_PLATFORM_TEST_APPLICATION_ADMIN_ID` as a GitHub Actions secret

## Known limitations

- **`Developer` environment type** is not supported — the `microsoft/power-platform` provider cannot create Developer environments using service principal authentication
- **Environment group membership** — when `environment.environment_group_id` is set, Managed Environment settings are inherited from the group and individual settings in `var.managed_environment` are ignored (provider warning expected)
- **Security settings require Managed Environment** — `var.security_settings` defaults to `{}` and is applied only when `managed_environment_enabled = true`; a lifecycle precondition enforces this
- **No `prevent_destroy` guardrail** — this module does not enforce Terraform `lifecycle.prevent_destroy`; use external policy/approval controls if required
- **Tags not supported** — the `powerplatform_environment` resource does not support Azure resource tags

## Troubleshooting

### Transient timing issues with Managed Environment + security/firewall settings

Power Platform and provider-side propagation can be eventually consistent right after Managed Environment creation. In some runs, security/firewall application in `powerplatform_environment_settings` may fail transiently even with explicit dependency ordering.

If this occurs:

- Re-run `terraform apply` (most cases succeed on the next run)
- Allow a short wait after initial environment creation before re-applying
- Keep `managed_environment_enabled = true` when using `security_settings`

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->
