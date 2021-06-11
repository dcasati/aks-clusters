resource "azurerm_route_table" "default" {
  depends_on = [
    module.firewall
  ]

  name                = "defaultRouteTable"
  location            = azurerm_resource_group.default.location
  resource_group_name = azurerm_resource_group.default.name
}

resource "azurerm_route" "default" {
  name                   = "defaultRoute"
  resource_group_name    = azurerm_resource_group.default.name
  route_table_name       = azurerm_route_table.default.name
  address_prefix         = "0.0.0.0/0"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = module.firewall.ip_address
}

resource "azurerm_subnet_route_table_association" "jumpbox" {
  subnet_id      = azurerm_subnet.jumpbox.id
  route_table_id = azurerm_route_table.default.id
}

resource "azurerm_subnet_route_table_association" "dnsForwarder" {
  subnet_id      = azurerm_subnet.dnsForwarder.id
  route_table_id = azurerm_route_table.default.id
}

# spokes
#

# spoke-1
resource "azurerm_route_table" "aks-1-rt" {
  depends_on = [
    module.firewall
  ]

  name                = "aks1RouteTable"
  location            = azurerm_resource_group.default.location
  resource_group_name = azurerm_resource_group.default.name
}

resource "azurerm_subnet_route_table_association" "aks-1" {
  subnet_id      = azurerm_subnet.aks-1-cluster.id
  route_table_id = azurerm_route_table.aks-1-rt.id
}

resource "azurerm_route" "defaultRtSpoke1" {
  name                   = "defaultRoute"
  resource_group_name    = azurerm_resource_group.default.name
  route_table_name       = azurerm_route_table.aks-1-rt.name
  address_prefix         = "0.0.0.0/0"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = module.firewall.ip_address
}

# spoke-2
resource "azurerm_route_table" "aks-2-rt" {
  depends_on = [
    module.firewall
  ]

  name                = "aks2RouteTable"
  location            = azurerm_resource_group.default.location
  resource_group_name = azurerm_resource_group.default.name
}

resource "azurerm_subnet_route_table_association" "aks-2" {
  subnet_id      = azurerm_subnet.aks-2-cluster.id
  route_table_id = azurerm_route_table.aks-2-rt.id
}

resource "azurerm_route" "defaultRtSpoke2" {
  name                   = "defaultRoute"
  resource_group_name    = azurerm_resource_group.default.name
  route_table_name       = azurerm_route_table.aks-2-rt.name
  address_prefix         = "0.0.0.0/0"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = module.firewall.ip_address
}

