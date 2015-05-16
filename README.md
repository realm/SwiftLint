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

## Command Line Usage

```shell
$ swiftlint help
Available commands:

   help      Display general or command-specific help
   lint      Print lint warnings and errors for the Swift files in the current directory
   version   Display the current version of SwiftLint
```

Run `swiftlint` in the directory containing the Swift files to lint. SwiftLint
will search files recursively in the current directory.

## License

MIT licensed.
