variable "display_name" {
  description = "The display name for the Power Platform environment."
  type        = string
}

variable "location" {
  description = "The geographic location for the Power Platform environment (e.g., 'unitedstates', 'europe')."
  type        = string
}

variable "dataverse_currency_code" {
  description = "ISO 4217 currency code for the Dataverse database (e.g., 'USD', 'EUR', 'GBP')."
  type        = string
}

variable "dataverse_security_group_id" {
  description = "Azure AD security group UUID controlling access to the Dataverse database. Use '00000000-0000-0000-0000-000000000000' for no group restriction."
  type        = string
}
