#!/bin/bash

log() {
    echo "$(date +%Y-%m-%dT%H:%M:%S) - $1"
}

validate_storage_name() {
    local NAME="$1"
    if [[ ! "$NAME" =~ ^[a-z0-9]{3,24}$ ]]; then
        log "Error: Invalid storage account name format. Storage account names must be between 3 and 24 characters in length and may contain numbers and lowercase letters only."
        exit 1
    fi
}

generate_storage_name() {
    local ID=$(date +%Y%m%d%H%M%S)
    local NAME="store${ID}"
    validate_storage_name "$NAME"
    echo "$NAME"
}

check_name_availability() {
    local STORAGE_NAME=$1
    local NAME_AVAILABLE="false"

    until [ "$NAME_AVAILABLE" == "true" ]; do
        log "Checking availability for: $STORAGE_NAME"

        local TOKEN=$(az account get-access-token --query accessToken -o tsv 2>/dev/null)
        if [ -z "$TOKEN" ]; then
            log "Error: Unable to obtain access token. Ensure you're logged into Azure CLI."
            exit 1
        fi
        local API_VERSION="2023-01-01"

        local RES=$(curl -s -X POST -H "Content-Type: application/json" -H "Authorization: Bearer $TOKEN" -d "{\"name\": \"$STORAGE_NAME\", \"type\": \"Microsoft.Storage/storageAccounts\"}" "https://management.azure.com/subscriptions/$SUBSCRIPTION_ID/providers/Microsoft.Storage/checkNameAvailability?api-version=$API_VERSION")

        if [ -z "$RES" ]; then
            log "Error: Received an empty response from the server."
            exit 1
        fi

        if ! echo "$RES" | jq . &> /dev/null; then
            log "Error: Failed to parse JSON response: $RES"
            exit 1
        fi

        NAME_AVAILABLE=$(echo "$RES" | jq -r '.nameAvailable')

        if [ "$NAME_AVAILABLE" == "false" ]; then
            log "The name $STORAGE_NAME is not available. Reason: $(echo "$RES" | jq -r '.reason')"
            if [[ "$(echo "$RES" | jq -r '.reason')" == "AccountNameInvalid" ]]; then
                log "Generating a new name."
                STORAGE_NAME=$(generate_storage_name)
            else
                log "Exiting script due to availability check failure."
                exit 1
            fi
        fi
    done

    log "The name $STORAGE_NAME is available."
}

SUBSCRIPTION_ID=$(az account show --query id -o tsv 2>/dev/null)
if [ -z "$SUBSCRIPTION_ID" ]; then
    log "Error: Unable to obtain subscription ID. Ensure you're logged into Azure CLI."
    exit 1
else
    log "Using Subscription ID: $SUBSCRIPTION_ID"
fi

STORAGE_NAME=$(generate_storage_name)
check_name_availability "$STORAGE_NAME"
