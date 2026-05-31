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
> Power Platform's design intent is that environments in an environment group are Managed Environments (`managed_environment_enabled = true`). This module does **not** enforce this as a hard precondition, because the platform allows `managed_environment_enabled = false` for group members at the API level and there are known provider issues that may require this as a temporary workaround (see Known Limitations). Use Tier 1 (group + managed=true) for all production workloads; `managed_environment_enabled = false` with a group is an escape hatch only.

> [!NOTE]
> For group-governed environments (Tier 1), `var.managed_environment` settings are applied at the env level as a baseline but you typically do not need to customise them — the group's rule set takes precedence. Customising this variable is most relevant for standalone managed environments (Tier 2).

> [!NOTE]
> The `powerplatform_environment_group_rule_set` resource does not support service principal authentication (preview limitation). For automated pipelines using OIDC, the group-governed path still works for environment and managed environment management — only rule-set publishing requires interactive auth.

## Prerequisites

- Power Platform tenant with admin permissions
- Service principal with Power Platform admin permissions, authenticated via OIDC
- `POWER_PLATFORM_TENANT_ID` and `POWER_PLATFORM_CLIENT_ID` environment variables set
- CI prerequisite for application-admin integration tests: configure `POWER_PLATFORM_TEST_APPLICATION_ADMIN_ID` as a GitHub Actions secret

## Known limitations

- **`Developer` environment type** is not supported — the `microsoft/power-platform` provider cannot create Developer environments using service principal authentication
- **Security settings require Managed Environment** — `var.security_settings` is applied only when explicitly set and `managed_environment_enabled = true`; a lifecycle precondition enforces this
- **No `prevent_destroy` guardrail** — this module does not enforce Terraform `lifecycle.prevent_destroy`; use external policy/approval controls if required
- **Tags not supported** — the `powerplatform_environment` resource does not support Azure resource tags
- **Premium licensing applies to users, not environment creation** — enabling a Managed Environment does not require any specific license; the admin only needs Power Platform admin permissions. However, all users who actively run apps or flows *inside* a Managed Environment must hold a qualifying premium licence (Power Apps Premium, Power Automate Premium, Dynamics 365 Enterprise, etc.); the Developer Plan does not qualify for active usage. This is a per-user compliance requirement, not an environment-provisioning prerequisite.
- **Provider >= 4.0.0 required** — the `microsoft/power-platform` provider had a bug in v3.x ([issue #931](https://github.com/microsoft/terraform-provider-power-platform/issues/931)) where `powerplatform_managed_environment` would panic with a plugin crash. This was fixed in **v4.0.0** (December 2025). The `~> 4.0` constraint in this module enforces the minimum required version; verify your **resolved** provider version (check `.terraform.lock.hcl`) rather than just the version constraint text.
- **[Known provider issue] Group-governed managed environment attributes may return invalid state (provider v4.1.0)** — When `environment.environment_group_id` is set and `managed_environment_enabled = true`, the `powerplatform_managed_environment` resource may return `Provider returned invalid result object after apply` for multiple attributes (`copilot_*`, `is_group_sharing_disabled`, `limit_sharing_mode`, etc.) with provider v4.1.0. This is a provider issue reported by consumers against v4.1.0, **distinct from #931** (which only fixed the crash; it did not address attribute-level invalid state). Temporary workaround: set `managed_environment_enabled = false` — this avoids creating `powerplatform_managed_environment` but results in an unmanaged group member. Restore `managed_environment_enabled = true` once the provider issue is resolved upstream.
- **[Platform constraint] Environment group with Generative AI Settings blocks environment creation** — If the target environment group has Generative AI Settings configured at the group level, the `powerplatform_environment` resource returns `GenerativeAISettingsUpdateInvalid` (HTTP 400) when `environment_group_id` is set. This is a platform constraint: per-environment Generative AI settings cannot be independently modified for environments in a group that manages those settings. This is **not** bypassed by `managed_environment_enabled = false` — it affects the base environment resource regardless. Workaround: use an environment group that does not have Generative AI settings configured, or remove `environment_group_id`.

## Troubleshooting

### Failure mode A — Provider crash with group-governed environments (fixed in v4.0.0)

In provider versions before v4.0.0, `powerplatform_managed_environment` would panic during refresh when the environment was a member of an Environment Group:

- `Error: Plugin did not respond` / `Provider process exited unexpectedly`

This was a nil-pointer bug ([issue #931](https://github.com/microsoft/terraform-provider-power-platform/issues/931)), confirmed fixed in **v4.0.0** (December 2025). The `~> 4.0` constraint enforces the minimum version. If you see this error, check the resolved version in `.terraform.lock.hcl`:

```bash
cat .terraform.lock.hcl | grep -A2 "microsoft/power-platform"
```

If below `4.0.0`, run `terraform init -upgrade`.

> [!NOTE]
> This fix is **scoped to the crash only**. It does not resolve other group-related provider issues (failure modes B and C below).

### Failure mode B — `GenerativeAISettingsUpdateInvalid` HTTP 400 on environment creation

When `environment.environment_group_id` is set and the target group has Generative AI Settings configured at the group level, the `powerplatform_environment` resource may return:

```
Error: GenerativeAISettingsUpdateInvalid
Can not update Generative AI Settings for environments in an environment group with Generative AI Settings.
```

This is a **platform constraint** on the base environment resource. It is **not** caused by `managed_environment_enabled` and is **not** bypassed by setting `managed_environment_enabled = false`. Resolution:

- Use an environment group that does not have Generative AI Settings configured at the group level, or
- Remove `environment_group_id` from the environment configuration

### Failure mode C — `Provider returned invalid result object` for managed environment attributes

When `environment.environment_group_id` is set and `managed_environment_enabled = true`, you may encounter:

```
Error: Provider returned invalid result object after apply
```

for attributes such as `copilot_*`, `is_group_sharing_disabled`, `limit_sharing_mode`, `max_limit_user_sharing`, etc. This is a provider issue reported by consumers against v4.1.0, **distinct from #931** — the crash was fixed in v4.0.0, but attribute-level invalid state for group-managed environments is a separate unresolved issue.

Temporary workaround: set `managed_environment_enabled = false`. This prevents `powerplatform_managed_environment` from being created and avoids the invalid result, but leaves the environment as an unmanaged group member. Note that:

- `managed_environment_enabled = false` with a group is **technically permitted** by the platform API but is **not the intended configuration**
- `security_settings` will not be applied when `managed_environment_enabled = false`
- Restore `managed_environment_enabled = true` once the provider issue is resolved upstream

### Transient timing issues with Managed Environment + security/firewall settings

Power Platform and provider-side propagation can be eventually consistent right after Managed Environment creation. In some runs, security/firewall application in `powerplatform_environment_settings` may fail transiently even with explicit dependency ordering.

If this occurs:

- Re-run `terraform apply` (most cases succeed on the next run)
- Allow a short wait after initial environment creation before re-applying
- Keep `managed_environment_enabled = true` when using `security_settings`

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->
