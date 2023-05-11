#!/bin/bash

set -euo pipefail

# Release Notes Section

in_top_changelog_section=0
first_line=1

while IFS= read -r line; do
  if [[ "$line" == "## "* ]]; then
    if [ $in_top_changelog_section -eq 0 ]; then
      in_top_changelog_section=1
    else
      in_top_changelog_section=0
      break
    fi
  elif [ $in_top_changelog_section -eq 1 ]; then
    if [ $first_line -eq 1 ]; then
      first_line=0
    else
      echo "$line"
    fi
  fi
done < CHANGELOG.md

# Bazel Section

bazel_section=$(cat <<'EOF'
---

### Using Bazel

With bzlmod:

```
// Pending BCR update
bazel_dep(name = "swiftlint", version = "SWIFTLINT_VERSION", repo_name = "SwiftLint")
```

Without bzlmod, put this in your `WORKSPACE`:

<details>

<summary>WORKSPACE</summary>

```python
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

http_archive(
    name = "build_bazel_rules_apple",
    sha256 = "9e26307516c4d5f2ad4aee90ac01eb8cd31f9b8d6ea93619fc64b3cbc81b0944",
    url = "https://github.com/bazelbuild/rules_apple/releases/download/2.2.0/rules_apple.2.2.0.tar.gz",
)

load(
    "@build_bazel_rules_apple//apple:repositories.bzl",
    "apple_rules_dependencies",
)

apple_rules_dependencies()

load(
    "@build_bazel_rules_swift//swift:repositories.bzl",
    "swift_rules_dependencies",
)

swift_rules_dependencies()

load(
    "@build_bazel_rules_swift//swift:extras.bzl",
    "swift_rules_extra_dependencies",
)

swift_rules_extra_dependencies()

http_archive(
    name = "SwiftLint",
    sha256 = "BAZEL_SHA",
    url = "https://github.com/realm/SwiftLint/releases/download/SWIFTLINT_VERSION/bazel.tar.gz",
)

load("@SwiftLint//bazel:repos.bzl", "swiftlint_repos")

swiftlint_repos()

load("@SwiftLint//bazel:deps.bzl", "swiftlint_deps")

swiftlint_deps()
```

</details>

Then you can run SwiftLint in the current directory with this command:

```console
bazel run @SwiftLint//:swiftlint -- --help
```
EOF
)

version="$(./tools/get-version)"
bazel_sha="$(cut -d' ' -f1 bazel.tar.gz.sha256 | sed '0d')"

echo "$bazel_section" \
  | sed "s/SWIFTLINT_VERSION/$version/g" \
  | sed "s/BAZEL_SHA/$bazel_sha/"
