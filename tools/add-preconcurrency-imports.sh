#!/bin/bash

files=(
"Source/SwiftLintBuiltInRules/Rules/Idiomatic/PrivateOverFilePrivateRule.swift"
"Source/SwiftLintBuiltInRules/Rules/Idiomatic/ToggleBoolRule.swift"
"Source/SwiftLintBuiltInRules/Rules/Lint/UnusedClosureParameterRule.swift"
"Source/SwiftLintBuiltInRules/Rules/Style/EmptyEnumArgumentsRule.swift"
"Source/SwiftLintBuiltInRules/Rules/Style/OptionalEnumCaseMatchingRule.swift"
"Source/SwiftLintBuiltInRules/Rules/Style/TrailingCommaRule.swift"
)

for file in "${files[@]}"; do
  sed -i '' -e 's/import SwiftSyntax$/@preconcurrency import SwiftSyntax/g' "$file"
done
