terraform{
  required_providers{
  azurerm={
      source="hashicorp/azurerm"
      version=">=3.59.0"#This is the version of Azure Rm module
  }
}
      required_version=">=1.4.0"  #This is the version of Terraform 
}
provider "azurerm" {

    features{}
    skip_provider_registration=true
    client_id=var.client_id
    client_secret=var.client_secret
    subscription_id=var.subscription_id
    tenant_id=var.tenant_id
}
