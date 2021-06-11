# Setting up Azure Virtual Network Gateway (VPN Gateway)

```bash
cd default
terraform init
terraform plan -out tfplan
terraform apply -auto-approve tfplan
```

## Installing Certificates

```bash
cd default
export AZURE_VPN_ID=$(terraform output -raw vpn_id)
export AZURE_VPN_CONFIG_ZIP=`az network vnet-gateway vpn-client generate --ids $AZURE_VPN_ID --processor-architecture Amd64 -o tsv`
export AZURE_VPN_CONFIG_DIR="vpnconfig"
export AZURE_VPN_CONFIG_FILENAME="config.zip"

curl -o $AZURE_VPN_CONFIG_DIR/$AZURE_VPN_CONFIG_FILENAME --create-dirs  $AZURE_VPN_CONFIG_ZIP

unzip -o "$AZURE_VPN_CONFIG_DIR/$AZURE_VPN_CONFIG_FILENAME" -d "$AZURE_VPN_CONFIG_DIR/temp"
```

install the cert at ```$AZURE_VPN_CONFIG_DIR/temp/Generic/VpnServerRoot.cer``` and the client cert at ```certs/clientCert.p12```
VPN Host URI can be found in ```$AZURE_VPN_CONFIG_DIR/temp/Generic/VpnSettings.xml``` under property ```VpnServer```

You can follow these instructions: https://docs.microsoft.com/en-us/azure/vpn-gateway/vpn-gateway-howto-point-to-site-resource-manager-portal


## Force traffic over VPN - Advertise Custom Route 0.0.0.0/0

- P2S VPN
	- Must setup/modify resolver files for DNS to point to a (Custom) DNS server in Azure (Bind9 or Windows Server DC) which will then forward to Azure DNS.
		- Example: hub.raykao.com -> 10.255.0.132 (DNS Server in Azure) -> Forward Resolve to Azure DNS (168.63.129.16))
	- Azure VNET must have the private domain linked to it if using Azure Private DNS Zones for certain services

## Security Issues
- In production you should not include an ```ssh_key``` by default for AKS