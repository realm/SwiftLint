## Pull Requests

All changes, no matter how trivial, must be done via pull request. Commits
should never be made directly on the `master` branch. If you have commit access
to SwiftLint and believe your change to be trivial and not worth waiting for
review, you may open a pull request and merge immediately, but this should be
the exception, not the norm.

## Rules

New rules should be added in the `Source/SwiftLintFramework/Rules` directory.

Rules should conform to either the `Rule` or `ASTRule` protocols. 
To activate a rule, add the rule to `masterRuleList` in `MasterRuleList.swift`.

All new rules or changes to existing rules should be accompanied by unit tests.

Whenever possible, prefer adding tests via the `triggeringExamples` and
`nonTriggeringExamples` properties of a rule's `description` rather than adding
those test cases in the unit tests directly. This makes it easier to understand
what rules do by reading their source, and simplifies adding more test cases
over time.

### `ConfigurationProviderRule`

If your rule supports user-configurable options via `.swiftlint.yml`, you can
accomplish this by conforming to `ConfigurationProviderRule`. You must provide a
configuration object via the `configuration` property:

* The object provided must conform to `RuleConfiguration`.
* There are several provided `RuleConfiguration`s that cover the common patterns like
  configuring violation severity, violation severity levels, and evaluating
  names.
* If none of the provided `RuleConfiguration`s are applicable, you can create one
  specifically for your rule.

See [`ForceCastRule`](https://github.com/realm/SwiftLint/blob/master/Source/SwiftLintFramework/Rules/ForceCastRule.swift)
for a rule that allows severity configuration,
[`FileLengthRule`](https://github.com/realm/SwiftLint/blob/master/Source/SwiftLintFramework/Rules/FileLengthRule.swift)
for a rule that has multiple severity levels,
[`VariableNameRule`](https://github.com/realm/SwiftLint/blob/master/Source/SwiftLintFramework/Rules/VariableNameRule.swift)
for a rule that allows name evaluation configuration:

``` yaml
force_cast: warning

file_length:
  warning: 800
  error: 1200

variable_name:
  min_length:
    warning: 3
    error: 2
  max_length: 20
  excluded: id
```

If your rule is configurable, but does not fit the pattern of
`ConfigurationProviderRule`, you can conform directly to `Rule`:

* `init(configuration: AnyObject) throws` will be passed the result of parsing the
  value from `.swiftlint.yml` associated with your rule's `identifier` as a key
  (if present).
* `configuration` may be of any type supported by YAML (e.g. `Int`, `String`, `Array`,
  `Dictionary`, etc.).
* This initializer must throw if it does not understand the configuration, or
  it cannot be fully initialized with the configuration and default values.
* By convention, a failing initializer throws
  `ConfigurationError.UnknownConfiguration`
* If this initializer fails, your rule will be initialized with its default
  values by calling `init()`.

## Tracking changes

All changes should be made via pull requests on GitHub.

When issuing a pull request, please add a summary of your changes to
the `CHANGELOG.md` file.

We follow the same syntax as CocoaPods' CHANGELOG.md:

1. One Markdown unnumbered list item describing the change.
2. 2 trailing spaces on the last line describing the change.
3. A list of Markdown hyperlinks to the contributors to the change. One entry
   per line. Usually just one.
4. A list of Markdown hyperlinks to the issues the change addresses. One entry
   per line. Usually just one.
5. All CHANGELOG.md content is hard-wrapped at 80 characters.
