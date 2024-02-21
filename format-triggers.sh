#!/bin/bash

# Check if a file path is provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <path_to_input_file>"
    exit 1
fi

input_file="$1"
input_dir=$(dirname "$input_file")
output_file="${input_dir}/cleaned_output.json"

echo "Processing file: $input_file"

# Extract the JSON string, remove leading and trailing parts, and unescape
content=$(grep -oP '^ *\"triggers\": \"\K(.*)(?=\",$)' "$input_file" | sed 's/\\//g')

if [ -z "$content" ]; then
    echo "No content extracted. Please check the input file format."
    exit 1
fi

# Format the JSON content using jq and save it in the same directory as the input file
echo "$content" | jq . > "$output_file"

if [ $? -ne 0 ]; then
    echo "Failed to parse JSON content. The extracted string might not be valid JSON."
    exit 1
else
    echo "Processed JSON saved to: $output_file"
fi
