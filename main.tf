terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=5.0.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "terraform_resource_group" {
  name     = "terraform_resource_group"
  location = "East US "
}

# Create a virtual network within the resource group
resource "azurerm_virtual_network" "terraform_vnet" {
  name                = "terraform_vnet"
  resource_group_name = azurerm_resource_group.terraform_resource_group.name
  location            = azurerm_resource_group.terraform_resource_group.location
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "terraform_subnet" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.terraform_resource_group.name
  virtual_network_name = azurerm_virtual_network.terraform_vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_network_interface" "terraform_nic" {
  name                = "terraform_nic"
  location            = azurerm_resource_group.terraform_resource_group.location
  resource_group_name = azurerm_resource_group.terraform_resource_group.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.terraform_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "terraform_vm" {
  name                = "terraform_vm"
  resource_group_name = azurerm_resource_group.terraform_resource_group.name
  location            = azurerm_resource_group.terraform_resource_group.location
  size                = "Standard_D4_v5"
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.terraform_nic.id,
  ]

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}
