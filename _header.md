# terraform-powerplatform-res-environment

A composite [AVM-aligned](https://azure.github.io/Azure-Verified-Modules/) Terraform module that provisions a fully-configured Power Platform environment with optional Dataverse end-to-end.

## What this module creates

| Resource | Condition | Purpose |
|---|---|---|
| `powerplatform_environment` | Always | Core Power Platform environment. Dataverse provisioned by default (set `dataverse = null` to skip). |
| `powerplatform_managed_environment` | `managed_environment_enabled = true` (default) | Premium governance features |
| `powerplatform_environment_settings` | `dataverse != null` (default) | Audit, features, email, security configuration (requires Dataverse) |
| `powerplatform_environment_application_admin` | `application_admin_id` is set | Service principal as System Administrator |

## Secure defaults

This module applies a **secure-by-default, zero-trust posture**:

- **Dataverse provisioned by default** — Dataverse is enabled with sensible defaults (`currency_code = "USD"`, no security group restriction). Override via `dataverse = { ... }` or skip entirely with `dataverse = null` (requires `managed_environment_enabled = false`).
- **Managed Environment enabled** — governance controls are on by default
- **Immediate hardening for managed environments** — `security_settings` defaults to `{}` and security controls are applied as soon as Managed Environment is enabled
- **All AI features disabled** — Copilot, form-fill AI, and generative features default to `Off` or `false`
- **Restricted sharing** — canvas app and cloud flow sharing limited to security groups
- **Auditing enabled** — general and user-access audit logs on by default
- **Bing search disabled** — cross-tenant data access disabled by default
- **Data residency enforced** — `allow_moving_data_across_regions` defaults to `false`

## Governance paths

This module supports three governance tiers for Power Platform environments, in recommended order:

| Tier | When to Use | Configuration |
|---|---|---|
| **1 — Group-governed** (recommended) | Enterprise-scale; policy inherited from a group | `environment.environment_group_id = "<group-uuid>"` **and** `managed_environment_enabled = true` |
| **2 — Standalone managed** (good) | Environments governed individually | `managed_environment_enabled = true` (default), `environment.environment_group_id` not set |
| **3 — Unmanaged** (accepted) | No premium governance required | `managed_environment_enabled = false`, no group |

> [!NOTE]
> When `environment.environment_group_id` is set, `managed_environment_enabled` **must** be `true`. The Power Platform requires environments in an environment group to be Managed Environments — this is enforced by a lifecycle precondition. The group's published rule set governs enforcement; env-level managed settings (via `var.managed_environment`) serve as the **initial baseline** and may be overridden or extended by the group rule set.

> [!NOTE]
> For group-governed environments (Tier 1), `var.managed_environment` settings are applied at the env level as a baseline but you typically do not need to customise them — the group's rule set takes precedence. Customising this variable is most relevant for standalone managed environments (Tier 2).

> [!NOTE]
> The `powerplatform_environment_group_rule_set` resource does not support service principal authentication (preview limitation). For automated pipelines using OIDC, the group-governed path still works for environment and managed environment management — only rule-set publishing requires interactive auth.

## Prerequisites

- Power Platform tenant with appropriate licensing (Managed Environments requires Power Platform premium licensing)
- Service principal with Power Platform admin permissions, authenticated via OIDC
- `POWER_PLATFORM_TENANT_ID` and `POWER_PLATFORM_CLIENT_ID` environment variables set
- CI prerequisite for application-admin integration tests: configure `POWER_PLATFORM_TEST_APPLICATION_ADMIN_ID` as a GitHub Actions secret

## Known limitations

- **`Developer` environment type** is not supported — the `microsoft/power-platform` provider cannot create Developer environments using service principal authentication
- **Group membership requires Managed Environment and premium licensing** — when `environment.environment_group_id` is set, `managed_environment_enabled` **must** be `true`; this is a Power Platform platform requirement enforced by a lifecycle precondition. Group-governed environments require qualifying premium licensing for all active users. In unlicensed tenants the `powerplatform_managed_environment` apply will fail — see [Troubleshooting](#troubleshooting) for guidance.
- **Security settings require Managed Environment** — `var.security_settings` is applied only when explicitly set and `managed_environment_enabled = true`; a lifecycle precondition enforces this
- **No `prevent_destroy` guardrail** — this module does not enforce Terraform `lifecycle.prevent_destroy`; use external policy/approval controls if required
- **Tags not supported** — the `powerplatform_environment` resource does not support Azure resource tags
- **Premium licensing required** — Managed Environments require all active users to hold a qualifying premium licence (Power Apps Premium, Power Automate Premium, or Dynamics 365 Enterprise); the Developer Plan does not include this entitlement. Attempting to apply `managed_environment_enabled = true` in an unlicensed tenant can produce `Provider returned invalid result object after apply` errors.
- **Provider >= 4.0.0 required for group-governed environments** — the `microsoft/power-platform` provider had a bug in v3.x ([issue #931](https://github.com/microsoft/terraform-provider-power-platform/issues/931)) where `powerplatform_managed_environment` would panic with a plugin crash when the environment was a member of an Environment Group. This was fixed in **v4.0.0** (December 2025). The `~> 4.0` constraint in this module enforces the minimum required version; verify your **resolved** provider version (check `.terraform.lock.hcl` or run `terraform providers`) rather than just the version constraint text.

## Troubleshooting

### Provider crash or `Provider returned invalid result object` with group-governed managed environments

When using `environment.environment_group_id` with `managed_environment_enabled = true`, you may encounter:

- `Error: Plugin did not respond` / `Provider process exited unexpectedly`
- `Error: Provider returned invalid result object after apply`

These errors **can be caused by** one or more of:

1. **Provider version below v4.0.0** — provider versions before v4.0.0 contain a bug ([issue #931](https://github.com/microsoft/terraform-provider-power-platform/issues/931)) where `powerplatform_managed_environment` crashes during refresh when the environment is a member of an Environment Group. The `~> 4.0` constraint in this module enforces the minimum required version, but verify the **resolved** version:

   ```bash
   cat .terraform.lock.hcl | grep -A2 "microsoft/power-platform"
   # or
   terraform providers
   ```

   If the resolved version is below `4.0.0`, run `terraform init -upgrade`.

2. **Tenant lacks Managed Environment licensing** — Managed Environments require all active users to hold a qualifying premium licence (Power Apps Premium, Power Automate Premium, or Dynamics 365 Enterprise). The Power Platform API may accept the apply but return a malformed or empty state object if the feature is not activated for the tenant.

   Verify licensing in the [Power Platform admin center](https://admin.powerplatform.microsoft.com) or consult your tenant administrator.

### Transient timing issues with Managed Environment + security/firewall settings

Power Platform and provider-side propagation can be eventually consistent right after Managed Environment creation. In some runs, security/firewall application in `powerplatform_environment_settings` may fail transiently even with explicit dependency ordering.

If this occurs:

- Re-run `terraform apply` (most cases succeed on the next run)
- Allow a short wait after initial environment creation before re-applying
- Keep `managed_environment_enabled = true` when using `security_settings`

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->
