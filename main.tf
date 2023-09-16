resource "azurerm_resource_group" "rgmcti" {
  name      = var.resource_group_name
  location  = var.location
  tags      = var.tags
}

resource "random_string" "fqdn" {
  length    =  6
  special   =  false
  upper     =  false
  number    =  false

}

resource "azurerm_virtual_network" "vnetmcti" {
    name                    =   "vnet-${convention}"
    address_space           =   ["10.0.0.0/16"]
    location                =   azurerm_resource_group.rgmcti.location
    resource_group_name     =   azurerm_resource_group.rgmcti.name
    tags                    =   var.tags
}

resource "azurerm_subnet" "snetinternal" {
  name                 = "snet-internal-${convention}"
  address_prefixes     = ["10.0.2.0/24"]
  resource_group_name  = azurerm_resource_group.rgmcti.name
  virtual_network_name = azurerm_virtual_network.vnetmcti.name
}

resource "azurerm_public_ip" "pipmcti" {
 name                         = "pip-${convention}"
 location                     = azurerm_resource_group.rgmcti.location
 allocation_method            = "Static"
 domain_name_label            = random_string.fqdn.result
 resource_group_name          = azurerm_resource_group.rgmcti.name
 tags                         = var.tags
}

resource "azurerm_lb" "lbemcti" {
  name                = "lbe-${convention}"
  location            = azurerm_resource_group.rgmcti.location
  resource_group_name = azurerm_resource_group.rgmcti.name

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.pipmcti.id
  }

  tags = var.tags
}

resource "azurerm_lb_backend_address_pool" "bkaddpool" {
  loadbalancer_id     = azurerm_lb.lbemcti.id
  name                = "bkaddpool-${convention}"
}

resource "azurerm_lb_probe" "lbprobe" {
  resource_group_name = azurerm_resource_group.rgmcti.name
  loadbalancer_id     = azurerm_lb.lbemcti.id
  name                = "ssh-running-probe"
  port                = var.application_port
}

resource "azurerm_lb_rule" "lbnatrule" {
   resource_group_name            = azurerm_resource_group.rgmcti.name
   loadbalancer_id                = azurerm_lb.lbemcti.id
   name                           = "http"
   protocol                       = "Tcp"
   frontend_port                  = var.application_port
   backend_port                   = var.application_port
   backend_address_pool_id        = azurerm_lb_backend_address_pool.bkaddpool.id
   frontend_ip_configuration_name = "PublicIPAddress"
   probe_id                       = azurerm_lb_probe.lbprobe.id
}


resource "azurerm_virtual_machine_scale_set" "vmss" {
  name                = "vmss-${convention}"
  location            = var.location
  resource_group_name = azurerm_resource_group.rgmcti.name
  upgrade_policy_mode = "Manual"

  ## SKU block - Stock Keeping Unit
  sku {
    name     = "Standard_DS1_v2"
    tier     = "Standard"
    capacity = 2
  }

  storage_profile_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  storage_profile_os_disk {
    name              = ""
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  storage_profile_data_disk {
    lun          = 0
    caching        = "ReadWrite"
    create_option  = "Empty"
    disk_size_gb   = 10
 }

  os_profile {
    computer_name_prefix = "vmlab"
    admin_username       = var.admin_user
    admin_password       = var.admin_password
    custom_data          = file("web.conf")
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  network_profile {
    name    = "terraformnetworkprofile"
    primary = true

    ip_configuration {
      name                                   = "IPConfiguration"
      subnet_id                              = azurerm_subnet.snetinternal.id
      load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.bkaddpool.id]
      primary = true
    }
  }

  tags = var.tags
}

resource "azurerm_public_ip" "jumpbox" {
  name                         = "jumpbox-${convention}"
  location                     = azurerm_resource_group.rgmcti.location
  resource_group_name          = azurerm_resource_group.rgmcti.name
  allocation_method            = "Static"
  domain_name_label            = "${random_string.fqdn.result}-ssh"
  tags                         = var.tags
}

resource "azurerm_network_interface" "jumpbox" {
  name                = "jumpbox-nic"
  location            = azurerm_resource_group.rgmcti.location
  resource_group_name = azurerm_resource_group.rgmcti.name

  ip_configuration {
    name                          = "IPConfiguration"
    subnet_id                     = azurerm_subnet.snetinternal.id
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = azurerm_public_ip.jumpbox.id
  }

  tags = var.tags
}

resource "azurerm_virtual_machine" "jumpbox" {
  name                  = "jumpbox"
  location              = azurerm_resource_group.rgmcti.location
  resource_group_name   = azurerm_resource_group.rgmcti.name
  network_interface_ids = [azurerm_network_interface.jumpbox.id]
  vm_size               = "Standard_DS1_v2"

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "jumpbox-osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "jumpbox"
    admin_username = var.admin_user
    admin_password = var.admin_password
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  tags = var.tags
}
