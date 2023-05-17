#!/bin/bash

set -euo pipefail

# Text to prepend
new_section=$(cat <<EOF
## Main

#### Breaking

* None.

#### Experimental

* None.

#### Enhancements

* None.

#### Bug Fixes

* None.
EOF
)

# Create a temporary file
temp_file=$(mktemp)

# Prepend the new section and a newline to the changelog
{ echo -e "$new_section"; echo; cat CHANGELOG.md; } > "$temp_file"

# Replace the changelog file with this new file
mv "$temp_file" CHANGELOG.md
