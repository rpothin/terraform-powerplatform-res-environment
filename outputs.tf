# TODO: Replace these placeholder outputs with actual resource attributes.

output "resource_id" {
  description = "The ID of the managed resource."
  value       = null # Replace with actual resource ID, e.g., powerplatform_environment.this.id
}

output "display_name" {
  description = "The display name of the Power Platform environment."
  value       = var.environment.display_name
}
