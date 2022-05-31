#!/bin/bash

# VARIABLES
mgmtrg='avnm-mgmt'
eastrg='avnm-east'
westrg='avnm-west'
mgmtloc='eastus'
hubeastloc='eastus'
hubwestloc='westus2'

# create resource groups for AVNM Management resource + hub east and hub west
az group create -g $mgmtrg -l $mgmtloc -o none
az group create -g $eastrg -l $hubeastloc -o none
az group create -g $westrg -l $hubwestloc -o none

# deploy hub east
# hub Vnet
echo '['$(date +"%T")'] Create East Hub Virtual Network:'
az network vnet create --address-prefixes 10.100.0.0/16 -n eastHubVnet -g $eastrg --subnet-name subnet1 --subnet-prefixes 10.100.0.0/24 -o none
az network vnet subnet create -g $eastrg --vnet-name eastHubVnet -n GatewaySubnet --address-prefixes 10.100.200.0/26 -o none
# ER Gateway
echo '['$(date +"%T")'] Create East Hub ER Gateway (no-wait):'
az network public-ip create -g $eastrg -n eastHubGW-pip --sku Standard -o none --only-show-errors
az network vnet-gateway create -g $eastrg -n eastHubGW --public-ip-address eastHubGW-pip --vnet eastHubVnet --gateway-type ExpressRoute --sku ERGw1Az  -o none --no-wait
# spokes
echo '['$(date +"%T")'] Create Spokes 1 and 2:'
az network vnet create --address-prefixes 10.1.0.0/16 -n eastSpoke1 -g $eastrg --subnet-name subnet1 --subnet-prefixes 10.1.0.0/24 -o none
az network vnet create --address-prefixes 10.2.0.0/16 -n eastSpoke2 -g $eastrg --subnet-name subnet1 --subnet-prefixes 10.2.0.0/24 -o none

# note there is no peering configuration here

# deploy hub west
# hub Vnet
echo '['$(date +"%T")'] Create West Hub Virtual Network:'
az network vnet create --address-prefixes 10.101.0.0/16 -n westHubVnet -g $westrg --subnet-name subnet1 --subnet-prefixes 10.101.0.0/24 -o none
az network vnet subnet create -g $westrg --vnet-name westHubVnet -n GatewaySubnet --address-prefixes 10.101.200.0/26 -o none
# ER Gateway
echo '['$(date +"%T")'] Create West Hub ER Gateway:'
az network public-ip create -g $westrg -n westHubGW-pip --sku Standard  -o none --only-show-errors
az network vnet-gateway create -g $westrg -n westHubGW --public-ip-address westHubGW-pip --vnet westHubVnet --gateway-type ExpressRoute --sku ERGw1Az -o none
# spokes
echo '['$(date +"%T")'] Create Spokes 1 and 2:'
az network vnet create --address-prefixes 10.3.0.0/16 -n westSpoke1 -g $westrg --subnet-name subnet1 --subnet-prefixes 10.3.0.0/24 -o none
az network vnet create --address-prefixes 10.4.0.0/16 -n westSpoke2 -g $westrg --subnet-name subnet1 --subnet-prefixes 10.4.0.0/24 -o none

# note there is no peering configuration here

# Create some VM's
#
echo '['$(date +"%T")'] Creating Virtual Machines: easthubVM'
az vm create -n easthubVM -g $eastrg --image ubuntults --public-ip-sku Standard --size Standard_D2S_v3 --subnet subnet1 --vnet-name eastHubVnet --authentication-type ssh --admin-username azureuser --ssh-key-values @~/.ssh/id_rsa.pub -o none --only-show-errors
echo '['$(date +"%T")'] Creating Virtual Machines: eastspoke1VM'
az vm create -n eastspoke1VM -g $eastrg --image ubuntults --public-ip-sku Standard --size Standard_D2S_v3 --subnet subnet1 --vnet-name eastSpoke1 --authentication-type ssh --admin-username azureuser --ssh-key-values @~/.ssh/id_rsa.pub -o none --only-show-errors
echo '['$(date +"%T")'] Creating Virtual Machines: eastspoke2VM'
az vm create -n eastspoke2VM -g $eastrg --image ubuntults --public-ip-sku Standard --size Standard_D2S_v3 --subnet subnet1 --vnet-name eastSpoke2 --authentication-type ssh --admin-username azureuser --ssh-key-values @~/.ssh/id_rsa.pub -o none --only-show-errors
echo '['$(date +"%T")'] Creating Virtual Machines: westhubVM'
az vm create -n westhubVM -g $westrg --image ubuntults --public-ip-sku Standard --size Standard_D2S_v3 --subnet subnet1 --vnet-name westHubVnet --authentication-type ssh --admin-username azureuser --ssh-key-values @~/.ssh/id_rsa.pub -o none --only-show-errors
echo '['$(date +"%T")'] Creating Virtual Machines: westspoke1VM'
az vm create -n westspoke1VM -g $westrg --image ubuntults --public-ip-sku Standard --size Standard_D2S_v3 --subnet subnet1 --vnet-name westSpoke1 --authentication-type ssh --admin-username azureuser --ssh-key-values @~/.ssh/id_rsa.pub -o none --only-show-errors
echo '['$(date +"%T")'] Creating Virtual Machines: westspoke2VM'
az vm create -n westspoke2VM -g $westrg --image ubuntults --public-ip-sku Standard --size Standard_D2S_v3 --subnet subnet1 --vnet-name westSpoke1 --authentication-type ssh --admin-username azureuser --ssh-key-values @~/.ssh/id_rsa.pub -o none --only-show-errors

# update NSGs to allow public access for port 22 on your IP only
echo '['$(date +"%T")'] Updating NSG rule for public port 22 on easthubVM'
mypip=$(curl -4 ifconfig.io -s)
az network nsg rule update -g $eastrg --nsg-name easthubVM'NSG' -n 'default-allow-ssh' --source-address-prefixes $mypip -o none
echo '['$(date +"%T")'] Updating NSG rule for public port 22 on eastspoke1VM'
az network nsg rule update -g $eastrg --nsg-name eastspoke1VM'NSG' -n 'default-allow-ssh' --source-address-prefixes $mypip -o none
echo '['$(date +"%T")'] Updating NSG rule for public port 22 on eastspoke2VM'
az network nsg rule update -g $eastrg --nsg-name eastspoke2VM'NSG' -n 'default-allow-ssh' --source-address-prefixes $mypip -o none
echo '['$(date +"%T")'] Updating NSG rule for public port 22 on westhubVM'
az network nsg rule update -g $westrg --nsg-name westhubVM'NSG' -n 'default-allow-ssh' --source-address-prefixes $mypip -o none
echo '['$(date +"%T")'] Updating NSG rule for public port 22 on westspoke1VM'
az network nsg rule update -g $westrg --nsg-name westspoke1VM'NSG' -n 'default-allow-ssh' --source-address-prefixes $mypip -o none
echo '['$(date +"%T")'] Updating NSG rule for public port 22 on westspoke2VM'
az network nsg rule update -g $westrg --nsg-name westspoke2VM'NSG' -n 'default-allow-ssh' --source-address-prefixes $mypip -o none

# Create Azure Virtual Network Manager
#
echo '['$(date +"%T")'] Create Network Manager:'
subid=$(az account show --query 'id' -o tsv)
az network manager create --name "avnm-mgmt" \
    --location $mgmtloc \
    --description "Network Manager for MS-Connectivity Subscription" \
    --display-name "AVNM Mgmt" \
    --scope-accesses "SecurityAdmin" "Connectivity" \
    --network-manager-scopes subscriptions="/subscriptions/$subid" \
    --resource-group $mgmtrg \
    --output none

# Create a management group for the east hub
echo '['$(date +"%T")'] Create Management Group EastHub:'
az network manager group create --name "eastSpokeGroup" \
    --network-manager-name "avnm-mgmt" \
    --description "east group" \
    --display-name "East Spoke Group" \
    --member-type "Microsoft.Network/virtualNetworks" \
    --resource-group $mgmtrg \
    --output none

# Create the static members
echo '['$(date +"%T")'] Create Static Member Spoke1:'
spoke1id=$(az network vnet show -g $eastrg -n eastSpoke1 --query id -o tsv)
az network manager group static-member create --network-group-name "eastSpokeGroup" \
    --network-manager-name "avnm-mgmt" \
    --resource-group $mgmtrg \
    --static-member-name "eastspoke1" \
    --resource-id=$spoke1id \
    --output none

echo '['$(date +"%T")'] Create Static Member Spoke2:'
spoke2id=$(az network vnet show -g $eastrg -n eastSpoke2 --query id -o tsv)
az network manager group static-member create --network-group-name "eastSpokeGroup" \
    --network-manager-name "avnm-mgmt" \
    --resource-group $mgmtrg \
    --static-member-name "eastspoke2" \
    --resource-id=$spoke2id \
    --output none

# Create a management group for west hub
echo '['$(date +"%T")'] Create Management Group WestHub:'
az network manager group create --name "westSpokeGroup" \
    --network-manager-name "avnm-mgmt" \
    --description "west group" \
    --display-name "West Spoke Group" \
    --member-type "Microsoft.Network/virtualNetworks" \
    --resource-group $mgmtrg \
    --output none

echo '['$(date +"%T")'] Create Static Member Spoke1:'
spoke1id=$(az network vnet show -g $westrg -n westSpoke1 --query id -o tsv)
az network manager group static-member create --network-group-name "westSpokeGroup" \
    --network-manager-name "avnm-mgmt" \
    --resource-group $mgmtrg \
    --static-member-name "westspoke1" \
    --resource-id=$spoke1id \
    --output none

echo '['$(date +"%T")'] Create Static Member Spoke2:'
spoke2id=$(az network vnet show -g $westrg -n westSpoke2 --query id -o tsv)
az network manager group static-member create --network-group-name "westSpokeGroup" \
    --network-manager-name "avnm-mgmt" \
    --resource-group $mgmtrg \
    --static-member-name "westspoke2" \
    --resource-id=$spoke2id \
    --output none

# Create configuration for east hub
echo '['$(date +"%T")'] Create Confifguration for East Hub:'
hubVnetid=$(az network vnet show -g $eastrg -n eastHubVnet --query 'id' -o tsv)
groupid=$(az network manager group show --network-group-name "eastSpokeGroup" --network-manager-name "avnm-mgmt" --resource-group $mgmtrg --query 'id' -o tsv)
az network manager connect-config create --configuration-name "eastSpokeConnectivityConfig" \
    --description "Test configuration for any-any" \
    --applies-to-groups group-Connectivity=DirectlyConnected network-group-id=$groupid use-hub-gateway=true \
    --connectivity-topology "HubAndSpoke" \
    --delete-existing-peering true \
    --display-name "East Hub Connectivity" \
    --hub resource-id=$hubVnetid resource-type="Microsoft.Network/virtualNetworks" \
    --network-manager-name "avnm-mgmt" \
    --resource-group $mgmtrg \
    --output none

# Create configuration for west hub
echo '['$(date +"%T")'] Create Confifguration for West Hub:'
hubVnetid=$(az network vnet show -g $westrg -n westHubVnet --query 'id' -o tsv)
groupid=$(az network manager group show --network-group-name "westSpokeGroup" --network-manager-name "avnm-mgmt" --resource-group $mgmtrg --query 'id' -o tsv)
az network manager connect-config create --configuration-name "westSpokeConnectivityConfig" \
    --description "Test configuration for any-any" \
    --applies-to-groups group-Connectivity=DirectlyConnected network-group-id=$groupid use-hub-gateway=true \
    --connectivity-topology "HubAndSpoke" \
    --delete-existing-peering true \
    --display-name "West Hub Connectivity" \
    --hub resource-id=$hubVnetid resource-type="Microsoft.Network/virtualNetworks" \
    --network-manager-name "avnm-mgmt" \
    --resource-group $mgmtrg \
    --output none

# Deploy east hub configuration. Note that an Azure CLI command is not available for this, using REST API
echo '['$(date +"%T")'] Posting Commit via REST API for east hub:'
conf=$(az network manager connect-config show --configuration-name 'eastSpokeConnectivityConfig' -g $mgmtrg -n avnm-mgmt --query 'id' -o tsv)
subid=$(az account show --query 'id' -o tsv)
url='https://management.azure.com/subscriptions/'$subid'/resourceGroups/'$mgmtrg'/providers/Microsoft.Network/networkManagers/avnm-mgmt/commit?api-version=2021-02-01-preview'
json='{
  "targetLocations": [
    "'$hubeastloc'"
  ],
  "configurationIds": [
    "'$conf'"
  ],
  "commitType": "Connectivity"
}'

az rest --method POST \
    --url $url \
    --body "$json" \
    --output none

# Deploy west hub configuration. Note that an Azure CLI command is not available for this, using REST API
echo '['$(date +"%T")'] Posting Commit via REST API for west hub:'
conf=$(az network manager connect-config show --configuration-name 'westSpokeConnectivityConfig' -g $mgmtrg -n avnm-mgmt --query 'id' -o tsv)
url='https://management.azure.com/subscriptions/'$subid'/resourceGroups/'$mgmtrg'/providers/Microsoft.Network/networkManagers/avnm-mgmt/commit?api-version=2021-02-01-preview'
json='{
  "targetLocations": [
    "'$hubwestloc'"
  ],
  "configurationIds": [
    "'$conf'"
  ],
  "commitType": "Connectivity"
}'

az rest --method POST \
    --url $url \
    --body "$json" \
    --output none

# check deployment status
echo '['$(date +"%T")'] Get Deployment Status:'
az network manager list-deploy-status --network-manager-name "avnm-mgmt" --deployment-types "Connectivity" --regions $hubeastloc $hubwestloc --resource-group $mgmtrg
