# Contribution Guidelines

## Tutorial

If you'd like to write a SwiftLint rule but aren't sure how to start,
please watch and follow along with
[this video tutorial](https://vimeo.com/819268038).

## Pull Requests

All changes, no matter how trivial, must be done via pull requests. Commits
should never be made directly on the `main` branch. If possible, avoid mixing
different aspects in one pull request. Prefer squashing if there are commits
that are not reasonable alone. To update your PR branch and resolve conflicts,
prefer rebasing over merging `main`.

_If you have commit access to SwiftLint and believe your change to be trivial
and not worth waiting for review, you may open a pull request and merge it
immediately, but this should be the exception, not the norm._

## Building and Running Locally

### Using Xcode

1. `git clone https://github.com/realm/SwiftLint.git`
1. `cd SwiftLint`
1. `xed .`
1. Select the "swiftlint" scheme.
1. `cmd-opt-r` to open the scheme options.
1. Set the "Arguments Passed On Launch" you want in the "Arguments" tab. See
available arguments [in the README](https://github.com/realm/SwiftLint#command-line).
1. Set the "Working Directory" in the "Options" tab to the path where you would like
to execute SwiftLint — a folder that contains Swift source files.
1. Hit "Run".

|Arguments|Options|
|-|-|
|![image](https://user-images.githubusercontent.com/5748627/115156411-d38c8780-a08c-11eb-9de4-939606c81574.png)|![image](https://user-images.githubusercontent.com/5748627/115156276-287bce00-a08c-11eb-9e1d-35684a665228.png)|

Then you can use the full power of Xcode/LLDB/Instruments to develop and debug your changes to SwiftLint.

### Using the Command Line

1. `git clone https://github.com/realm/SwiftLint.git`
1. `cd SwiftLint`
1. `swift build [-c release]`
1. Use the produced `swiftlint` binary from the command line, either by running `swift run [-c release] [swiftlint] [arguments]` or by invoking the binary directly at `.build/[release|debug]/swiftlint`
1. For debugging, attach LLDB: `lldb -- .build/[release|debug]/swiftlint [arguments]`

### Code Generation

If XCTest cases or functions are added/removed/renamed, or if rules are
added/removed/renamed, you'll need to run `make sourcery`, which requires that
[Sourcery](https://github.com/krzysztofzablocki/Sourcery) be installed on your
machine. This will update source files to reflect these changes.

### Tests

SwiftLint supports building via Xcode and Swift Package Manager on macOS, and
with Swift Package Manager on Linux. When contributing code changes, please
ensure that all four supported build methods continue to work and pass tests:

```shell
xcodebuild -scheme swiftlint test -destination 'platform=macOS'
swift test
make bazel_test
make docker_test
```

## Rules

New rules should be added in the `Source/SwiftLintBuiltInRules/Rules` directory.

Prefer implementing new rules with the help of SwiftSyntax. Look for the
`@SwiftSyntaxRule` attribute for examples and use the same on your own rule.
New rules should conform to either `Rule` or `OptInRule` depending on whether
they shall be enabled by default or opt-in, respectively.

All new rules or changes to existing rules should be accompanied by unit tests.

Whenever possible, prefer adding tests via the `triggeringExamples` and
`nonTriggeringExamples` properties of a rule's `description` rather than adding
those test cases in the unit tests directly. This makes it easier to understand
what rules do by reading their source, and simplifies adding more test cases
over time. With `make sourcery`, you ensure that all test cases are automatically
checked in unit tests. Moreover, the examples added to a rule will appear in the
rule's rendered documentation accessible from the
[Rule Directory](https://realm.github.io/SwiftLint/rule-directory.html).

For debugging purposes, examples can be marked as `focused`. If there are any
focused examples found, then only those will be run when running all tests for that
rule.

```swift
nonTriggeringExamples: [
    Example("let x: [Int]"),
    Example("let x: [Int: String]").focused()   // Only this one will be run in tests.
],
triggeringExamples: [
    Example("let x: ↓Array<String>"),
    Example("let x: ↓Dictionary<Int, String>")
]
```

### Configuration

Every rule is configurable via `.swiftlint.yml`, even if only by settings its default
severity. This is done by setting the `configuration` property of a rule as:

```swift
var configuration = SeverityConfiguration<Self>(.warning)
```

If a rule requires more options, a specific configuration can be implemented
and associated with the rule via its `configuration` property. Check for rules providing
their own configurations as extensive examples or check out

* [`ForceCastRule`](https://github.com/realm/SwiftLint/blob/main/Source/SwiftLintBuiltInRules/Rules/Idiomatic/ForceCastRule.swift)
  for a rule that allows severity configuration,
* [`FileLengthRule`](https://github.com/realm/SwiftLint/blob/main/Source/SwiftLintBuiltInRules/Rules/Metrics/FileLengthRule.swift)
  for a rule that has multiple severity levels or
* [`IdentifierNameRule`](https://github.com/realm/SwiftLint/blob/main/Source/SwiftLintBuiltInRules/Rules/Style/IdentifierNameRule.swift)
  for a rule that allows name evaluation configuration.

Configuring them in `.swiftlint.yml` looks like:

```yaml
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

## Tracking Changes

All changes should be made via pull requests on GitHub.

When issuing a pull request with user-facing changes, please add a
summary of your changes to the `CHANGELOG.md` file.

We follow the same syntax as CocoaPods' CHANGELOG.md:

1. One Markdown unnumbered list item describing the change.
1. 2 trailing spaces on the last line describing the change (so that Markdown renders each change
  [on its own line](https://daringfireball.net/projects/markdown/syntax#p)).
1. A list of Markdown hyperlinks to the contributors to the change. One entry
   per line. Usually just one.
1. A list of Markdown hyperlinks to the issues the change addresses. One entry
   per line. Usually just one. If there was no issue tracking this change,
   you may instead link to the change's pull request.
1. All CHANGELOG.md content is hard-wrapped at 80 characters.

## Cutting a Release

SwiftLint maintainers follow these steps to cut a release:

1. Come up with a witty washer- or dryer-themed release name. Past names include:
    * Tumble Dry
    * FabricSoftenerRule
    * Top Loading
    * Fresh Out Of The Dryer
1. Make sure you have the latest stable Xcode version installed and `xcode-select`ed.
1. Make sure that the selected Xcode has the latest SDKs of all supported platforms installed. This is required to
   build the CocoaPods release.
1. Release a new version by running `make release "0.2.0: Tumble Dry"`.
1. Celebrate. :tada:

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
1. Install Homebrew: <https://brew.sh>
1. Install Buildkite agent and other tools via Homebrew:
   `brew install aria2 bazelisk htop buildkite/buildkite/buildkite-agent robotsandpencils/made/xcodes`
1. Install latest Xcode version: `xcodes update && xcodes install 14.0.0`
1. Add `DANGER_GITHUB_API_TOKEN` and `HOME` to `/opt/homebrew/etc/buildkite-agent/hooks/environment`
1. Configure and launch buildkite agent: `brew info buildkite-agent` /
   <https://buildkite.com/organizations/swiftlint/agents#setup-macos>
