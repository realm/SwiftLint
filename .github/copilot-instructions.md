You are working on SwiftLint, a linter for Swift code that enforces coding style and conventions. It helps maintain a clean and consistent codebase by identifying and reporting issues in Swift files. It can even automatically fix some of these issues.

Linting rules are defined in `Source/SwiftLintBuiltInRules/Rules`. If someone mentions a rule by its identifier that is in "snake_case" (e.g., `rule_name`), you can usually find the rule's implementation file named "UpperCamelCaseRule.swift" (e.g., `<RuleName>Rule.swift`) in one of the sub-folders depending on the rule's kind. Specific configurations for rules are located in the `RuleConfigurations` folder, which contains files named as `<RuleName>Configuration.swift` (e.g., `IdentifierNameConfiguration.swift`).

User-facing changes must be documented in the `CHANGELOG.md` file, which is organized by version. New entries always go into the "Main" section. They give credit to the person who has made the change and they reference the issue which has been fixed by the change.

All changes need to pass `swift test` as well as running SwiftLint on itself. This is done by running `swift run swiftlint` in the root directory of the project.
