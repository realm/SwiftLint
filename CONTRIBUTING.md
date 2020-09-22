## Pull Requests

All changes, no matter how trivial, must be done via pull request. Commits
should never be made directly on the `master` branch. Prefer rebasing over
merging `master` into your PR branch to update it and resolve conflicts.

_If you have commit access to SwiftLint and believe your change to be trivial
and not worth waiting for review, you may open a pull request and merge
immediately, but this should be the exception, not the norm._

### Building And Running Locally

#### Using Xcode

1. `git clone https://github.com/realm/SwiftLint.git`
1. `cd SwiftLint`
1. `xed .`
1. Select the "swiftlint" scheme
1. `cmd-opt-r` open the scheme options
1. Set the "Arguments Passed On Launch" you want in the "Arguments" tab
1. Set the "Working Directory" you want in the "Options" tab
1. Hit "Run"

|Arguments|Options|
|-|-|
|![image](https://user-images.githubusercontent.com/474794/93893073-1676b000-fca2-11ea-9428-20423c5f5237.png)|![image](https://user-images.githubusercontent.com/474794/93893135-27bfbc80-fca2-11ea-805a-ee21b446c3f0.png)|

Then you can use the full power of Xcode/LLDB/Instruments to develop and debug your changes to SwiftLint.

#### Using the command line

1. `git clone https://github.com/realm/SwiftLint.git`
1. `cd SwiftLint`
1. `swift build [-c release]`
1. Use the produced `swiftlint` binary from the command line, either by running `swift run [-c release] [swiftlint] [arguments]` or by invoking the binary directly at `.build/[release|debug]/swiftlint`
1. [Optional] Attach LLDB: `lldb -- .build/[release|debug]/swiftlint [arguments]`

### Submodules

This SwiftLint repository uses submodules for its dependencies.
This means that if you decide to fork this repository to contribute to SwiftLint,
don't forget to checkout the submodules as well when cloning, by running
`git submodule update --init --recursive` after cloning.

See more info [in the README](https://github.com/realm/SwiftLint#installation).

### Code Generation

If XCTest cases or functions are added/removed/renamed, or if rules are
added/removed/renamed, you'll need to run `make sourcery`, which requires that
[Sourcery](https://github.com/krzysztofzablocki/Sourcery) be installed on your
machine. This will update source files to reflect these changes.

### Tests

SwiftLint supports building via Xcode and Swift Package Manager on macOS, and
with Swift Package Manager on Linux. When contributing code changes, please
ensure that all three supported build methods continue to work and pass tests.

```shell
$ script/cibuild
$ swift test
$ make docker_test
```

## Rules

New rules should be added in the `Source/SwiftLintFramework/Rules` directory.

Rules should conform to either the `Rule` or `ASTRule` protocols.

All new rules or changes to existing rules should be accompanied by unit tests.

Whenever possible, prefer adding tests via the `triggeringExamples` and
`nonTriggeringExamples` properties of a rule's `description` rather than adding
those test cases in the unit tests directly. This makes it easier to understand
what rules do by reading their source, and simplifies adding more test cases
over time. This way adding a unit test for your new Rule is just a matter of
adding a test case in `RulesTests.swift` which simply calls
`verifyRule(YourNewRule.description)`.

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

See [`ForceCastRule`](https://github.com/realm/SwiftLint/blob/master/Source/SwiftLintFramework/Rules/Idiomatic/ForceCastRule.swift)
for a rule that allows severity configuration,
[`FileLengthRule`](https://github.com/realm/SwiftLint/blob/master/Source/SwiftLintFramework/Rules/Metrics/FileLengthRule.swift)
for a rule that has multiple severity levels,
[`IdentifierNameRule`](https://github.com/realm/SwiftLint/blob/master/Source/SwiftLintFramework/Rules/Style/IdentifierNameRule.swift)
for a rule that allows name evaluation configuration:

``` yaml
force_cast: warning

file_length:
  warning: 800
  error: 1200

identifier_name:
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
  `ConfigurationError.UnknownConfiguration`.
* If this initializer fails, your rule will be initialized with its default
  values by calling `init()`.

## Tracking changes

All changes should be made via pull requests on GitHub.

When issuing a pull request, please add a summary of your changes to
the `CHANGELOG.md` file.

We follow the same syntax as CocoaPods' CHANGELOG.md:

1. One Markdown unnumbered list item describing the change.
2. 2 trailing spaces on the last line describing the change (so that Markdown renders each change [on its own line](https://daringfireball.net/projects/markdown/syntax#p)).
3. A list of Markdown hyperlinks to the contributors to the change. One entry
   per line. Usually just one.
4. A list of Markdown hyperlinks to the issues the change addresses. One entry
   per line. Usually just one. If there was no issue tracking this change,
   you may instead link to the change's pull request.
5. All CHANGELOG.md content is hard-wrapped at 80 characters.
