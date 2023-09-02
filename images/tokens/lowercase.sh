#!/bin/bash

# Loop over all files in the current directory
for file in *; do
  # Convert the filename to all lowercase
  lowercase=$(echo "$file" | tr '[:upper:]' '[:lower:]')
  
  # Rename the file
  if [ "$file" != "$lowercase" ]; then
    mv "$file" "$lowercase"
  fi
done