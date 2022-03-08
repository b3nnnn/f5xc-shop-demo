terraform {
  required_version = ">= 0.15"
  required_providers {
    volterra = {
      source = "volterraedge/volterra"
      version = "0.11.3"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.7.0"
    }
  }
}

provider "volterra" {
  api_p12_file = "./cred.p12"
  url          = var.api_url
}

provider "kubectl" {
  alias                  = "app"
  host                   = module.f5xc.app_kubecfg_host
  cluster_ca_certificate = base64decode(module.f5xc.app_kubecfg_cluster_ca)
  client_certificate     = base64decode(module.f5xc.app_kubecfg_client_cert)
  client_key             = base64decode(module.f5xc.app_kubecfg_client_key)
  load_config_file       = false
  apply_retry_count      = 10
}

provider "kubectl" {
  alias                  = "utility"
  host                   = module.f5xc.utility_kubecfg_host
  cluster_ca_certificate = base64decode(module.f5xc.utility_kubecfg_cluster_ca)
  client_certificate     = base64decode(module.f5xc.utility_kubecfg_client_cert)
  client_key             = base64decode(module.f5xc.utility_kubecfg_client_key)
  load_config_file       = false
  apply_retry_count      = 10
}

module "f5xc" {
  source = "./module/f5xc"

  api_url = var.api_url
  base = var.base
  app_fqdn = var.app_fqdn
  spoke_site_selector = var.spoke_site_selector
  hub_site_selector = var.hub_site_selector
  utility_site_selector = var.utility_site_selector
  cred_expiry_days = var.cred_expiry_days
  bot_defense_region = var.bot_defense_region
}
 
module "virtualk8s" {
  source = "./module/virtualk8s"
  providers = {
    kubectl.app     = kubectl.app
    kubectl.utility = kubectl.utility
  }
  depends_on = [
    module.f5xc.app_vk8s,
    module.f5xc.utility_vk8s
  ]
 
  reg_server = var.registry_server
  reg_password_b64 = var.registry_password
  reg_server_b64 = base64encode(var.registry_server)
  reg_username_b64 = base64encode(var.registry_username)

  app_namespace = module.f5xc.app_namespace
  utility_namespace = module.f5xc.utility_namespace
  spoke_vsite = module.f5xc.spoke_vsite
  hub_vsite = module.f5xc.hub_vsite
  utility_vsite = module.f5xc.utility_vsite
  target_url = module.f5xc.app_url

  tenant_js_ref = var.tenant_js_ref
}