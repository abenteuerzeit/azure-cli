#!/bin/bash

# Function to display help message
show_help() {
    echo "Usage: $0 -a <AZURE_STORAGE_ACCOUNT> -c <AZURE_STORAGE_CONTAINER> -g <RG> [-n <NUMBER_OF_BLOBS>] [-d <DURATION_IN_MINUTES>]"
    echo ""
    echo "Mandatory arguments:"
    echo "  -a    Azure Storage Account name"
    echo "  -c    Azure Storage Container name"
    echo "  -g    Resource Group name"
    echo ""
    echo "Optional arguments:"
    echo "  -n    Number of blobs to upload (default is to run indefinitely)"
    echo "  -d    Duration to run the script in minutes (overrides -n if both are provided)"
    exit 1
}

# Initialize our variables
AZURE_STORAGE_ACCOUNT=""
AZURE_STORAGE_CONTAINER=""
RG=""
NUMBER_OF_BLOBS=-1
DURATION_IN_MINUTES=0

# Parse command-line arguments
while getopts "ha:c:g:n:d:" opt; do
    case ${opt} in
        h )
            show_help
            ;;
        a )
            AZURE_STORAGE_ACCOUNT=$OPTARG
            ;;
        c )
            AZURE_STORAGE_CONTAINER=$OPTARG
            ;;
        g )
            RG=$OPTARG
            ;;
        n )
            NUMBER_OF_BLOBS=$OPTARG
            ;;
        d )
            DURATION_IN_MINUTES=$OPTARG
            ;;
        \? )
            show_help
            ;;
    esac
done

# Validate mandatory arguments
if [ -z "$AZURE_STORAGE_ACCOUNT" ] || [ -z "$AZURE_STORAGE_CONTAINER" ] || [ -z "$RG" ]; then
    echo "Error: Missing mandatory arguments"
    show_help
fi

# Start timer for duration-based execution
END_TIME=$(( $(date +%s) + DURATION_IN_MINUTES * 60 ))

# Main loop
COUNT=0
while [ $NUMBER_OF_BLOBS -lt 0 ] || [ $COUNT -lt $NUMBER_OF_BLOBS ]; do
    if [ $DURATION_IN_MINUTES -gt 0 ] && [ $(date +%s) -ge $END_TIME ]; then
        break
    fi

    # Dynamically get the account key
    ACCOUNT_KEY=$(az storage account keys list --resource-group $RG --account-name $AZURE_STORAGE_ACCOUNT --query "[0].value" -o tsv)

    # Generate random text file name and content
    FILE_NAME=$(openssl rand -hex 10).txt
    FOLDER_NAME=$(openssl rand -hex 10)
    FILE_CONTENT=$(openssl rand -base64 16000)

    # Create a temporary file with the generated content
    echo "$FILE_CONTENT" > /tmp/$FILE_NAME

    echo "$(date) - \\$FOLDER_NAME\\$FILE_NAME"

    # Use Azure CLI to upload the file to the storage container
    az storage blob upload \
      --account-name $AZURE_STORAGE_ACCOUNT \
      --account-key $ACCOUNT_KEY \
      --container-name $AZURE_STORAGE_CONTAINER \
      --file /tmp/$FILE_NAME \
      --name $FOLDER_NAME/$FILE_NAME

    # Remove the temporary file
    rm /tmp/$FILE_NAME

    COUNT=$((COUNT + 1))

    # Generate a random sleep interval between 15 and 90 seconds
    SLEEP_INTERVAL=$((RANDOM % 76 + 15))
    sleep $SLEEP_INTERVAL
done

echo "Operation completed: $COUNT blobs uploaded."
