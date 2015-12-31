## Master

##### Breaking

* Remove `Location.init(file:offset:)` in favor of the more explicit
  `Location.init(file:byteOffset:)` & `Location.init(file:characterOffset:)`.  
  [JP Simard](https://github.com/jpsim)

##### Enhancements

* Add `checkstyle` reporter to generate XML reports in the Checkstyle 4.3
  format.
  [JP Simard](https://github.com/jpsim)
  [#277](https://github.com/realm/SwiftLint/issues/277)

* Support command comment modifiers (`previous`, `this` & `next`) to limit the
  command's scope to a single line.
  [JP Simard](https://github.com/jpsim)
  [#222](https://github.com/realm/SwiftLint/issues/222)

* Add nested `.swiftlint.yml` configuration support.  
  [Scott Hoyt](https://github.com/scottrhoyt)
  [#299](https://github.com/realm/SwiftLint/issues/299)

##### Bug Fixes

* Fix multibyte handling in many rules.  
  [JP Simard](https://github.com/jpsim)
  [#279](https://github.com/realm/SwiftLint/issues/279)

* Fix an `NSRangeException` crash.  
  [Norio Nomura](https://github.com/norio-nomura)
  [#294](https://github.com/realm/SwiftLint/issues/294)

* The `valid_docs` rule now handles multibyte characters.  
  [Norio Nomura](https://github.com/norio-nomura)
  [#295](https://github.com/realm/SwiftLint/issues/295)

## 0.5.3: Mountain Scent

##### Breaking

* None.

##### Enhancements

* Improve autocorrect for OpeningBraceRule.  
  [Yasuhiro Inami](https://github.com/inamiy)

* Add autocorrect for ColonRule.  
  [Brian Partridge](https://github.com/brianpartridge)

* Add ClosingBraceRule.  
  [Yasuhiro Inami](https://github.com/inamiy)

##### Bug Fixes

* Fix false positives in ValidDocsRule.  
  [JP Simard](https://github.com/jpsim)
  [#267](https://github.com/realm/SwiftLint/issues/267)

## 0.5.2: Snuggle™

##### Breaking

* None.

##### Enhancements

* Performance improvements & unicode fixes (via SourceKitten).  
  [Norio Nomura](https://github.com/norio-nomura)

##### Bug Fixes

* Fix `ValidDocsRule` false positive when documenting functions with closure
  parameters.  
  [diogoguimaraes](https://github.com/diogoguimaraes)
  [#267](https://github.com/realm/SwiftLint/issues/267)

## 0.5.1: Lint Tray Malfunction

##### Breaking

* None.

##### Enhancements

* None.

##### Bug Fixes

* Make linting faster than 0.5.0, but slower than 0.4.0  
  [Norio Nomura](https://github.com/norio-nomura)
  [#119](https://github.com/jpsim/SourceKitten/issues/119)

* Re-introduce `--use-script-input-files` option for `lint` & `autocorrect`
  commands. Should also fix some issues when running SwiftLint from an Xcode
  build phase.  
  [JP Simard](https://github.com/jpsim)
  [#264](https://github.com/realm/SwiftLint/issues/264)

## 0.5.0: Downy™

##### Breaking

* `init()` is no longer a member of the `Rule` protocol.

##### Enhancements

* Add legacy constructor rule.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#202](https://github.com/realm/SwiftLint/issues/202)

* The `VariableNameRule` now allows variable names when the entire name is
  capitalized. This allows stylistic usage common in cases like `URL` and other
  acronyms.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#161](https://github.com/realm/SwiftLint/issues/161)

* Add `autocorrect` command to automatically correct certain violations
  (currently only `trailing_newline`, `trailing_semicolon` &
  `trailing_whitespace`).
  [JP Simard](https://github.com/jpsim)
  [#5](https://github.com/realm/SwiftLint/issues/5)

* Allow to exclude files from `included` directory with `excluded`.  
  [Michal Laskowski](https://github.com/michallaskowski)

##### Bug Fixes

* Statement position rule no longer triggers for non-keyword uses of `catch` and
  `else`.  
  [JP Simard](https://github.com/jpsim)
  [#237](https://github.com/realm/SwiftLint/issues/237)

* Fix issues with multi-byte characters.  
  [JP Simard](https://github.com/jpsim)
  [#234](https://github.com/realm/SwiftLint/issues/234)


## 0.4.0: Wrinkle Release

##### Breaking

* API: Rename RuleExample to RuleDescription, remove StyleViolationType and
  combine Rule().identifier and Rule().example into Rule.description.  
  [JP Simard](https://github.com/jpsim)
  [#183](https://github.com/realm/SwiftLint/issues/183)

##### Enhancements

* The `VariableNameRule` now allows capitalized variable names when they are
  declared static. This allows stylistic usage common in cases like
  `OptionSetType` subclasses.  
  [Will Fleming](https://github.com/wfleming)

* Add `VariableNameMaxLengthRule` and `VariableNameMinLengthRule` parameter
  rules. Remove length checks on `VariableNameRule`.  
  [Mickael Morier](https://github.com/mmorier)

* Add trailing semicolon rule.  
  [JP Simard](https://github.com/jpsim)

* Add force try rule.  
  [JP Simard](https://github.com/jpsim)

* Support linting from Input Files provided by Run Script Phase of Xcode with
  `--use-script-input-files`.  
  [Norio Nomura](https://github.com/norio-nomura)
  [#193](https://github.com/realm/SwiftLint/pull/193)

##### Bug Fixes

* All rules now print their identifiers in reports.  
  [JP Simard](https://github.com/jpsim)
  [#180](https://github.com/realm/SwiftLint/issues/180)

* `ControlStatementRule` now detects all violations.  
  [Mickael Morier](https://github.com/mmorier)
  [#187](https://github.com/realm/SwiftLint/issues/187)

* `ControlStatementRule` no longer triggers a violation for acceptable use of
  parentheses.  
  [Mickael Morier](https://github.com/mmorier)
  [#189](https://github.com/realm/SwiftLint/issues/189)

* Nesting rule no longer triggers a violation for enums nested one level deep.  
  [JP Simard](https://github.com/jpsim)
  [#190](https://github.com/realm/SwiftLint/issues/190)

* `ColonRule` now triggers a violation even if equal operator is collapse to
  type and value.  
  [Mickael Morier](https://github.com/mmorier)
  [#135](https://github.com/realm/SwiftLint/issues/135)

* Fix an issue where logs would be printed asynchronously over each other.  
  [JP Simard](https://github.com/jpsim)
  [#200](https://github.com/realm/SwiftLint/issues/200)


## 0.3.0: Wrinkly Rules

##### Breaking

* `swiftlint rules` now just prints a list of all available rules and their
  identifiers.

##### Enhancements

* Support for Swift 2.1.  
  [JP Simard](https://github.com/jpsim)

* Added `StatementPositionRule` to make sure that catch, else if and else
  statements are on the same line as closing brace preceding them and after one
  space.  
  [Alex Culeva](https://github.com/S2dentik)

* Added `Comma Rule` to ensure there is a single space after a comma.  
  [Alex Culeva](https://github.com/S2dentik)

* Add rule identifier to all linter reports.  
  [zippy1978](https://github.com/zippy1978)

* Add `OpeningBraceRule` to make sure there is exactly a space before opening
  brace and it is on the same line as declaration.
  [Alex Culeva](https://github.com/S2dentik)

* Print to stderr for all informational logs. Only reporter outputs is logged to
  stdout.  
  [JP Simard](https://github.com/jpsim)

* JSON and CSV reporters now only print at the very end of the linting
  process.  
  [JP Simard](https://github.com/jpsim)

* Add support for `guard` statements to ControlStatementRule.  
  [David Potter](https://github.com/Tableau-David-Potter)

* Lint parameter variables.  
  [JP Simard](https://github.com/jpsim)

##### Bug Fixes

* Custom reporters are now supported even when not running with `--use-stdin`.  
  [JP Simard](https://github.com/jpsim)
  [#151](https://github.com/realm/SwiftLint/issues/151)

* Deduplicate files in the current directory.  
  [JP Simard](https://github.com/jpsim)
  [#154](https://github.com/realm/SwiftLint/issues/154)


## 0.2.0: Tumble Dry

##### Breaking

* SwiftLint now exclusively supports Swift 2.0.  
  [JP Simard](https://github.com/jpsim)
  [#77](https://github.com/realm/SwiftLint/issues/77)

* `ViolationSeverity` now has an associated type of `String` and two members:
  `.Warning` and `.Error`.  
  [JP Simard](https://github.com/jpsim)
  [#113](https://github.com/realm/SwiftLint/issues/113)

##### Enhancements

* Configure SwiftLint via a YAML file:
  Supports `disabled_rules`, `included`, `excluded` and passing parameters to
  parameterized rules.
  Pass a configuration file path to `--config`, defaults to `.swiftlint.yml`.  
  [JP Simard](https://github.com/jpsim)
  [#1](https://github.com/realm/SwiftLint/issues/1)
  [#3](https://github.com/realm/SwiftLint/issues/3)
  [#20](https://github.com/realm/SwiftLint/issues/20)
  [#26](https://github.com/realm/SwiftLint/issues/26)

* Updated `TypeNameRule` and `VariableNameRule` to allow private type & variable
  names to start with an underscore.
  [JP Simard](https://github.com/jpsim)

* Disable and re-enable rules from within source code comments using
  `// swiftlint:disable $IDENTIFIER` and `// swiftlint:enable $IDENTIFIER`.  
  [JP Simard](https://github.com/jpsim)
  [#4](https://github.com/realm/SwiftLint/issues/4)

* Add `--strict` lint flag which makes the lint fail if there are any
  warnings.  
  [Keith Smiley](https://github.com/keith)

* Violations are now printed to stderr.  
  [Keith Smiley](https://github.com/keith)

* Custom reporters are now supported. Specify a value for the `reporter:` key in
  your configuration file. Available reporters are `xcode` (default), `json`,
  `csv`.  
  [JP Simard](https://github.com/jpsim)
  [#42](https://github.com/realm/SwiftLint/issues/42)

##### Bug Fixes

* Improve performance of `TrailingWhitespaceRule`.  
  [Keith Smiley](https://github.com/keith)

* Allow newlines in function return arrow.  
  [JP Simard](https://github.com/jpsim)


## 0.1.2: FabricSoftenerRule

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
