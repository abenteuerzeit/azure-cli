#!/bin/bash

# Function to display help
show_help() {
  echo "Usage: $0 [options] [arguments]"
  echo "Options:"
  echo "  -h            Display this help message."
  echo "  -l            List available Azure locations."
  echo "  -s            List available SKUs (pricing tiers)."
  echo "Arguments:"
  echo "  location      Azure location (default: first available location)."
  echo "  tag           Resource tag (default: reproduction)."
  echo "  skuStorage    Storage account SKU (default: Standard_LRS)."
  echo "  functionsVersion Function app version (default: 4)."
  echo "  pricingTier   Function app pricing tier (default: B1)."
}

# Function to list Azure locations
list_locations() {
  az account list-locations --query "[].{DisplayName:displayName, Name:name}" -o table
}

# Function to list SKUs
list_skus() {
  echo "Available SKUs:"
  echo "B1, B2, B3, D1, F1, FREE, I1, I1v2, I2, I2v2, I3, I3v2, I4v2, I5v2, I6v2, P0V3, P1MV3, P1V2, P1V3, P2MV3, P2V2, P2V3, P3MV3, P3V2, P3V3, P4MV3, P5MV3, S1, S2, S3, SHARED, WS1, WS2, WS3"
}

# Default values
location_default=$(az account list-locations --query "[0].name" -o tsv)
tag_default="reproduction"
skuStorage_default="Standard_LRS"
functionsVersion_default="4"
pricingTier_default="B1"

# Parse command-line options
while getopts ":hls" option; do
  case $option in
    h) # Display help
      show_help
      exit 0;;
    l) # List locations
      list_locations
      exit 0;;
    s) # List SKUs
      list_skus
      exit 0;;
    \?) # Handle invalid options
      echo "Error: Invalid option"
      show_help
      exit 1;;
  esac
done

# Skip over the processed options
shift $((OPTIND-1))

# Accept parameters or use defaults
location="${1:-$location_default}"
tag="${2:-$tag_default}"
skuStorage="${3:-$skuStorage_default}"
functionsVersion="${4:-$functionsVersion_default}"
pricingTier="${5:-$pricingTier_default}"

# Variable block
id=$(date +%Y%m%d%H%M%S)
resourceGroup="rg${id}"
storage="sacc${id}"
functionApp="fnapp$id"

# Create a resource group
echo "Creating $resourceGroup in $location..."
az group create --name $resourceGroup --location "$location" --tags $tag

# Create an Azure storage account in the resource group.
echo "Creating $storage"
az storage account create --name $storage --location "$location" --resource-group $resourceGroup --sku $skuStorage

# Create a serverless function app in the resource group.
echo "Creating $functionApp"
az functionapp create --name $functionApp --storage-account $storage --consumption-plan-location "$location" --resource-group $resourceGroup --functions-version $functionsVersion
az webapp identity assign --name $functionApp --resource-group $resourceGroup
