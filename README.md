# SwiftLint

A tool to enforce Swift style and conventions, loosely based on
[GitHub's Swift Style Guide](https://github.com/github/swift-style-guide).

SwiftLint hooks into [Clang](http://clang.llvm.org) and
[SourceKit](http://www.jpsim.com/uncovering-sourcekit) to use the
[AST](http://clang.llvm.org/docs/IntroductionToTheClangAST.html) representation
of your source files for more accurate results.

[![Build Status](https://dev.azure.com/jpsim/SwiftLint/_apis/build/status/realm.SwiftLint?branchName=master)](https://dev.azure.com/jpsim/SwiftLint/_build/latest?definitionId=4?branchName=master)
[![codecov.io](https://codecov.io/github/realm/SwiftLint/coverage.svg?branch=master)](https://codecov.io/github/realm/SwiftLint?branch=master)

![](assets/screenshot.png)

This project adheres to the [Contributor Covenant Code of Conduct](https://realm.io/conduct).
By participating, you are expected to uphold this code. Please report
unacceptable behavior to [info@realm.io](mailto:info@realm.io).

> Language Switch: [中文](https://github.com/realm/SwiftLint/blob/master/README_CN.md), [한국어](https://github.com/realm/SwiftLint/blob/master/README_KR.md).

## Installation

### Using [Homebrew](http://brew.sh/):

```
brew install swiftlint
```

### Using [CocoaPods](https://cocoapods.org):

Simply add the following line to your Podfile:

```ruby
pod 'SwiftLint'
```

This will download the SwiftLint binaries and dependencies in `Pods/` during your next
`pod install` execution and will allow you to invoke it via `${PODS_ROOT}/SwiftLint/swiftlint`
in your Script Build Phases.

This is the recommended way to install a specific version of SwiftLint since it supports
installing a pinned version rather than simply the latest (which is the case with Homebrew).

Note that this will add the SwiftLint binaries, its dependencies' binaries and the Swift binary
library distribution to the `Pods/` directory, so checking in this directory to SCM such as
git is discouraged.

### Using [Mint](https://github.com/yonaskolb/mint):

```
$ mint install realm/SwiftLint
```

### Using a pre-built package:

You can also install SwiftLint by downloading `SwiftLint.pkg` from the
[latest GitHub release](https://github.com/realm/SwiftLint/releases/latest) and
running it.

### Compiling from source:

You can also build from source by cloning this project and running
`git submodule update --init --recursive; make install` (Xcode 10.0 or later).

### Known Installation Issues On MacOS Before 10.14.4

Starting with [SwiftLint 0.32.0](https://github.com/realm/SwiftLint/releases/tag/0.32.0), if you get
an error similar to `dyld: Symbol not found: _$s11SubSequenceSlTl` when running SwiftLint,
you'll need to install the [Swift 5 Runtime Support for Command Line Tools](https://support.apple.com/kb/DL1998).

Alternatively, you can:

* Update to macOS 10.14.4 or later
* Install Xcode 10.2 or later at `/Applications/Xcode.app`
* Rebuild SwiftLint from source using Xcode 10.0 or later

## Usage

### Presentation

To get a high-level overview of recommended ways to integrate SwiftLint into your project,
we encourage you to watch this presentation or read the transcript:

[![Presentation](assets/presentation.jpg)](https://academy.realm.io/posts/slug-jp-simard-swiftlint/)

### Xcode

Integrate SwiftLint into an Xcode scheme to get warnings and errors displayed
in the IDE. Just add a new "Run Script Phase" with:

```bash
if which swiftlint >/dev/null; then
  swiftlint
else
  echo "warning: SwiftLint not installed, download from https://github.com/realm/SwiftLint"
fi
```

![](assets/runscript.png)

Alternatively, if you've installed SwiftLint via CocoaPods the script should look like this:

```bash
"${PODS_ROOT}/SwiftLint/swiftlint"
```

#### Format on Save Xcode Plugin

To run `swiftlint autocorrect` on save in Xcode, install the
[SwiftLintXcode](https://github.com/ypresto/SwiftLintXcode) plugin from Alcatraz.

⚠️This plugin will not work with Xcode 8 or later without disabling SIP.
This is not recommended.

### AppCode

To integrate SwiftLint with AppCode, install
[this plugin](https://plugins.jetbrains.com/plugin/9175) and configure
SwiftLint's installed path in the plugin's preferences.
The `autocorrect` action is available via `⌥⏎`.

### Atom

To integrate SwiftLint with [Atom](https://atom.io/), install the
[`linter-swiftlint`](https://atom.io/packages/linter-swiftlint) package from
APM.

### fastlane

You can use the [official swiftlint fastlane action](https://docs.fastlane.tools/actions/swiftlint) to run SwiftLint as part of your fastlane process.

```ruby
swiftlint(
    mode: :lint,                            # SwiftLint mode: :lint (default) or :autocorrect
    executable: "Pods/SwiftLint/swiftlint", # The SwiftLint binary path (optional). Important if you've installed it via CocoaPods
    path: "/path/to/lint",                  # Specify path to lint (optional)
    output_file: "swiftlint.result.json",   # The path of the output file (optional)
    reporter: "json",                       # The custom reporter to use (optional)
    config_file: ".swiftlint-ci.yml",       # The path of the configuration file (optional)
    files: [                                # List of files to process (optional)
        "AppDelegate.swift",
        "path/to/project/Model.swift"
    ],
    ignore_exit_status: true,               # Allow fastlane to continue even if SwiftLint returns a non-zero exit status (Default: false)
    quiet: true,                            # Don't print status logs like 'Linting ' & 'Done linting' (Default: false)
    strict: true                            # Fail on warnings? (Default: false)
)
```


### Command Line

```
$ swiftlint help
Available commands:

   analyze         [Experimental] Run analysis rules
   autocorrect     Automatically correct warnings and errors
   generate-docs   Generates markdown documentation for all rules
   help            Display general or command-specific help
   lint            Print lint warnings and errors (default command)
   rules           Display the list of rules and their identifiers
   version         Display the current version of SwiftLint
```

Run `swiftlint` in the directory containing the Swift files to lint. Directories
will be searched recursively.

To specify a list of files when using `lint`, `autocorrect` or `analyze`
(like the list of files modified by Xcode specified by the
[`ExtraBuildPhase`](https://github.com/norio-nomura/ExtraBuildPhase) Xcode
plugin, or modified files in the working tree based on `git ls-files -m`), you
can do so by passing the option `--use-script-input-files` and setting the
following instance variables: `SCRIPT_INPUT_FILE_COUNT` and
`SCRIPT_INPUT_FILE_0`, `SCRIPT_INPUT_FILE_1`...`SCRIPT_INPUT_FILE_{SCRIPT_INPUT_FILE_COUNT}`.

These are same environment variables set for input files to
[custom Xcode script phases](http://indiestack.com/2014/12/speeding-up-custom-script-phases/).

### Working With Multiple Swift Versions

SwiftLint hooks into SourceKit so it continues working even as Swift evolves!

This also keeps SwiftLint lean, as it doesn't need to ship with a full Swift
compiler, it just communicates with the official one you already have installed
on your machine.

You should always run SwiftLint with the same toolchain you use to compile your
code.

You may want to override SwiftLint's default Swift toolchain if you have
multiple toolchains or Xcodes installed.

Here's the order in which SwiftLint determines which Swift toolchain to use:

* `$XCODE_DEFAULT_TOOLCHAIN_OVERRIDE`
* `$TOOLCHAIN_DIR` or `$TOOLCHAINS`
* `xcrun -find swift`
* `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain`
* `/Applications/Xcode-beta.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain`
* `~/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain`
* `~/Applications/Xcode-beta.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain`

`sourcekitd.framework` is expected to be found in the `usr/lib/` subdirectory of
the value passed in the paths above.

You may also set the `TOOLCHAINS` environment variable to the reverse-DNS
notation that identifies a Swift toolchain version:

```shell
$ TOOLCHAINS=com.apple.dt.toolchain.Swift_2_3 swiftlint autocorrect
```

On Linux, SourceKit is expected to be located in
`/usr/lib/libsourcekitdInProc.so` or specified by the `LINUX_SOURCEKIT_LIB_PATH`
environment variable.

### Swift Version Support

Here's a reference of which SwiftLint version to use for a given Swift version.

| Swift version   | Last supported SwiftLint release |
|:----------------|:---------------------------------|
| Swift 1.x       | SwiftLint 0.1.2                  |
| Swift 2.x       | SwiftLint 0.18.1                 |
| Swift 3.x       | SwiftLint 0.25.1                 |
| Swift 4.0-4.1.x | SwiftLint 0.28.2                 |
| Swift 4.2.x-5.0 | Latest                           |

## Rules

Over 75 rules are included in SwiftLint and the Swift community (that's you!)
continues to contribute more over time.
[Pull requests](CONTRIBUTING.md) are encouraged.

You can find an updated list of rules and more information about them
in [Rules.md](Rules.md).

You can also check [Source/SwiftLintFramework/Rules](Source/SwiftLintFramework/Rules)
directory to see their implementation.

### Opt-In Rules

`opt_in_rules` are disabled by default (i.e., you have to explicitly enable them
in your configuration file).

Guidelines on when to mark a rule as opt-in:

* A rule that can have many false positives (e.g. `empty_count`)
* A rule that is too slow
* A rule that is not general consensus or is only useful in some cases
  (e.g. `force_unwrapping`)

### Disable rules in code

Rules can be disabled with a comment inside a source file with the following
format:

`// swiftlint:disable <rule1> [<rule2> <rule3>...]`

The rules will be disabled until the end of the file or until the linter sees a
matching enable comment:

`// swiftlint:enable <rule1> [<rule2> <rule3>...]`

For example:

```swift
// swiftlint:disable colon
let noWarning :String = "" // No warning about colons immediately after variable names!
// swiftlint:enable colon
let hasWarning :String = "" // Warning generated about colons immediately after variable names
```

Including the `all` keyword will disable all rules until the linter sees a matching enable comment:

`// swiftlint:disable all`
`// swiftlint:enable all`

For example:

```swift
// swiftlint:disable all
let noWarning :String = "" // No warning about colons immediately after variable names!
let i = "" // Also no warning about short identifier names
// swiftlint:enable all
let hasWarning :String = "" // Warning generated about colons immediately after variable names
let y = "" // Warning generated about short identifier names
```

It's also possible to modify a `disable` or `enable` command by appending
`:previous`, `:this` or `:next` for only applying the command to the previous,
this (current) or next line respectively.

For example:

```swift
// swiftlint:disable:next force_cast
let noWarning = NSNumber() as! Int
let hasWarning = NSNumber() as! Int
let noWarning2 = NSNumber() as! Int // swiftlint:disable:this force_cast
let noWarning3 = NSNumber() as! Int
// swiftlint:disable:previous force_cast
```

Run `swiftlint rules` to print a list of all available rules and their
identifiers.

### Configuration

Configure SwiftLint by adding a `.swiftlint.yml` file from the directory you'll
run SwiftLint from. The following parameters can be configured:

Rule inclusion:

* `disabled_rules`: Disable rules from the default enabled set.
* `opt_in_rules`: Enable rules not from the default set.
* `whitelist_rules`: Acts as a whitelist, only the rules specified in this list
  will be enabled. Can not be specified alongside `disabled_rules` or
  `opt_in_rules`.
* `analyzer_rules`: This is an entirely separate list of rules that are only
  run by the `analyze` command. All analyzer rules are opt-in, so this is the
  only configurable rule list (there is no disabled/whitelist equivalent).

```yaml
disabled_rules: # rule identifiers to exclude from running
  - colon
  - comma
  - control_statement
opt_in_rules: # some rules are only opt-in
  - empty_count
  # Find all the available rules by running:
  # swiftlint rules
included: # paths to include during linting. `--path` is ignored if present.
  - Source
excluded: # paths to ignore during linting. Takes precedence over `included`.
  - Carthage
  - Pods
  - Source/ExcludedFolder
  - Source/ExcludedFile.swift
  - Source/*/ExcludedFile.swift # Exclude files with a wildcard
analyzer_rules: # Rules run by `swiftlint analyze` (experimental)
  - explicit_self

# configurable rules can be customized from this configuration file
# binary rules can set their severity level
force_cast: warning # implicitly
force_try:
  severity: warning # explicitly
# rules that have both warning and error levels, can set just the warning level
# implicitly
line_length: 110
# they can set both implicitly with an array
type_body_length:
  - 300 # warning
  - 400 # error
# or they can set both explicitly
file_length:
  warning: 500
  error: 1200
# naming rules can set warnings/errors for min_length and max_length
# additionally they can set excluded names
type_name:
  min_length: 4 # only warning
  max_length: # warning and error
    warning: 40
    error: 50
  excluded: iPhone # excluded via string
identifier_name:
  min_length: # only min_length
    error: 4 # only error
  excluded: # excluded via string array
    - id
    - URL
    - GlobalAPIKey
reporter: "xcode" # reporter type (xcode, json, csv, checkstyle, junit, html, emoji, sonarqube, markdown)
```

You can also use environment variables in your configuration file,
by using `${SOME_VARIABLE}` in a string.

#### Defining Custom Rules

You can define custom regex-based rules in your configuration file using the
following syntax:

```yaml
custom_rules:
  pirates_beat_ninjas: # rule identifier
    included: ".*\\.swift" # regex that defines paths to include during linting. optional.
    excluded: ".*Test\\.swift" # regex that defines paths to exclude during linting. optional
    name: "Pirates Beat Ninjas" # rule name. optional.
    regex: "([n,N]inja)" # matching pattern
    match_kinds: # SyntaxKinds to match. optional.
      - comment
      - identifier
    message: "Pirates are better than ninjas." # violation message. optional.
    severity: error # violation severity. optional.
  no_hiding_in_strings:
    regex: "([n,N]inja)"
    match_kinds: string
```

This is what the output would look like:

![](assets/custom-rule.png)

You can filter the matches by providing one or more `match_kinds`, which will
reject matches that include syntax kinds that are not present in this list. Here
are all the possible syntax kinds:

* argument
* attribute.builtin
* attribute.id
* buildconfig.id
* buildconfig.keyword
* comment
* comment.mark
* comment.url
* doccomment
* doccomment.field
* identifier
* keyword
* number
* objectliteral
* parameter
* placeholder
* string
* string_interpolation_anchor
* typeidentifier

If using custom rules alongside a whitelist, make sure to add `custom_rules` as an item under `whitelist_rules`.

#### Nested Configurations

SwiftLint supports nesting configuration files for more granular control over
the linting process.

* Include additional `.swiftlint.yml` files where necessary in your directory
  structure.
* Each file will be linted using the configuration file that is in its
  directory or at the deepest level of its parent directories. Otherwise the
  root configuration will be used.
* `excluded` and `included` are ignored for nested
  configurations.

### Auto-correct

SwiftLint can automatically correct certain violations. Files on disk are
overwritten with a corrected version.

Please make sure to have backups of these files before running
`swiftlint autocorrect`, otherwise important data may be lost.

Standard linting is disabled while correcting because of the high likelihood of
violations (or their offsets) being incorrect after modifying a file while
applying corrections.

### Analyze (experimental)

The _experimental_ `swiftlint analyze` command can lint Swift files using the
full type-checked AST. The compiler log path containing the clean `swiftc` build
command invocation (incremental builds will fail) must be passed to `analyze`
via the `--compiler-log-path` flag.
e.g. `--compiler-log-path /path/to/xcodebuild.log`

This can be obtained by running
`xcodebuild -workspace {WORKSPACE}.xcworkspace -scheme {SCHEME} > xcodebuild.log`
with a clean `DerivedData` folder.

This command and related code in SwiftLint is subject to substantial changes at
any time while this feature is marked as experimental. Analyzer rules also tend
to be considerably slower than lint rules.

## License

[MIT licensed.](LICENSE)

## About

<img src="assets/realm.png" width="184" />

SwiftLint is maintained and funded by Realm Inc. The names and logos for
Realm are trademarks of Realm Inc.

We :heart: open source software!
See [our other open source projects](https://github.com/realm),
read [our blog](https://realm.io/news), or say hi on twitter
([@realm](https://twitter.com/realm)).
