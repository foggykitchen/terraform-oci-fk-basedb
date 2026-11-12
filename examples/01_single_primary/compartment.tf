module "compartment" {
  source                = "git::https://github.com/foggykitchen/terraform-oci-fk-compartment.git?ref=v0.1.1"
  providers             = { oci = oci.home }
  parent_compartment_id = var.parent_compartment_id
  name                  = var.name_prefix
  description           = "FoggyKitchen BaseDB end-to-end example"
  enable_delete         = false
}
