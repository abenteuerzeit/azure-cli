#!/bin/bash

# Default values
defaultIdPrefix="rep"
ID=$(date +%Y%m%d%H%M%S)
region="eastus"
namespaceSuffix="ehnamespace"
eventhubSuffix="entity"
dashboardSuffix="dashboard"

# Check for help flag
if [[ "$1" == "--help" ]]; then
    echo "Usage: $0 [OPTIONS]"
    echo "Options:"
    echo "  --id <ID>                Custom identifier for the resources (default: current timestamp)"
    echo "  --region <region>        Azure region for the resources (default: eastus)"
    echo "  --namespaceSuffix <text> Suffix for the Event Hubs namespace (default: ehnamespace)"
    echo "  --eventhubSuffix <text>  Suffix for the Event Hub (default: entity)"
    echo "  --dashboardSuffix <text> Suffix for the dashboard (default: dashboard)"
    echo "  --help                   Show this help message and exit"
    exit 0
fi

# Parse named arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --id) ID="$2"; shift ;;
        --region) region="$2"; shift ;;
        --namespaceSuffix) namespaceSuffix="$2"; shift ;;
        --eventhubSuffix) eventhubSuffix="$2"; shift ;;
        --dashboardSuffix) dashboardSuffix="$2"; shift ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

# Validate and adjust ID to meet Azure naming conventions
if ! [[ $ID =~ ^[a-zA-Z].*[a-zA-Z0-9]$ ]]; then
    echo "Original ID does not meet Azure naming conventions. Adjusting..."
    ID="${defaultIdPrefix}${ID}"
    ID="${ID:0:254}" # Ensure max length is not exceeded
fi

# Ensure ID ends with a letter or number
if ! [[ $ID =~ [a-zA-Z0-9]$ ]]; then
    ID="${ID}1"
fi

# Variable overrides
rgName="${ID}rg"
namespaceName="${ID}${namespaceSuffix}"
eventhubName="${ID}${eventhubSuffix}"
dashboardName="${ID}${dashboardSuffix}"

echo "Using configuration - ID: $ID, Region: $region, Namespace: $namespaceName, Event Hub: $eventhubName, Dashboard: $dashboardName"

# Resource Group Creation
echo "Creating Resource Group: $rgName..."
if ! az group create --name "$rgName" --location "$region"; then
    echo "Failed to create resource group $rgName"
    exit 1
fi

# Event Hubs Namespace Creation
echo "Creating Event Hubs Namespace: $namespaceName..."
if ! az eventhubs namespace create --name "$namespaceName" --resource-group "$rgName" --location "$region"; then
    echo "Failed to create Event Hubs Namespace $namespaceName"
    exit 1
fi

# Event Hub Creation
echo "Creating Event Hub: $eventhubName..."
if ! az eventhubs eventhub create --name "$eventhubName" --resource-group "$rgName" --namespace-name "$namespaceName"; then
    echo "Failed to create Event Hub $eventhubName"
    exit 1
fi

# Final Summary
echo
echo "Setup Summary:"
echo "---------------"
echo "Resource Group: $rgName"
echo "Region: $region"
echo "Event Hubs Namespace: $namespaceName"
echo "Event Hub: $eventhubName"
echo "Dashboard: $dashboardName"
echo
echo "To manage these resources, use the Azure portal or continue with Azure CLI commands."
echo "For example:"
echo "  az eventhubs namespace show --name $namespaceName --resource-group $rgName"
echo "  az eventhubs eventhub show --name $eventhubName --namespace-name $namespaceName --resource-group $rgName"
