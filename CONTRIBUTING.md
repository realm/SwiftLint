# Contribution Guidelines

## Tutorial

If you'd like to write a SwiftLint rule but aren't sure how to start, please watch and follow along with [this video
tutorial](https://vimeo.com/819268038).

## Pull Requests

All changes, no matter how trivial, must be done via pull requests. Commits should never be made directly on the `main`
branch. If possible, avoid mixing different aspects in one pull request. Prefer squashing if there are commits that are
not reasonable alone. To update your PR branch and resolve conflicts, use rebasing instead of merging `main`.

> [!IMPORTANT]
> If you have commit access to SwiftLint and believe your change to be trivial and not worth waiting for
> review, you may open a pull request and merge it immediately, but this should be the exception, not the norm.

## Building and Running Locally

The first step is to clone the repository. We recommend Xcode or Visual Studio Code with the
[awesome Swift extension](https://github.com/swiftlang/vscode-swift) installed from the
[Visual Studio Marketplace](https://marketplace.visualstudio.com/items?itemName=swiftlang.swift-vscode) or the
[Open VSX Registry](https://open-vsx.org/extension/sswg/swift-lang) for development.

### Using Xcode

1. `xed .`
1. Select the "swiftlint" scheme.
1. Press `⌘ Cmd` `⌥ Option` `R` to open the scheme options.
1. Set the "Arguments Passed On Launch" you want in the "Arguments" tab. See
available arguments [in the README](https://github.com/realm/SwiftLint#command-line).
1. Set the "Working Directory" in the "Options" tab to the path where you would like
to execute SwiftLint — a folder that contains Swift source files.
1. Hit "Run".

|Arguments|Options|
|-|-|
|![image](https://user-images.githubusercontent.com/5748627/115156411-d38c8780-a08c-11eb-9de4-939606c81574.png)|![image](https://user-images.githubusercontent.com/5748627/115156276-287bce00-a08c-11eb-9e1d-35684a665228.png)|

Then you can use the full power of Xcode/LLDB/Instruments to develop and debug your changes to SwiftLint.

### Using Visual Studio Code

1. `code .`
1. Wait for the setup to complete.
1. Press `⌘ Cmd` `⇧ Shift` `P` to open the command palette.
1. With the [Swift extension](https://github.com/swiftlang/vscode-swift) installed search for and select
   "Task: Run Build Task".
1. Decide to build the `swiftlint` binary only or to build everything including tests.
1. The extension allows you to debug the binary and run tests.

### Using the Command Line

1. `swift build [-c release]`
1. Use the produced `swiftlint` binary from the command line, either by running
   `swift run [-c release] [swiftlint] [arguments]` or by invoking the binary directly at
   `.build/[release|debug]/swiftlint`.
1. For debugging, attach LLDB: `lldb -- .build/[release|debug]/swiftlint [arguments]`.

### Code Generation

If rules are added/removed/renamed, you'll need to run `make sourcery`, which requires that [Bazel](https://bazel.build)
is installed on your machine (`brew install bazelisk`). This will update source files to reflect these changes.

If you'd rather like to avoid installing Bazel, you can run Sourcery manually. Make sure to use the same version of
Sourcery as defined in [WORKSPACE](WORKSPACE).

### Tests

SwiftLint supports building via Xcode and Swift Package Manager on macOS, and with Swift Package Manager on Linux. When
contributing code changes, please ensure that all four supported build methods continue to work and pass tests:

```shell
xcodebuild -scheme swiftlint test -destination 'platform=macOS'
swift test
make bazel_test
make docker_test
```

If you find it too much effort to installed all the tooling required for the different build/test methods, just
open a pull request and watch the CI results carefully. They include all the necessary builds and checks.

## Rules

New rules should be added in the `Source/SwiftLintBuiltInRules/Rules` directory. We recommend to use the `swiftlint-dev`
command line tool to generate scaffolds for new rules and their configurations. After having the repository cloned, run
`swift run swiftlint-dev rule-template <RuleName>` to create the new rule at the correct location. Refer to the command's
help `-h/--help` for customization options. Run `make sourcery` afterwards to register the new rule and its tests.

Prefer implementing new rules with the help of SwiftSyntax. Look for the `@SwiftSyntaxRule` attribute for examples and
use the same on your own rule.

All new rules or changes to existing rules should be accompanied by unit tests.

Whenever possible, prefer adding tests via the `triggeringExamples` and `nonTriggeringExamples` properties of a rule's
`description` rather than adding those test cases in unit tests directly. This makes it easier to understand what rules
do by reading their source, and simplifies adding more test cases over time. With `make sourcery`, you ensure that all
test cases are automatically checked in unit tests. Moreover, the examples added to a rule will appear in the rule's
rendered documentation accessible from the [Rule Directory](https://realm.github.io/SwiftLint/rule-directory.html).

For debugging purposes, examples can be marked as `focused`. If there are any focused examples found, then only those
will be run when executing all tests for that rule.

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

Every rule is configurable via `.swiftlint.yml`, even if only by settings its default severity. This is done by setting
the `configuration` property of a rule as:

```swift
var configuration = SeverityConfiguration<Self>(.warning)
```

If a rule requires more options, a specific configuration can be implemented and associated with the rule via its
`configuration` property. Check for rules providing their own configurations as extensive examples or check out

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

When issuing a pull request with user-facing changes, please add a summary of your changes to the `CHANGELOG.md` file.

We follow the same syntax as CocoaPods' CHANGELOG.md:

1. One Markdown unnumbered list item describing the change.
1. 2 trailing spaces on the last line describing the change (so that Markdown renders each change
   [on its own line](https://daringfireball.net/projects/markdown/syntax#p)).
1. A list of Markdown hyperlinks to the contributors to the change. Usually just one.
1. A list of Markdown hyperlinks to the issues the change addresses. Usually just one or even none. Mentioning the pull
   request number is not necessary, as GitHub automatically adds it to the commit message upon squash-merge.
1. All `CHANGELOG.md` content is hard-wrapped at 80 characters.

## Cutting a Release

The release workflows require two tokens specific to your GitHub user account to be set as Action secrets in the
SwiftLint repository. Make sure you have the following steps completed once before cutting your first release:

1. Navigate to [Action secrets and variables](https://github.com/realm/SwiftLint/settings/secrets/actions) in the
   repository settings.
1. Add a new secret named `PERSONAL_GITHUB_TOKEN_<USERNAME>` where `<USERNAME>` is your GitHub username in all
   uppercase. The value must be a personal access token with the `read:user`, `repo`, `user:email` and
   `workflow` scopes.
1. Follow [these instructions](https://medium.com/swlh/automated-cocoapod-releases-with-github-actions-8526dd4535c7) to
   set the variable `COCOAPODS_TRUNK_TOKEN_<USERNAME>` to your CocoaPods trunk token.

SwiftLint maintainers follow these steps to cut a release:

1. Come up with a witty washer- or dryer-themed release name. Past names include:
    * Tumble Dry
    * FabricSoftenerRule
    * Top Loading
    * Fresh Out Of The Dryer

   You may ask your favorite AI chat bot for suggestions. :robot:
1. In the [GitHub UI](https://github.com/realm/SwiftLint/actions/workflows/release.yml) press "Run workflow". Enter the
   release version and the title. Start the workflow and wait for it to **create a release branch**,
   **build the most important artifacts** and **prepare a draft release**.
1. Review the draft release thoroughly making sure that the artifacts have been attached to it and the release notes are
   correct.
1. If everything looks good and the **release branch has not diverged from `main`** in the meantime, publish the
   release. :rocket:
1. A few "post-release" jobs will get started to complete the list of artifacts on the release page. One of them
   will also fast-forward merge the release branch into `main`. All jobs fail if that's not possible.
1. Celebrate! :tada:

In case the CocoaPods release fails, you can try to publish it manually:

1. Make sure you have the latest stable Xcode version installed and `xcode-select`ed.
1. Make sure that the selected Xcode has the latest SDKs of all supported platforms installed. This is required to
   build the CocoaPods release.
1. Run `make pod_publish`.

## CI

SwiftLint uses Azure Pipelines for most of its CI jobs, primarily because they're the only CI provider to have a free
tier with 10x concurrency on macOS.

Some CI jobs run as GitHub Actions (e.g. Docker build, linting, release workflows).

The most important CI jobs run on Buildkite using Macs provided by MacStadium. These are jobs that benefit from being
run on the latest Xcode & macOS versions on bare metal. This is important for performance comparisons and caching in
Bazel builds.

### Buildkite Setup

To bring up a new Buildkite worker from MacStadium:

1. Change account password.
1. Update macOS to the latest version.
1. [Install Homebrew](https://brew.sh).
1. Install the Buildkite agent and other tools via Homebrew:
   `brew install aria2 bazelisk htop buildkite/buildkite/buildkite-agent robotsandpencils/made/xcodes`
1. Install latest Xcode version: `xcodes update && xcodes install 14.0.0`
1. Add `DANGER_GITHUB_API_TOKEN` and `HOME` to `/opt/homebrew/etc/buildkite-agent/hooks/environment`
1. Configure and launch buildkite agent as described in `brew info buildkite-agent` or on
   <https://buildkite.com/organizations/swiftlint/agents#setup-macos>.
