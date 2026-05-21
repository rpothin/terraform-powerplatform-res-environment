module "environment" {
  source  = "rpothin/res-environment/powerplatform"

  environment = {
    display_name = var.display_name
    location     = var.location
  }
}
