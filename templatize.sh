#!/bin/bash

# Get the template name from the first argument to this script
template_name=$1

# Check if a .env.general file exists
env_general_file=".env.general"
if [ ! -f "$env_general_file" ]; then
    echo "INFO: No .env.general file found. This is not required, but can simplify the process of creating new templates."
else
    # Source the environment variables from the .env.general file
    set -a
    source "$env_general_file"
    set +a
fi

# Check if a .env file exists for the given template
env_file=".env.${template_name}"
if [ ! -f "$env_file" ]; then
    echo "ERROR: Environment file $env_file does not exist"
    exit 1
else
    echo "INFO: Using environment file $env_file"
fi

# Source the environment variables from the .env file
set -a
source "$env_file"
set +a

# Replace ~ with $HOME in SRC_CONFIG_PATH and DST_CONFIG_PATH
SRC_CONFIG_PATH=${SRC_CONFIG_PATH/\~/$HOME}
DST_CONFIG_PATH=${DST_CONFIG_PATH/\~/$HOME}

# Check if source file exists
if [ ! -f "$SRC_CONFIG_PATH" ]; then
    echo "ERROR: Template file $SRC_CONFIG_PATH does not exist"
    exit 1
else
    echo "INFO: Using template file $SRC_CONFIG_PATH"
fi

# Declare two indexed arrays to store the variable names and their corresponding values
var_names=()
var_values=()

# Iterate over all environment variables
for var in $(compgen -e); do
    # If the environment variable name starts with "TEMPLATE_VAR_", add it to the variables array
    if [[ $var == TEMPLATE_VAR_* ]]; then
        var_names+=("$var")
        var_values+=("${!var}")
    fi
done

echo "INFO: Found ${#var_names[@]} variables in the environment file"
echo "INFO: Found ${#var_values[@]} values in the environment file"

# Read the source config file line by line
while IFS= read -r line || [[ -n $line ]]; do
    # Iterate over each variable in the variables array
    for index in "${!var_names[@]}"; do
        # Assign current variable
        current_var="{{${var_names[$index]}}}"
        # Replace each occurrence of the variable name in the current line with its corresponding value
        line=${line//$current_var/${var_values[$index]}}
    done
    # Output the processed line
    echo "$line"
# Read from the source config file and write to the destination config file
done < "$SRC_CONFIG_PATH" > "$DST_CONFIG_PATH"

echo "SUCCESS: Template $template_name successfully templatized and saved to $DST_CONFIG_PATH"
