#!/bin/bash

echo "Starting Azure deployment script..."

subscription=""
resourceGroupName=""
location=""
templateFile="azuredeploy.json" # Default template file path
deploymentName="blanktemplate" # Default deployment name

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --s) subscription="$2"; echo "Subscription set to $subscription"; shift ;;
        --rg) resourceGroupName="$2"; echo "Resource group set to $resourceGroupName"; shift ;;
        --l) location="$2"; echo "Location set to $location"; shift ;;
        --arm-path) templateFile="$2"; echo "Template file path set to $templateFile"; shift ;;
        --deployment-name) deploymentName="$2"; echo "Deployment name set to $deploymentName"; shift ;;
        *) echo "Unknown parameter: $1"; exit 1 ;;
    esac
    shift
done

if [ -n "$ACC_CLOUD" ]; then
    echo "Running in Azure Cloud Shell."
else
    echo "Not running in Azure Cloud Shell."
fi

if [[ -n "$subscription" ]]; then
    echo "Setting subscription to $subscription..."
    az account set --subscription "$subscription"
else
    subscription=$(az account show --query id -o tsv)
    echo "Using current Azure subscription ID: $subscription"
fi

if [[ -z "$resourceGroupName" ]]; then
    resourceGroupName="rg$(date +%Y%m%d%H%M%S)"
    echo "Resource group name not provided. Generated resource group name: $resourceGroupName"

    if [[ -z "$location" ]]; then
        echo "Fetching first available location..."
        location=$(az account list-locations --query "[0].name" -o tsv)
        echo "Location set to $location (first available location)"
    fi

    echo "Creating resource group $resourceGroupName in $location..."
    az group create --name "$resourceGroupName" --location "$location"

fi



if [[ ! -f "$templateFile" ]]; then
    echo "Template file $templateFile not found. Creating a default ARM template..."
    cat > "$templateFile" << EOF
{
  "\$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
  "contentVersion": "1.0.0.0",
  "resources": []
}
EOF
    echo "Default ARM template created at $templateFile"
fi

echo "Deploying template..."
deploymentOutput=$(az deployment group create --name "$deploymentName" --resource-group "$resourceGroupName" --template-file "$templateFile" --output json)
provisioningState=$(echo "$deploymentOutput" | jq -r '.properties.provisioningState')

if [[ "$provisioningState" == "Succeeded" ]]; then
    echo "Deployment succeeded."
else
    echo "Deployment failed. Provisioning State: $provisioningState"
    deploymentError=$(echo "$deploymentOutput" | jq '.error')
    echo "Error details: $deploymentError"
fi

portalUrl="https://ms.portal.azure.com/#@microsoft.onmicrosoft.com/resource/subscriptions/$subscription/resourceGroups/$resourceGroupName/deployments"

echo "To view the deployments for the resource group, please visit: $portalUrl"

if [ -z "$ACC_CLOUD" ]; then
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        xdg-open "$portalUrl"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        open "$portalUrl"
    elif [[ "$OSTYPE" == "cygwin" ]] || [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "win32" ]]; then
        start "$portalUrl"
    else
        echo "Automatic URL opening not supported on this platform. Please open the URL manually."
    fi
else
    echo "Running in Azure Cloud Shell. Please manually open the URL in your browser."
fi
