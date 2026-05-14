locals {
  final_domain = var.dataverse != null ? coalesce(
    var.dataverse.domain,
    replace(
      replace(
        substr(replace(lower(var.environment.display_name), "/[^a-z0-9]+/", "-"), 0, 63),
        "/^-+/",
        ""
      ),
      "/-+$/",
      ""
    )
  ) : null
}
