module "environment" {
  source  = "rpothin/res-environment/powerplatform"
  version = "~> 0.1"

  environment = {
    display_name = var.display_name
    location     = var.location
  }
}
