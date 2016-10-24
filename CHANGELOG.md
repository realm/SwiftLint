## Master

##### Breaking

* None.

##### Enhancements

* Add `SuperCallRule` Opt-In rule that warns about methods not calling to super.  
  [Angel G. Olloqui](https://github.com/angelolloqui)
  [#803](https://github.com/realm/SwiftLint/issues/803)
  
* Add `RedundantNilCoalesingRule` Opt-In rule that warns against `?? nil`.  
  [Daniel Beard](https://github.com/daniel-beard)
  [#764](https://github.com/realm/SwiftLint/issues/764)

* Added opt-In rule to makes closure expressions spacing consistent.  
  [J. Cheyo Jimenez](https://github.com/masters3d)
  [#770](https://github.com/realm/SwiftLint/issues/770)

* Adds `allow_private_set` configuration for the `private_outlet` rule.  
  [Rohan Dhaimade](https://github.com/HaloZero)

* Swift 2.3 support.  
  [Norio Nomura](https://github.com/norio-nomura),
  [Syo Ikeda](https://github.com/ikesyo)

* Color literals count as single characters to avoid unintentional line length
  violations.  
  [Jonas](https://github.com/VFUC)
  [#742](https://github.com/realm/SwiftLint/issues/742)
  
* Add `SwitchCaseOnNewlineRule' opt-in rule that enforces a newline after
  `case pattern:` in a `switch`.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#681](https://github.com/realm/SwiftLint/issues/681)

##### Bug Fixes

* Fixed whitespace being added to TODO messages.  
  [W. Bagdon](https://github.com/wbagdon)
  [#792](https://github.com/realm/SwiftLint/issues/792)

* Fixed regex bug in Vertical Whitespace Rule by using SourceKitten instead.
  The rule now enabled by default again (no longer opt-in).  
  [J. Cheyo Jimenez](https://github.com/masters3d)
  [#772](https://github.com/realm/SwiftLint/issues/772)

* Fixed regex bug in Mark Rule where MARK could not be used with only a hyphen
  but no descriptive text: `// MARK: -`.  
  [Ruotger Deecke](https://github.com/roddi)
  [#778](https://github.com/realm/SwiftLint/issues/778)

* Fixed: Private unit test rule not scoped to test classes.  
  Fixed: Private unit test rule config is ignored if regex is missing.  
  [Cristian Filipov](https://github.com/cfilipov)
  [#786](https://github.com/realm/SwiftLint/issues/786)

* Fixed: `ConditionalReturnsOnNewline' now respects severity configuration.  
  [Rohan Dhaimade](https://github.com/HaloZero)
  [#783](https://github.com/realm/SwiftLint/issues/783)
  
* Fixed: `ConditionalReturnsOnNewline' now checks if `return` is a keyword,
  avoiding false positives.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#784](https://github.com/realm/SwiftLint/issues/784)

## 0.12.0: Vertical Laundry

##### Breaking

* Fixed: SwiftLint assumes paths in the YAML config file are relative to the
  current directory even when `--path` is passed as an argument.  
  [Cristian Filipov](https://github.com/cfilipov)

##### Enhancements

* None.

##### Bug Fixes

* Made Vertical Whitespace Rule added in 0.11.2 opt-in due to performance
  issues.  
  [JP Simard](https://github.com/jpsim)
  [#772](https://github.com/realm/SwiftLint/issues/772)

## 0.11.2: Communal Clothesline

This release has seen a phenomenal uptake in community contributions!

##### Breaking

* None.

##### Enhancements

* Add `MarkRule` rule to enforce `// MARK` syntax.  
  [Krzysztof Rodak](https://github.com/krodak)
  [#749](https://github.com/realm/SwiftLint/issues/749)

* Add `PrivateOutletRule` Opt-In rule to enforce `@IBOutlet`
  instance variables to be `private`.  
  [Olivier Halligon](https://github.com/AliSoftware)

* Add content of the todo statement to message.  
  [J. Cheyo Jimenez](https://github.com/masters3d)
  [#478](https://github.com/realm/SwiftLint/issues/478)

* Add `LegacyNSGeometryFunctionsRule` rule. Add `NSSize`, `NSPoint`, and
  `NSRect` constants and constructors to existing rules.  
  [David Rönnqvist](https://github.com/d-ronnqvist)

* Added Vertical Whitespace Rule.  
  [J. Cheyo Jimenez](https://github.com/masters3d)
  [#548](https://github.com/realm/SwiftLint/issues/548)

* Removed ConditionalBindingCascadeRule.  
  [J. Cheyo Jimenez](https://github.com/masters3d)
  [#701](https://github.com/realm/SwiftLint/issues/701)

* Allow setting `flexible_right_spacing` configuration for the `colon` rule.  
  [Shai Mishali](https://github.com/freak4pc)
  [#730](https://github.com/realm/SwiftLint/issues/730)

* Add Junit reporter.  
  [Matthew Ellis](https://github.com/matthewellis)

* LeadingWhitespaceRule is now auto correctable.  
  [masters3d](https://github.com/masters3d)

* Add included regex for custom rules to control what files are processed.  
  [bootstraponline](https://github.com/bootstraponline)
  [#689](https://github.com/realm/SwiftLint/issues/689)

* Add rule to check for private unit tests (private unit tests don't get run
  by XCTest).  
  [Cristian Filipov](https://github.com/cfilipov)

* Add configuration for setting a warning threshold.  
  [woodhamgh](https://github.com/woodhamgh)
  [696](https://github.com/realm/SwiftLint/issues/696)

* Adds 'ConditionalReturnsOnNewLineRule' rule.  
  [Rohan Dhaimade](https://github.com/HaloZero)

* Made `- returns:` doc optional for initializers.  
  [Mohpor](https://github.com/mohpor)
  [#557](https://github.com/realm/SwiftLint/issues/557)

##### Bug Fixes

* Fixed CustomRule Regex.  
  [J. Cheyo Jimenez](https://github.com/masters3d)
  [#717](https://github.com/realm/SwiftLint/issues/717)
  [#726](https://github.com/realm/SwiftLint/issues/726)

* Allow disabling custom rules in code.  
  [J. Cheyo Jimenez](https://github.com/masters3d)
  [#515](https://github.com/realm/SwiftLint/issues/515)

* Fix LegacyConstructorRule when using variables instead of numbers.  
  [Sarr Blaise](https://github.com/bsarr007)
  [#646](https://github.com/realm/SwiftLint/issues/646)

* Fix force_unwrapping false positive inside strings.  
  [Daniel Beard](https://github.com/daniel-beard)
  [#721](https://github.com/realm/SwiftLint/issues/721)

## 0.11.1: Cuddles... Or Else!

##### Breaking

* None.

##### Enhancements

* Added `statement_mode` configuration to  the `statement_position` rule. The   
  `default` mode keeps the current SwiftLint behavior of keeping `else` and
  `catch` statements on the same line as the closing brace before them. The
  `uncuddled_else`configuration requires the `else` and `catch` to be on a new
  line with the same leading whitespace as the brace.  
  [Mike Skiba](https://github.com/ateliercw)
  [#651](https://github.com/realm/SwiftLint/issues/651)

##### Bug Fixes

* Remove extraneous argument label added in LegacyCGGeometryFunctionsRule
  autocorrect.  
  [Sarr Blaise](https://github.com/bsarr007)
  [643](https://github.com/realm/SwiftLint/issues/643)

## 0.11.0: Laundromat Format

##### Breaking

* Now `type_name` allows lowercase enum values to match the Swift API Design
  Guidelines.  
  [Jorge Bernal](https://github.com/koke)
  [#654](https://github.com/realm/SwiftLint/issues/654)

* Embedding frameworks needed by `swiftlint` was moved from
  SwiftLintFramework Xcode target to the swiftlint target.
  The `SwiftLintFramework.framework` product built by the
  SwiftLintFramework target no longer contains unnecessary frameworks or
  multiple copies of the Swift libraries.  
  [Norio Nomura](https://github.com/norio-nomura)

##### Enhancements

* Add `--format` option to `autocorrect` command which re-indents Swift files
  much like pasting into Xcode would. This option isn't currently configurable,
  but that can change if users request it.  
  [JP Simard](https://github.com/jpsim)

* Improve error messages for invalid configuration files.  
  [Brian Hardy](https://github.com/lyricsboy)

* Added the user-configurable option `ignores_empty_lines` to the
  `trailing_whitespace` rule. It can be used to control whether the
  `TrailingWhitespaceRule` should report and correct whitespace-indented empty
  lines. Defaults to `false`. Added unit tests.  
  [Reimar Twelker](https://github.com/raginmari)

##### Bug Fixes

* Fix false positive in conditional binding cascade violation.  
  [Norio Nomura](https://github.com/norio-nomura)
  [#642](https://github.com/realm/SwiftLint/issues/642)

* Another conditional binding fix, this time for enum that has two parameters
  or an if statement with two case tests.  
  [Andrew Rahn](https://github.com/paddlefish)
  [#667](https://github.com/realm/SwiftLint/issues/667)

* Fix regression in CommaRule ignoring violations when the comma is followed
  by a comment.  
  [Norio Nomura](https://github.com/norio-nomura)
  [#683](https://github.com/realm/SwiftLint/issues/683)

## 0.10.0: `laundry-select` edition

##### Breaking

* None.

##### Enhancements

* Now `libclang.dylib` and `sourcekitd.framework` are dynamically loaded at
  runtime by SourceKittenFramework to use the versions included in the Xcode
  version specified by `xcode-select -p` or custom toolchains.  
  [Norio Nomura](https://github.com/norio-nomura)
  [#167](https://github.com/jpsim/SourceKitten/issues/167)

* Add `LegacyCGGeometryFunctionsRule` rule.  
  [Sarr Blaise](https://github.com/bsarr007)
  [#625](https://github.com/realm/SwiftLint/issues/625)

* SwiftLint no longer crashes when SourceKitService crashes.  
  [Norio Nomura](https://github.com/norio-nomura)

* Rewrite `conditional_binding_cascade` rule.  
  [Norio Nomura](https://github.com/norio-nomura)
  [#617](https://github.com/realm/SwiftLint/issues/617)

* Add autocorrect for `ReturnArrowWhitespaceRule`.  
  [Craig Siemens](https://github.com/CraigSiemens)

##### Bug Fixes

* Failed to launch swiftlint when Xcode.app was placed at non standard path.  
  [Norio Nomura](https://github.com/norio-nomura)
  [#593](https://github.com/realm/SwiftLint/issues/593)

* `ClosingBraceRule` no longer triggers across line breaks.  
  [Josh Friend](https://github.com/joshfriend)
  [#592](https://github.com/realm/SwiftLint/issues/592)

* `LegacyConstantRule` and `LegacyConstructorRule` failed to `autocorrect`.  
  [Norio Nomura](https://github.com/norio-nomura)
  [#623](https://github.com/realm/SwiftLint/issues/623)

## 0.9.2: Multiple Exhaust Codes

##### Breaking

* None.

##### Enhancements

* Return different exit codes to distinguish between types of errors:
  * 0: No errors, maybe warnings in non-strict mode
  * 1: Usage or system error
  * 2: Style violations of severity "Error"
  * 3: No style violations of severity "Error", but violations of severity
       "warning" with `--strict`  
  [JP Simard](https://github.com/jpsim)
  [#166](https://github.com/realm/SwiftLint/issues/166)

* `VariableNameRule` now accepts symbols starting with more than one uppercase
  letter to allow for names like XMLString or MIMEType.  
  [Erik Aigner](https://github.com/eaigner)
  [#566](https://github.com/realm/SwiftLint/issues/566)

##### Bug Fixes

* Avoid overwriting files whose contents have not changed.  
  [Neil Gall](https://github.com/neilgall)
  [#574](https://github.com/realm/SwiftLint/issues/574)

* Fix `CommaRule` mismatch between violations and corrections.  
  [Norio Nomura](https://github.com/norio-nomura)
  [#466](https://github.com/realm/SwiftLint/issues/466)

* Fix more false positives in `ForceUnwrappingRule`.  
  [Norio Nomura](https://github.com/norio-nomura)
  [#546](https://github.com/realm/SwiftLint/issues/546)
  [#547](https://github.com/realm/SwiftLint/issues/547)

## 0.9.1: Air Duct Cleaning

##### Breaking

* None.

##### Enhancements

* None.

##### Bug Fixes

* Fix force unwrap rule missed cases with quotes.  
  [Norio Nomura](https://github.com/norio-nomura)
  [#535](https://github.com/realm/SwiftLint/issues/535)

* Fix issues with nested `.swiftlint.yml` file resolution.  
  [Norio Nomura](https://github.com/norio-nomura)
  [#543](https://github.com/realm/SwiftLint/issues/543)

## 0.9.0: Appliance Maintenance

##### Breaking

* `Linter.reporter` has been removed and `Configuration.reporterFromString(_:)`
  has been renamed to a free function: `reporterFromString(_:)`.  
  [JP Simard](https://github.com/jpsim)

* `_ConfigProviderRule` & `ConfigurableRule` have been removed and their
  requirements have been moved to `Rule`.  
  [JP Simard](https://github.com/jpsim)

* `Configuration(path:optional:silent)` has been changed to
  `Configuration(path:rootPath:optional:quiet:)`.  
  [JP Simard](https://github.com/jpsim)

* The static function `Configuration.rulesFromDict(_:ruleList:)` has been moved
  to an instance method: `RuleList.configuredRulesWithDictionary(_:)`.  
  [JP Simard](https://github.com/jpsim)

* The `rules` parameter in the `Configuration` initializer has been renamed to
  `configuredRules`.  
  [JP Simard](https://github.com/jpsim)

* Removed a large number of declarations from the public SwiftLintFramework API.
  This is being done to minimize the API surface area in preparation of a 1.0
  release. See [#507](https://github.com/realm/SwiftLint/pull/507) for a
  complete record of this change.  
  [JP Simard](https://github.com/jpsim)
  [#479](https://github.com/realm/SwiftLint/issues/479)

* All instances of the abbreviation "config" in the API have been expanded to
  "configuration". The `--config` command line parameter and
  `use_nested_configs` configuration key are unaffected.  
  [JP Simard](https://github.com/jpsim)

* The `use_nested_configs` configuration key has been deprecated and its value
  is now ignored. Nested configuration files are now always considered.  
  [JP Simard](https://github.com/jpsim)

##### Enhancements

* `swiftlint lint` now accepts an optional `--reporter` parameter which
  overrides existing `reporter` values in the configuration file. Choose between
  `xcode` (default), `json`, `csv` or `checkstyle`.  
  [JP Simard](https://github.com/jpsim)
  [#440](https://github.com/realm/SwiftLint/issues/440)

* `swiftlint rules` now shows a configuration description for all rules.  
  [JP Simard](https://github.com/jpsim)

* `lint` and `autocorrect` commands now accept a `--quiet` flag that prevents
  status messages like 'Linting <file>' & 'Done linting' from being logged.  
  [JP Simard](https://github.com/jpsim)
  [#386](https://github.com/realm/SwiftLint/issues/386)

* All top-level keys in a configuration file that accept an array now also
  accept a single value.  
  e.g. `included: Source` is equivalent to `included:\n  - Source`.  
  [JP Simard](https://github.com/jpsim)
  [#120](https://github.com/realm/SwiftLint/issues/120)

* Improve performance of `FunctionParameterCountRule`.  
  [Norio Nomura](https://github.com/norio-nomura)

* Improve performance of `ColonRule`.  
  [Norio Nomura](https://github.com/norio-nomura)

##### Bug Fixes

* Fix case sensitivity of keywords for `valid_docs`.  
  [Ankit Aggarwal](https://github.com/aciidb0mb3r)
  [#298](https://github.com/realm/SwiftLint/issues/298)

* Fixed inconsistencies between violations & corrections in
  `StatementPositionRule`.  
  [JP Simard](https://github.com/jpsim)
  [#466](https://github.com/realm/SwiftLint/issues/466)

* A warning will now be logged when invalid top-level keys are included in the
  configuration file.  
  [JP Simard](https://github.com/jpsim)
  [#120](https://github.com/realm/SwiftLint/issues/120)

* Fixed `LegacyConstructorRule` from correcting legacy constructors in string
  literals.  
  [JP Simard](https://github.com/jpsim)
  [#466](https://github.com/realm/SwiftLint/issues/466)

* Fixed an issue where `variable_name` or `type_name` would always report a
  violation when configured with only a `warning` value on either `min_length`
  or `max_length`.  
  [JP Simard](https://github.com/jpsim)
  [#522](https://github.com/realm/SwiftLint/issues/522)

## 0.8.0: High Heat

##### Breaking

* Setting only warning on `SeverityLevelsConfig` rules now disables the error
  value.  
  [Robin Kunde](https://github.com/robinkunde)
  [#409](https://github.com/realm/SwiftLint/issues/409)

* `enabled_rules` has been renamed to `opt_in_rules`.  
  [Daniel Beard](https://github.com/daniel-beard)

##### Enhancements

* Add `whitelist_rules` rule whitelists in config files.  
  [Daniel Beard](https://github.com/daniel-beard)
  [#256](https://github.com/realm/SwiftLint/issues/256)

* Improve performance of `ColonRule`, `LineLengthRule` & `syntaxKindsByLine`.  
  [Norio Nomura](https://github.com/norio-nomura)

* Add command to display rule description:
  `swiftlint rules <rule identifier>`.  
  [Tony Li](https://github.com/crazytonyli)
  [#392](https://github.com/realm/SwiftLint/issues/392)

* Add `FunctionParameterCountRule`.  
  [Denis Lebedev](https://github.com/garnett)
  [#415](https://github.com/realm/SwiftLint/issues/415)

* Measure complexity of nested functions separately in
  `CyclomaticComplexityRule`.  
  [Denis Lebedev](https://github.com/garnett)
  [#424](https://github.com/realm/SwiftLint/issues/424)

* Added exception for multi-line `if`/`guard`/`while` conditions to allow
  opening brace to be on a new line in `OpeningBraceRule`.  
  [Scott Hoyt](https://github.com/scottrhoyt)
  [#355](https://github.com/realm/SwiftLint/issues/355)

* The `rules` command now prints a table containing values for: `identifier`,
  `opt-in`, `correctable`, `enabled in your config` & `configuration`.  
  [JP Simard](https://github.com/jpsim)
  [#392](https://github.com/realm/SwiftLint/issues/392)

* Reduce maximum memory usage.  
  [Norio Nomura](https://github.com/norio-nomura)

##### Bug Fixes

* Fix more false positives in `ValidDocsRule`.  
  [diogoguimaraes](https://github.com/diogoguimaraes)
  [#451](https://github.com/realm/SwiftLint/issues/451)

* Fix `trailing_newline` autocorrect to handle more than one violation per
  line.  
  [Daniel Beard](https://github.com/daniel-beard)
  [#465](https://github.com/realm/SwiftLint/issues/465)

* Fix complexity measurement for switch statements in `CyclomaticComplexityRule`.  
  [Denis Lebedev](https://github.com/garnett)
  [#461](https://github.com/realm/SwiftLint/issues/461)

## 0.7.2: Appliance Manual

##### Breaking

* None.

##### Enhancements

* None.

##### Bug Fixes

* Fix several false positives in `ValidDocsRule`.  
  [diogoguimaraes](https://github.com/diogoguimaraes)
  [#375](https://github.com/realm/SwiftLint/issues/375)

## 0.7.1: Delicate Cycle

##### Breaking

* None.

##### Enhancements

* Improve performance of `MissingDocsRule`.  
  [Norio Nomura](https://github.com/norio-nomura)

* Added `CustomRules`.  
  [Scott Hoyt](https://github.com/scottrhoyt)  
  [#123](https://github.com/realm/SwiftLint/issues/123)

* Added opt-in `ForceUnwrappingRule` to issue warnings for all forced
  unwrappings.  
  [Benjamin Otto](https://github.com/Argent)
  [#55](https://github.com/realm/SwiftLint/issues/55)

##### Bug Fixes

* Fix several false positives in `ValidDocsRule`.  
  [diogoguimaraes](https://github.com/diogoguimaraes)
  [#375](https://github.com/realm/SwiftLint/issues/375)

## 0.7.0: Automatic Permanent Press

##### Breaking

* Replaced all uses of `XPCDictionary` with
  `[String: SourceKitRepresentable]`.  
  [JP Simard](https://github.com/jpsim)

* `VariableNameMinLengthRule` and `VariableNameMaxLengthRule` have been
  removed. `VariableNameRule` now has this functionality.  
  [Scott Hoyt](https://github.com/scottrhoyt)

* `ViolationLevelRule` has been removed. This functionality is now provided
  by `ConfigProviderRule` and `SeverityLevelsConfig`.  
  [Scott Hoyt](https://github.com/scottrhoyt)

##### Enhancements

* `TypeBodyLengthRule` now does not count comment or whitespace lines.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#369](https://github.com/realm/SwiftLint/issues/369)

* `FunctionBodyLengthRule` now does not count comment or whitespace lines.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#258](https://github.com/realm/SwiftLint/issues/258)

* All `Rule`s are now configurable in at least their severity: `SeverityConfig`.  
  [Scott Hoyt](https://github.com/scottrhoyt)
  [#371](https://github.com/realm/SwiftLint/issues/371)
  [#130](https://github.com/realm/SwiftLint/issues/130)
  [#268](https://github.com/realm/SwiftLint/issues/268)

* `TypeNameRule` and `VariableNameRule` conform to `ConfigProviderRule` using
  `NameConfig` to support `min_length`, `max_length`, and `excluded` names.  
  [Scott Hoyt](https://github.com/scottrhoyt)
  [#388](https://github.com/realm/SwiftLint/issues/388)
  [#259](https://github.com/realm/SwiftLint/issues/259)
  [#191](https://github.com/realm/SwiftLint/issues/191)

* Add `CyclomaticComplexityRule`.  
  [Denis Lebedev](https://github.com/garnett)

##### Bug Fixes

* Fix crash caused by infinite recursion when using nested config files.  
  [JP Simard](https://github.com/jpsim)
  [#368](https://github.com/realm/SwiftLint/issues/368)

* Fix crash when file contains NULL character.  
  [Norio Nomura](https://github.com/norio-nomura)
  [#379](https://github.com/realm/SwiftLint/issues/379)

## 0.6.0: Steam Cycle

##### Breaking

* `ParameterizedRule` is removed. Use `ConfigurableRule` instead.  
  [Scott Hoyt](https://github.com/scottrhoyt)
  [#353](https://github.com/realm/SwiftLint/issues/353)

* To activate a `Rule`, it must be added to the global `masterRuleList`.  
  [Scott Hoyt](https://github.com/scottrhoyt)

##### Enhancements

* `ConfigurableRule` protocol allows for improved rule configuration. See
  `CONTRIBUTING` for more details.  
  [Scott Hoyt](https://github.com/scottrhoyt)
  [#303](https://github.com/realm/SwiftLint/issues/303)

* `VariableNameMinLengthRule` now supports excluding certain variable names
  (e.g. "id").  
  [Scott Hoyt](https://github.com/scottrhoyt)
  [#231](https://github.com/realm/SwiftLint/issues/231)

* `ViolationLevelRule` provides default `ConfigurableRule` implementation for
  rules that only need integer error and warning levels.  
  [Scott Hoyt](https://github.com/scottrhoyt)

* Add AutoCorrect for StatementPositionRule.  
  [Raphael Randschau](https://github.com/nicolai86)

* Add AutoCorrect for CommaRule.  
  [Raphael Randschau](https://github.com/nicolai86)

* Add AutoCorrect for LegacyConstructorRule.  
  [Raphael Randschau](https://github.com/nicolai86)

* Improve performance of `LineLengthRule`.  
  [Norio Nomura](https://github.com/norio-nomura)

* Add ConditionalBindingCascadeRule.  
  [Aaron McTavish](https://github.com/aamctustwo)
  [#202](https://github.com/realm/SwiftLint/issues/202)

* Opt-in rules are now supported.  
  [JP Simard](https://github.com/jpsim)
  [#256](https://github.com/realm/SwiftLint/issues/256)

* Add LegacyConstantRule.  
  [Aaron McTavish](https://github.com/aamctustwo)
  [#319](https://github.com/realm/SwiftLint/issues/319)

* Add opt-in rule to encourage checking `isEmpty` over comparing `count` to
  zero.  
  [JP Simard](https://github.com/jpsim)
  [#202](https://github.com/realm/SwiftLint/issues/202)

* Add opt-in "Missing Docs" rule to detect undocumented public declarations.  
  [JP Simard](https://github.com/jpsim)

##### Bug Fixes

* None.

## 0.5.6: Bug FixLint

##### Breaking

* None.

##### Enhancements

* Improve performance by reducing calls to SourceKit.  
  [Norio Nomura](https://github.com/norio-nomura)

##### Bug Fixes

* Fix homebrew deployment issues.  
  [Norio Nomura](https://github.com/norio-nomura)

* AutoCorrect for TrailingNewlineRule only removes at most one line.  
  [John Estropia](https://github.com/JohnEstropia)

* `valid_docs` did not detect tuple as return value.  
  [Norio Nomura](https://github.com/norio-nomura)
  [#324](https://github.com/realm/SwiftLint/issues/324)

* Escape strings when using CSV reporter.  
  [JP Simard](https://github.com/jpsim)

## 0.5.5: Magic Drying Fluff Balls™

<http://www.amazon.com/Magic-Drying-Fluff-Balls-Softening/dp/B001EIW1SG>

##### Breaking

* None.

##### Enhancements

* None.

##### Bug Fixes

* Always fail if a YAML configuration file was found but could not be parsed.  
  [JP Simard](https://github.com/jpsim)
  [#310](https://github.com/realm/SwiftLint/issues/310)

* Make commands with modifiers work for violations with line-only locations.  
  [JP Simard](https://github.com/jpsim)
  [#316](https://github.com/realm/SwiftLint/issues/316)


## 0.5.4: Bounce™

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
