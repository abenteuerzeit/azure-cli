#!/bin/bash

# Initialize variables
RG=""
FunctionAppName=""

# Manual parsing of command-line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -g|--resource-group)
            RG="$2"
            shift
            ;;
        -f|--function-app)
            FunctionAppName="$2"
            shift
            ;;
        *)
            echo "Unknown parameter passed: $1"
            exit 1
            ;;
    esac
    shift
done

# Check if variables are set
if [[ -z "$RG" ]] || [[ -z "$FunctionAppName" ]]; then
    echo "Both --resource-group (or -g) and --function-app (or -f) flags are required."
    exit 1
fi

masterKey=$(az functionapp keys list -g "$RG" -n "$FunctionAppName" 2>/dev/null | jq -r '.masterKey')
endpoint="https://${FunctionAppName}.azurewebsites.net/admin/host/synctriggers?code=${masterKey}"
response=$(curl -s -X POST $endpoint)
status=$(echo "$response" | jq -r '.status')
echo "Sync triggers status: $status"


# Alternatively use
# az resource invoke-action --resource-group $RG --action syncfunctiontriggers --name $FunctionAppName --resource-type Microsoft.Web/sites
