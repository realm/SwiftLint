## Pull Requests

All changes, no matter how trivial, must be done via pull request. Commits
should never be made directly on the `master` branch. If you have commit access
to SwiftLint and believe your change to be trivial and not worth waiting for
review, you may open a pull request and merge immediately, but this should be
the exception, not the norm.

## Rules

New rules should be added in the `Source/SwiftLintFramework/Rules` directory.

Rules should conform to either the `Rule`, `ASTRule` or `ConfigurableRule`
protocols. To activate a rule, add the rule to `masterRuleList` in
`RuleList.swift`.

All new rules or changes to existing rules should be accompanied by unit tests.

Whenever possible, prefer adding tests via the `triggeringExamples` and
`nonTriggeringExamples` properties of a rule's `description` rather than adding
those test cases in the unit tests directly. This makes it easier to understand
what rules do by reading their source, and simplifies adding more test cases
over time.

### `ConfigurableRule`

If your rule supports user-configurable options via `.swiftlint.yml`, you can
accomplish this by conforming to `ConfigurableRule`:

* `init?(config: AnyObject)` will be passed the result of parsing the value
  from `.swiftlint.yml` associated with your rule's `identifier` as a key (if
  present).
* `config` may be of any type supported by YAML (e.g. `Int`, `String`, `Array`,
  `Dictionary`, etc.).
* This initializer must fail if it does not understand the configuration, or
  it cannot be fully initialized with the configuration.
* If this initializer fails, your rule will be initialized with its default
  values by calling `init()`.

See [VariableNameMinLengthRule](https://github.com/realm/SwiftLint/blob/647371517e57de3499a77781e45f181605b21045/Source/SwiftLintFramework/Rules/VariableNameMinLengthRule.swift)
for an example that supports the following configurations:

``` yaml
variable_name_min_length: 3

variable_name_min_length:
  - 3
  - 2

variable_name_min_length:
  warning: 3
  error: 2
  excluded: id
```

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
