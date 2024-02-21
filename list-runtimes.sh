#!/bin/bash

# Function to display usage help and available runtime options
show_help() {
    echo "Usage: $0 [--runtime <RUNTIME_NAME>]"
    echo "Example: $0 --runtime powershell"
    echo "Filters and lists Azure Function App runtimes. If no runtime is specified, all runtimes are listed."
    echo "Available runtimes:"

    # Dynamically list available runtimes
    az functionapp list-runtimes | jq -r '[.linux[], .windows[] | .runtime] | unique | .[]' | while read runtime; do
        echo "  - $runtime"
    done
}

# Initialize variables
RUNTIME=""

# Parse command-line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -r|--runtime)
            RUNTIME="$2"
            shift # past argument
            shift # past value
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Execute Azure CLI command and filter output with jq
if [ -z "$RUNTIME" ]; then
    echo "Displaying all runtimes:"
    az functionapp list-runtimes | jq '.'
else
    echo "Filtering for runtime: $RUNTIME"
    OUTPUT=$(az functionapp list-runtimes 2>&1 | jq --arg RUNTIME "$RUNTIME" '[.linux + .windows | .[] | select(.runtime == $RUNTIME)]')

    # Check for errors in az command or jq processing
    if [ $? -ne 0 ]; then
        echo "Error executing command. Ensure Azure CLI is installed and you're logged in."
        echo "Error details: $OUTPUT"
        exit 1
    fi

    # Improved check for if any runtimes were found
    RUNTIME_COUNT=$(echo "$OUTPUT" | jq 'length')

    if [ "$RUNTIME_COUNT" -eq 0 ]; then
        echo "No runtimes found matching the filter: $RUNTIME"
    else
        echo "$OUTPUT" | jq .
    fi
fi

