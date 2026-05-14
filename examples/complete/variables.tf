variable "application_admin_id" {
  default     = null
  description = "Azure AD application ID of the service principal to assign as System Administrator."
  type        = string
}

variable "dataverse_currency_code" {
  default     = "USD"
  description = "ISO 4217 currency code for the Dataverse database."
  type        = string
}

variable "dataverse_language_code" {
  default     = 1033
  description = "LCID language code for the Dataverse database (1033 = English)."
  type        = number
}

variable "dataverse_security_group_id" {
  description = "Azure AD security group UUID for Dataverse access control."
  type        = string
}

variable "description" {
  default     = null
  description = "Optional description for the environment."
  type        = string
}

variable "display_name" {
  description = "The display name for the Power Platform environment."
  type        = string
}

variable "environment_type" {
  default     = "Sandbox"
  description = "Type of environment: Sandbox, Production, or Trial."
  type        = string
}

variable "location" {
  description = "The geographic location for the Power Platform environment."
  type        = string
}

variable "managed_environment_enabled" {
  default     = true
  description = "Whether to enable Managed Environment governance features."
  type        = bool
}
