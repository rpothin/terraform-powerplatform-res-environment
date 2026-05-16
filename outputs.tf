output "dataverse_organization_id" {
  description = "The Dataverse organization ID of the environment. Null if no Dataverse database was provisioned."
  value       = try(powerplatform_environment.this.dataverse.organization_id, null)
}

output "environment_display_name" {
  description = "The display name of the Power Platform environment."
  value       = powerplatform_environment.this.display_name
}

output "environment_id" {
  description = "The unique identifier (GUID) of the Power Platform environment."
  value       = powerplatform_environment.this.id
}

output "environment_url" {
  description = "The Dataverse URL of the Power Platform environment. Null if no Dataverse database was provisioned."
  value       = try(powerplatform_environment.this.dataverse.url, null)
}

output "managed_environment_id" {
  description = "The identifier of the Managed Environment resource. Null if managed environment is disabled."
  value       = try(powerplatform_managed_environment.this[0].id, null)
}

