output "environment_id" {
  description = "The unique identifier (GUID) of the Power Platform environment."
  value       = module.environment.environment_id
}

output "environment_display_name" {
  description = "The display name of the Power Platform environment."
  value       = module.environment.environment_display_name
}

output "environment_url" {
  description = "The Dataverse URL of the Power Platform environment."
  value       = module.environment.environment_url
}

output "dataverse_organization_id" {
  description = "The Dataverse organization ID of the environment."
  value       = module.environment.dataverse_organization_id
}
