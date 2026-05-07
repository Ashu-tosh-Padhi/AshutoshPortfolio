terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.63.0"
    }
  }
}

provider "azurerm" {
  features {}
}

data "azurerm_resource_group" "rg" {
  name = "TINXSYS-MGMT-RG"
}

data "azurerm_virtual_network" "vnet" {
  name                = "TINXSYS-MGMT-Vnet"
  resource_group_name = data.azurerm_resource_group.rg.name
}

data "azurerm_subnet" "subnet" {
  name                 = "TINXSYS-MGMT-OpsGW-Subnet"
  virtual_network_name = data.azurerm_virtual_network.vnet.name
  resource_group_name  = data.azurerm_resource_group.rg.name
}

data "azurerm_network_security_group" "nsg" {
  name                = "VistaraNSG"
  resource_group_name = data.azurerm_resource_group.rg.name
}

data "azurerm_storage_account" "diag" {
  name                = "tinxsysmgmtrgdiag"
  resource_group_name = data.azurerm_resource_group.rg.name
}

################Networking######################################

resource "azurerm_network_interface" "nic" {
  name                = "TINXSYS-MGMT-MEGW-nic"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "primary"
    subnet_id                     = data.azurerm_subnet.subnet.id
    private_ip_address_allocation = "Static"
  }
}

resource "azurerm_network_interface_security_group_association" "nic_nsg" {
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = data.azurerm_network_security_group.nsg.id
}

#############################VM#############################

resource "azurerm_linux_virtual_machine" "vm" {
  name                = "TINXSYS-MGMT-MEGW"
  computer_name       = "TINXSYS-MGMT-MEGW"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  size                = "Standard_D2s_v3"

  network_interface_ids = [azurerm_network_interface.nic.id]

  admin_username                  = "cosysadmin"
  admin_password                  = "We!c0me@123#"
  disable_password_authentication = false

  os_disk {
    name                 = "TINXSYS-MGMT-MEGW_OsDisk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS" # Standard HDD LRS
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }

  boot_diagnostics {
    storage_account_uri = data.azurerm_storage_account.diag.primary_blob_endpoint
  }
}

#############################Data Disk#############################

resource "azurerm_managed_disk" "data0" {
  name                 = "TINXSYS-MGMT-MEGW_DataDisk_0"
  location             = data.azurerm_resource_group.rg.location
  resource_group_name  = data.azurerm_resource_group.rg.name
  storage_account_type = "Premium_LRS" # Premium SSD LRS
  create_option        = "Empty"
  disk_size_gb         = 128
}

resource "azurerm_virtual_machine_data_disk_attachment" "attach0" {
  managed_disk_id    = azurerm_managed_disk.data0.id
  virtual_machine_id = azurerm_linux_virtual_machine.vm.id
  lun                = 0
  caching            = "ReadWrite"
}
