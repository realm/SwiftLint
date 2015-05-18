# SwiftLint

An experimental tool to enforce Swift style and conventions, loosely based on
[GitHub's Swift Style Guide](https://github.com/github/swift-style-guide).

SwiftLint hooks into [Clang](http://clang.llvm.org) and
[SourceKit](http://www.jpsim.com/uncovering-sourcekit) to use the
[AST](http://clang.llvm.org/docs/IntroductionToTheClangAST.html) representation
of your source files for more accurate results.

## Installation

Installation requires [Homebrew](http://brew.sh).

`$ brew install swiftlint`

## Usage

### Xcode

Integrate SwiftLint into an Xcode scheme to get warnings and errors displayed
in the IDE. Just add a new "Run Script Phase" with `swiftlint` as its contents.

![](screenshot.png)

### Command Line

```
$ swiftlint help
Available commands:

   help      Display general or command-specific help
   lint      Print lint warnings and errors for the Swift files in the current directory (default command)
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

See the [Source/SwiftLintFramework/Rules](tree/master/Source/SwiftLintFramework/Rules) directory to see the currently
implemented rules.

## License

MIT licensed.
