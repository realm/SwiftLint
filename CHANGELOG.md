## Master

##### Breaking

* None.

##### Enhancements

* Added `OperatorFunctionWhitespaceRule` to make sure that
  you use whitespace around operators when defining them.  
  [Akira Hirakawa](https://github.com/akirahrkw)
  [#60](https://github.com/realm/SwiftLint/issues/60)

* Added `ReturnArrowWhitespaceRule` to make sure that
  you have 1 space before return arrow and return type.  
  [Akira Hirakawa](https://github.com/akirahrkw)

* Support linting from standard input (use `--use-stdin`).  
  [JP Simard](https://github.com/jpsim)
  [#78](https://github.com/realm/SwiftLint/issues/78)

* Improve performance of `TrailingNewlineRule`.  
  [Keith Smiley](https://github.com/keith)

* Lint parentheses around switch statements.  
  [Keith Smiley](https://github.com/keith)

##### Bug Fixes

* None.


## 0.1.1: Top Loading

##### Breaking

* The `Rule` and `ASTRule` protocol members are now non-static.  
  [aarondaub](https://github.com/aarondaub)

* Split `Rule` into `Rule` and `ParameterizedRule` protocols.  
  [aarondaub](https://github.com/aarondaub)
  [#21](https://github.com/realm/SwiftLint/issues/21)

##### Enhancements

* Added a command line option `--path` to specify a path to lint.  
  [Lars Lockefeer](https://github.com/larslockefeer)
  [#16](https://github.com/realm/SwiftLint/issues/16)

* swiftlint now returns a non-zero error code when a warning of high-severity
  or above is found in the source files being linted.  
  [Pat Wallace](https://github.com/pawrsccouk)
  [#30](https://github.com/realm/SwiftLint/issues/30)

* Added `rules` command to display which rules are currently applied along
  with examples.  
  [Chris Eidhof](https://github.com/chriseidhof)

* Cache parsing to reduce execution time by more than 50%.  
  [Nikolaj Schumacher](https://github.com/nschum)

* Added `ControlStatementRule` to make sure that if/for/while/do statements
  do not wrap their conditionals in parentheses.  
  [Andrea Mazzini](https://github.com/andreamazz)

* Character position is now included in violation location where appropriate.  
  [JP Simard](https://github.com/jpsim)
  [#62](https://github.com/realm/SwiftLint/issues/62)

* The following rules now conform to `ASTRule`:
  FunctionBodyLength, Nesting, TypeBodyLength, TypeName, VariableName.  
  [JP Simard](https://github.com/jpsim)

##### Bug Fixes

* Trailing newline and file length violations are now displayed in Xcode.  
  [JP Simard](https://github.com/jpsim)
  [#43](https://github.com/realm/SwiftLint/issues/43)


## 0.1.0: Fresh Out Of The Dryer

First Version!
