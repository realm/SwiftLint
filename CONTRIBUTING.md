## Pull Requests

All changes, no matter how trivial, must be done via pull request. Commits
should never be made directly on the `main` branch. Prefer rebasing over
merging `main` into your PR branch to update it and resolve conflicts.

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
1. Set the "Arguments Passed On Launch" you want in the "Arguments" tab. See
available arguments [in the README](https://github.com/realm/SwiftLint#command-line).
1. Set the "Working Directory" in the "Options" tab to the path where you would like
to execute SwiftLint. A folder that contains swift source files.
1. Hit "Run"

|Arguments|Options|
|-|-|
|![image](https://user-images.githubusercontent.com/5748627/115156411-d38c8780-a08c-11eb-9de4-939606c81574.png)|![image](https://user-images.githubusercontent.com/5748627/115156276-287bce00-a08c-11eb-9e1d-35684a665228.png)|

Then you can use the full power of Xcode/LLDB/Instruments to develop and debug your changes to SwiftLint.

#### Using the command line

1. `git clone https://github.com/realm/SwiftLint.git`
1. `cd SwiftLint`
1. `swift build [-c release]`
1. Use the produced `swiftlint` binary from the command line, either by running `swift run [-c release] [swiftlint] [arguments]` or by invoking the binary directly at `.build/[release|debug]/swiftlint`
1. [Optional] Attach LLDB: `lldb -- .build/[release|debug]/swiftlint [arguments]`

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
$ xcodebuild -scheme swiftlint test
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

For debugging purposes examples can be marked as `focused`. If there are any
focused examples found, then only those will be run when running tests for that rule.
```
nonTriggeringExamples: [
    Example("let x: [Int]"),
    Example("let x: [Int: String]").focused()   // only this one will be run in tests
],
triggeringExamples: [
    Example("let x: ↓Array<String>"),
    Example("let x: ↓Dictionary<Int, String>")
]
```

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

See [`ForceCastRule`](https://github.com/realm/SwiftLint/blob/main/Source/SwiftLintFramework/Rules/Idiomatic/ForceCastRule.swift)
for a rule that allows severity configuration,
[`FileLengthRule`](https://github.com/realm/SwiftLint/blob/main/Source/SwiftLintFramework/Rules/Metrics/FileLengthRule.swift)
for a rule that has multiple severity levels,
[`IdentifierNameRule`](https://github.com/realm/SwiftLint/blob/main/Source/SwiftLintFramework/Rules/Style/IdentifierNameRule.swift)
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

When issuing a pull request with user-facing changes, please add a
summary of your changes to the `CHANGELOG.md` file.

We follow the same syntax as CocoaPods' CHANGELOG.md:

1. One Markdown unnumbered list item describing the change.
2. 2 trailing spaces on the last line describing the change (so that Markdown renders each change [on its own line](https://daringfireball.net/projects/markdown/syntax#p)).
3. A list of Markdown hyperlinks to the contributors to the change. One entry
   per line. Usually just one.
4. A list of Markdown hyperlinks to the issues the change addresses. One entry
   per line. Usually just one. If there was no issue tracking this change,
   you may instead link to the change's pull request.
5. All CHANGELOG.md content is hard-wrapped at 80 characters.

## CI

SwiftLint uses Azure Pipelines for most of its CI jobs, primarily because
they're the only CI provider to have a free tier with 10x concurrency on macOS.

Some CI jobs run in GitHub Actions (e.g. Docker).

Some CI jobs run on Buildkite using Mac Minis from MacStadium. These are jobs
that benefit from being run on the latest Xcode & macOS versions on bare metal.

### Buildkite Setup

To bring up a new Buildkite worker from MacStadium:

1. Change account password
1. Update macOS to the latest version
1. Install Homebrew: https://brew.sh
1. Install Buildkite agent and other tools via Homebrew:
   `brew install aria2 bazelisk htop buildkite/buildkite/buildkite-agent robotsandpencils/made/xcodes`
1. Install latest Xcode version: `xcodes update && xcodes install 14.0.0`
1. Add `DANGER_GITHUB_API_TOKEN` and `HOME` to `/opt/homebrew/etc/buildkite-agent/hooks/environment`
1. Configure and launch buildkite agent: `brew info buildkite-agent` /
   https://buildkite.com/organizations/swiftlint/agents#setup-macos
