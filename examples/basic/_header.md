# Basic Example — Power Platform Environment

This example demonstrates the minimal configuration required to create a Power Platform environment using this module.

Only `environment.display_name` and `environment.location` are required. All other settings — including Dataverse provisioning — use secure module defaults.

It creates:
- A Sandbox environment in the specified region with a Dataverse database (USD currency, no security group restriction — override via `dataverse = { ... }`)
- A Managed Environment (enabled by default for governance)
- Environment settings with secure, zero-trust defaults

To skip Dataverse provisioning entirely, pass `dataverse = null` and set `managed_environment_enabled = false`.

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->
