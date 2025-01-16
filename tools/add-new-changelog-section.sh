#!/bin/bash

set -euo pipefail

# Header with new section
new_section=$(cat <<EOF
# Changelog

## Main

### Breaking

* None.

### Experimental

* None.

### Enhancements

* None.

### Bug Fixes

* None.
EOF
)

# Read changelog skipping the first line
changelog=$(tail -n +2 CHANGELOG.md)

# Prepend the new section and a newline to the existing changelog
{ echo -e "$new_section"; echo "$changelog"; } > CHANGELOG.md
