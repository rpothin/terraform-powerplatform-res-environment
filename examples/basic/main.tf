# TODO (before publishing): Replace the source path below with the Terraform Registry
# address once the module is published, e.g.:
#   source  = "rpothin/<module-name>/powerplatform"
#   version = "~> 0.1"
# See: https://developer.hashicorp.com/terraform/language/modules/develop/structure#examples
module "environment" {
  source = "../../" # local path for development — update to registry address before publishing

  environment = {
    display_name = var.display_name
    location     = var.location
  }

  dataverse = {
    currency_code     = var.dataverse_currency_code
    security_group_id = var.dataverse_security_group_id
  }
}
