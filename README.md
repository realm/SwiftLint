# SwiftLint

An experimental tool to enforce Swift style and conventions, loosely based on
[GitHub's Swift Style Guide](https://github.com/github/swift-style-guide).

SwiftLint hooks into [Clang](http://clang.llvm.org) and
[SourceKit](http://www.jpsim.com/uncovering-sourcekit) to use the
[AST](http://clang.llvm.org/docs/IntroductionToTheClangAST.html) representation
of your source files for more accurate results.

![Test Status](https://travis-ci.org/realm/SwiftLint.svg?branch=master)

## Installation

Using [Homebrew](http://brew.sh/)

```
brew install swiftlint
```

You can also install SwiftLint by downloading `SwiftLint.pkg` from the
[latest GitHub release](https://github.com/realm/SwiftLint/releases/latest) and
running it.

You can also build from source by cloning this project and running
`git submodule update --init --recursive; make install` (Xcode 7 Beta 6 required).

## Usage

### Xcode

Integrate SwiftLint into an Xcode scheme to get warnings and errors displayed
in the IDE. Just add a new "Run Script Phase" with `/usr/local/bin/swiftlint`
as its contents. Like this:
![](http://i.imgur.com/K0DaKq4.png)

![](screenshot.png)

### Atom

To integrate SwiftLint with [Atom](https://atom.io/) install the
[`linter-swiftlint`](https://atom.io/packages/linter-swiftlint) package from
APM.

### Command Line

```
$ swiftlint help
Available commands:

   help      Display general or command-specific help
   lint      Print lint warnings and errors for the Swift files in the current directory (default command)
   rules     Display the list of rules and their identifiers
   version   Display the current version of SwiftLint
```

Run `swiftlint` in the directory containing the Swift files to lint. Directories
will be searched recursively.

## Rules

There are only a small number of rules currently implemented, but we hope the
Swift community (that's you!) will contribute more over time. Pull requests are
encouraged.

The rules that *are* currently implemented are mostly there as a starting point
and are subject to change.

See the [Source/SwiftLintFramework/Rules](Source/SwiftLintFramework/Rules)
directory to see the currently implemented rules.

### Disable a rule in code

Rules can be disabled with a comment inside a source file with the following format: 

`/// swiftlint:disable <rule>`

The rule will be disabled until the end of the file or until the linter sees a matching enable comment:

`/// swiftlint:enable <rule>`

For example:

```swift
/// swiftlint:disable colon
let noWarning :String = "" // No warning about colons immediately after variable names!
/// swiftlint:enable colon
let yesWarning :String = "" // Warning generated about colons immediately after variable names
```

Run `swiftlint rules` to print a list of all available rules and their identifiers.

### Configuration

Configure SwiftLint by adding a `.swiftlint.yml` file from the directory you'll
run SwiftLint from. The following parameters can be configured:

```yaml
disabled_rules: # rule identifiers to exclude from running
  - colon
  - control_statement
  - file_length
  - force_cast
  - function_body_length
  - leading_whitespace
  - line_length
  - nesting
  - operator_whitespace
  - return_arrow_whitespace
  - todo
  - trailing_newline
  - trailing_whitespace
  - type_body_length
  - type_name
  - variable_name
included: # paths to include during linting. `--path` is ignored if present. takes precendence over `excluded`.
  - Source
excluded: # paths to ignore during linting. overridden by `included`.
  - Carthage
  - Pods
```

## License

MIT licensed.
