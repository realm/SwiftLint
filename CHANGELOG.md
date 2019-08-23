## Master

#### Breaking

* None.

#### Experimental

* None.

#### Enhancements

* None.

#### Bug Fixes

* Fixed false positive in `colon` rule inside guard and ternary operator.
  [Andrey Uryadov](https://github.com/a-25)
  [#2806](https://github.com/realm/SwiftLint/issues/2806)

* Release memory created for sourcekitd requests.  
  [Colton Schlosser](https://github.com/cltnschlosser)
  [#2812](https://github.com/realm/SwiftLint/issues/2812)

* Fix `swiftlint rules` output table formatting.  
  [JP Simard](https://github.com/jpsim)
  [#2787](https://github.com/realm/SwiftLint/issues/2787)

* Fix `unused_import` rule false positive when only operators from the module
  are used.  
  [Timofey Solonin](https://github.com/biboran)
  [#2737](https://github.com/realm/SwiftLint/issues/2737)

## 0.34.0: Anti-Static Wool Dryer Balls

#### Breaking

* To enable collecting rules, many breaking changes to `SwiftLintFramework`'s
  public API were made the `Linter` type was significantely changed, and a new
  `CollectedLinter` type was introduced. Many public `SwiftLintFramework` APIs
  that interacted with `Linter` have also been affected. More new types and
  protocols were added such as `RuleStorage`, `AnyCollectingRule`,
  `CollectingRule`, `CollectingCorrectableRule`.
  We are not aware of any significant users of the `SwiftLintFramework` library,
  so if you are affected by this, please reach out to SwiftLint contributors by
  filing a GitHub issue about your use case.  
  [Elliott Williams](https://github.com/elliottwilliams)
  [JP Simard](https://github.com/jpsim)

#### Experimental

* Add a two-stage `CollectingRule` protocol to support rules that collect data
  from all files before validating. Collecting rules implement a `collect`
  method which is called once for every file, before _any_ file is checked for
  violations. By collecting, rules can be written which validate across
  multiple files for things like unused declarations.  
  [Elliott Williams](https://github.com/elliottwilliams)
  [#2431](https://github.com/realm/SwiftLint/issues/2431)

* Add a new `unused_declaration` analyzer rule to lint for unused declarations.
  By default, detects unused `fileprivate`, `private` and `internal`
  declarations. Configure the rule with `include_public_and_open: true` to
  also detect unused `public` and `open` declarations.  
  [JP Simard](https://github.com/jpsim)

* Completely remove the `unused_private_declaration` rule. Please use
  `unused_declaration` instead.  
  [JP Simard](https://github.com/jpsim)

#### Enhancements

* None.

#### Bug Fixes

* None.

## 0.33.1: Coin-Operated Property Wrapper

#### Breaking

* None.

#### Experimental

* None.

#### Enhancements

* Significantly improve performance when running with a large number of cached
  configurations or when running with many cached results.
  This was done by splitting each configuration to have its own cache and by
  encoding the cache as a binary property list instead of json.  
  [Colton Schlosser](https://github.com/cltnschlosser)
  [JP Simard](https://github.com/jpsim)

* Several public types in SwiftLintFramework have added `Codable` conformance:
  Location, RuleDescription, RuleKind, StyleViolation, SwiftVersion,
  ViolationSeverity.  
  [JP Simard](https://github.com/jpsim)

* Print full relative path to file in log output when it matches the file name
  of another path being linted.  
  [Keith Smiley](https://github.com/keith)

#### Bug Fixes

* Don't trigger `vertical_parameter_alignment` violations when using parameters
  with attributes such as `@ViewBuilder` in function declarations.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#2792](https://github.com/realm/SwiftLint/issues/2792)

* Fix false positive in `function_default_parameter_at_end` rule when using
  a closure parameter with default value.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#2788](https://github.com/realm/SwiftLint/issues/2788)

## 0.33.0: Worldwide Dryers Conference

#### Breaking

* Remove the `weak_computed_property` rule. Please see linked issue for
  discussion and rationale.  
  [JP Simard](https://github.com/jpsim)
  [#2712](https://github.com/realm/SwiftLint/issues/2712)

#### Experimental

* None.

#### Enhancements

* Add `" - "` delimiter to allow commenting SwiftLint commands without triggering
  `superfluous_disable_command`.  
  [Kevin Randrup](https://github.com/kevinrandrup)

* Make `testSimulateHomebrewTest()` test opt-in because it may fail on unknown
  condition. Set `SWIFTLINT_FRAMEWORK_TEST_ENABLE_SIMULATE_HOMEBREW_TEST` 
  environment variable to test like:
    ```terminal.sh-session
    $ SWIFTLINT_FRAMEWORK_TEST_ENABLE_SIMULATE_HOMEBREW_TEST=1 \
    swift test --filter testSimulateHomebrewTest
    ```  
  [Norio Nomura](https://github.com/norio-nomura)

* Add option to configure how nested types should be separated in file names by
  introducting `nested_type_separator` configuration for the `file_name` rule.  
  [Frederick Pietschmann](https://github.com/fredpi)
  [#2717](https://github.com/realm/SwiftLint/issues/2717)

* Add `unowned_variable_capture` opt-in rule to warn against unowned captures
  in closures when using Swift 5.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#2097](https://github.com/realm/SwiftLint/issues/2097)

* Don't trigger a `no_fallthrough_only` violation if next case is an
  `@unknown default`.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#2696](https://github.com/realm/SwiftLint/issues/2696)

* Add `duplicate_enum_cases` rule to validate that an enum doesn't contain
  duplicated cases, as it's impossible to switch on it
  (see [SR-10077](https://bugs.swift.org/browse/SR-10077) for details).  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#2676](https://github.com/realm/SwiftLint/issues/2676)

* Add `legacy_multiple` opt-in rule to warn against using the remainder operator
  (`%`) checking for a remainder of zero when using Swift 5.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#2612](https://github.com/realm/SwiftLint/issues/2612)

#### Bug Fixes

* Don't trigger `redundant_void_return` violations when using `subscript` as the
  return type is required.  
  [Marcelo Fabri](https://github.com/marcelofabri)

* Skip module import if cursor info is missing module info.  
  [alvarhansen](https://github.com/alvarhansen)
  [#2746](https://github.com/realm/SwiftLint/issues/2746)

* Don't trigger `file_types_order` violations in files only containing 
  extensions.  
  [Sam Rayner](https://github.com/samrayner)
  [#2749](https://github.com/realm/SwiftLint/issues/2749)

* Force-unwrapping `self` should trigger a violation of the `force_unwrapping`
  rule.  
  [Dalton Claybrook](https://github.com/daltonclaybrook)
  [#2759](https://github.com/realm/SwiftLint/issues/2759)

## 0.32.0: Wash-N-Fold-N-Reduce

#### Breaking

* None.

#### Experimental

* None.

#### Enhancements

* Add `reduce_boolean` rule to prefer simpler constructs over `reduce(Boolean)`.  
  [Xavier Lowmiller](https://github.com/xavierLowmiller)
  [#2675](https://github.com/realm/SwiftLint/issues/2675)

* Add `nsobject_prefer_isequal` rule to warn against implementing `==` on an
  `NSObject` subclass as calling `isEqual` (i.e. when using the class from
  Objective-C) will not use the defined `==` method.  
  [Matthew Healy](https://github.com/matthew-healy)
  [#2663](https://github.com/realm/SwiftLint/pull/2663)

* Add `reduce_into` opt-in rule to encourage the use of `reduce(into:_:)`
  instead of `reduce(_:_:)` which is less performant.  
  [Dalton Claybrook](https://github.com/daltonclaybrook)
  [#2658](https://github.com/realm/SwiftLint/issues/2658)

* Remove @ mark to fix invalid link in Rules.md.  
  [Hiroki Nagasawa](https://github.com/pixyzehn)
  [#2669](https://github.com/realm/SwiftLint/pull/2669)

* Add new opt-in rule `file_types_order` to specify how the types in a file
  should be sorted.  
  [Cihat Gündüz](https://github.com/Dschee)
  [#2294](https://github.com/realm/SwiftLint/issues/2294)

* Add new opt-in rule `type_contents_order` to specify the order of subtypes,
  properties, methods & more within a type.  
  [Cihat Gündüz](https://github.com/Dschee)
  [#2294](https://github.com/realm/SwiftLint/issues/2294)

* Add `nslocalizedstring_require_bundle` rule to ensure calls to
  `NSLocalizedString` specify the bundle where the strings file is located.  
  [Matthew Healy](https://github.com/matthew-healy)
  [#2595](https://github.com/realm/SwiftLint/issues/2595)

* `contains_over_first_not_nil` rule now also checks for `firstIndex(where:)`.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#2678](https://github.com/realm/SwiftLint/issues/2678)

* Add `unused_capture_list` rule to ensure that all references in a closure
  capture list are used.  
  [Dalton Claybrook](https://github.com/daltonclaybrook)
  [#2715](https://github.com/realm/SwiftLint/issues/2715)

* SwiftLint can now be compiled using Xcode 10.2.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [Norio Nomura](https://github.com/norio-nomura)
  [#2693](https://github.com/realm/SwiftLint/issues/2693)

#### Bug Fixes

* Fix bug where SwiftLint ignores excluded files list in a nested configuration
  file.  
  [Dylan Bruschi](https://github.com/Bruschidy54)
  [#2447](https://github.com/realm/SwiftLint/issues/2447)

* `colon` rule now catches violations when declaring generic types with
  inheritance or protocol conformance.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#2628](https://github.com/realm/SwiftLint/issues/2628)

* `discarded_notification_center_observer` rule now checks if the observer is
  added to any collection or passed to a function before triggering the
  violation.  
  [jsloop42](https://github.com/jsloop42)
  [#2684](https://github.com/realm/SwiftLint/issues/2684)

* Fix false positives on `number_separator` when the number is wrapped in
  parentheses.  
  [Dalton Claybrook](https://github.com/daltonclaybrook)
  [#2683](https://github.com/realm/SwiftLint/issues/2683)

* Fix false positives on `sorted_first_last` when calling `firstIndex` and
  `lastIndex` method.
  [Taiki Komaba](https://github.com/r-plus)
  [#2700](https://github.com/realm/SwiftLint/issues/2700)

* Fix crash when running on Linux with Swift 5 without specifying a `--path`
  value or specifying an empty string.  
  [Keith Smiley](https://github.com/keith)
  [#2703](https://github.com/realm/SwiftLint/issues/2703)

* Fix false positives on `explicit_acl` and `explicit_top_level_acl` rules when
  declaring extensions that add protocol conformances with Swift 5.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#2705](https://github.com/realm/SwiftLint/issues/2705)
  
* Let `disable all` command override `superfluous_disable_command` rule.  
  [Frederick Pietschmann](https://github.com/fredpi)
  [#2670](https://github.com/realm/SwiftLint/issues/2670)

* Fix issues in `explict_acl`, `redundant_set_access_control` and
  `explicit_top_level_acl` rules when using Swift 5.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#2694](https://github.com/realm/SwiftLint/issues/2694)

## 0.31.0: Busy Laundromat

#### Breaking

* None.

#### Experimental

* None.

#### Enhancements

* Add `deployment_target` rule to validate that `@availability` attributes and
  `#available` conditions are not using a version that is satisfied by the
  deployment target. Since SwiftLint can't read an Xcode project, you need to
  configure this rule with these keys: `iOS_deployment_target`,
  `macOS_deployment_target`, `watchOS_deployment_target` and
  `tvOS_deployment_target`. By default, these values are configured with the
  minimum versions supported by Swift.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#2589](https://github.com/realm/SwiftLint/issues/2589)

* Add `weak_computed_property` rule to warn against using `weak` in a computed
  property as it has no effect.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#2596](https://github.com/realm/SwiftLint/issues/2596)

* Add `SwiftVersion.five` and automatically detect it when computing
  `SwiftVersion.current`.  
  [JP Simard](https://github.com/jpsim)

* Make `redundant_objc_attribute` rule autocorrectable.  
  [Daniel Metzing](https://github.com/dirtydanee)

* Add `required_deinit` opt-in rule to ensure that all classes have a deinit
  method. The purpose of this is to make memory leak debugging easier so all
  classes have a place to set a breakpoint to track deallocation.  
  [Ben Staveley-Taylor](https://github.com/BenStaveleyTaylor)
  [#2620](https://github.com/realm/SwiftLint/issues/2620)

* `nimble_operator` now warns about `beTrue()` and `beFalse()`.  
  [Igor-Palaguta](https://github.com/Igor-Palaguta)
  [#2613](https://github.com/realm/SwiftLint/issues/2613)

* Warn if a configured rule is not enabled.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#1350](https://github.com/realm/SwiftLint/issues/1350)

* Add `exclude_ranges` option to `number_separator` for exclusion.  
  [Cihat Gündüz](https://github.com/Dschee)
  [#2637](https://github.com/realm/SwiftLint/issues/2637)

#### Bug Fixes

* Fix false positives on `no_grouping_extension` rule when using `where`
  clause.  
  [Almaz Ibragimov](https://github.com/almazrafi)

* Fix `explicit_type_interface` when used in statements.  
  [Daniel Metzing](https://github.com/dirtydanee)
  [#2154](https://github.com/realm/SwiftLint/issues/2154)

* Fix `lower_acl_than_parent` when linting with Swift 5.  
  [JP Simard](https://github.com/jpsim)
  [#2607](https://github.com/realm/SwiftLint/issues/2607)

* Fix `let_var_whitespace` with `#warning`.  
  [Igor-Palaguta](https://github.com/Igor-Palaguta)
  [#2544](https://github.com/realm/SwiftLint/issues/2544)

* Fix excessive `superfluous_disable_command` violations being reported when
  using an invalid rule identifier in a disable command.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#2623](https://github.com/realm/SwiftLint/issues/2623)

* Fix `explicit_type_interface` with `allow_redundancy` when assigning type
  references to variables.  
  [Cihat Gündüz](https://github.com/Dschee)
  [#2636](https://github.com/realm/SwiftLint/issues/2636)

* Fix `unused_closure_parameter` when argument is named `self`.  
  [Cihat Gündüz](https://github.com/Dschee)
  [#2437](https://github.com/realm/SwiftLint/issues/2437)

* Fix `first_where` for some calls on Realm collection types.  
  [Cihat Gündüz](https://github.com/Dschee)
  [#1930](https://github.com/realm/SwiftLint/issues/1930)

## 0.30.1: Localized Stain Remover

#### Breaking

* None.

#### Experimental

* Silence `CodingKeys` violations in `unused_private_declaration` since these
  should always be intentional violations.  
  [Kim de Vos](https://github.com/kimdv)
  [#2573](https://github.com/realm/SwiftLint/issues/2573)

#### Enhancements

* Add `nslocalizedstring_key` opt-in rule to validate that keys used in
  `NSLocalizedString` calls are static strings, so `genstrings` will be
  able to find them.  
  [Marcelo Fabri](https://github.com/marcelofabri)

#### Bug Fixes

* Fix false positives on `trailing_closure` rule when using anonymous closure
  calls.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#2159](https://github.com/realm/SwiftLint/issues/2159)

* Fix false positives on `array_init` rule when using prefix operators.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#1877](https://github.com/realm/SwiftLint/issues/1877)

* Exclude files defined in the `excluded` value of SwiftLint's configuration
  when `--use-script-input-files` and `--force-exclude` are specified.  
  [Luis Valdés](https://github.com/luvacu)
  [#591](https://github.com/realm/SwiftLint/issues/591)

## 0.30.0: A New Washer and Dryer Set

#### Breaking

* None.

#### Experimental

* None.

#### Enhancements

* Add `duplicate_imports` rule to prevent importing the same module twice.  
  [Samuel Susla](https://github.com/sammy-sc)
  [#1881](https://github.com/realm/SwiftLint/issues/1881)

* Add `unused_setter_value` rule to validate that setter arguments are
  used in properties.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#1136](https://github.com/realm/SwiftLint/issues/1136)

* Add `only_single_muted_parameter` configuration on `trailing_closure` rule
  to only enforce using trailing closure on functions that take one single
  muted parameter.  
  [Marcelo Fabri](https://github.com/marcelofabri)

#### Bug Fixes

* Fix false positives on `identical_operands` rule when the right side of the
  operand has a chained optional.  
  [JP Simard](https://github.com/jpsim)
  [#2564](https://github.com/realm/SwiftLint/issues/2564)

## 0.29.4: In-Unit Operands

#### Breaking

* None.

#### Experimental

* Fix `unused_import` correction deleting unrelated ranges when there are
  multiple violations in a single file.  
  [JP Simard](https://github.com/jpsim)
  [#2561](https://github.com/realm/SwiftLint/issues/2561)

#### Enhancements

* Add `strong_iboutlet` opt-in rule to enforce that `@IBOutlet`s are not
  declared as `weak`.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#2433](https://github.com/realm/SwiftLint/issues/2433)

#### Bug Fixes

* Fix inaccessible custom rules in nested configurations.  
  [Timofey Solonin](https://github.com/biboran)
  [#1815](https://github.com/realm/SwiftLint/issues/1815)
  [#2441](https://github.com/realm/SwiftLint/issues/2441)

* Improve `superfluous_disable_command` to warn against disabling non-existent
  rules.  
  [Kim de Vos](https://github.com/kimdv)
  [#2348](https://github.com/realm/SwiftLint/issues/2348)

* Fix false positives on `identical_operands` rule when the right side of the
  operand does not terminate.  
  [Xavier Lowmiller](https://github.com/xavierLowmiller)
  [#2467](https://github.com/realm/SwiftLint/issues/2467)

## 0.29.3: Entangled Agitator

#### Breaking

* None.

#### Experimental

* Skip `@IBInspectable` and `deinit` declarations in
  `unused_private_declaration`.  
  [JP Simard](https://github.com/jpsim)

#### Enhancements

* Allow configuring `discouraged_object_literal` rule to only discourage one
  kind of object literal.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#2439](https://github.com/realm/SwiftLint/issues/2439)

* Adds `xct_specific_matcher` opt-in rule to enforce specific matchers
  over `XCTAssertEqual` and `XCTAssertNotEqual`.  
  [Ornithologist Coder](https://github.com/ornithocoder)
  [#1874](https://github.com/realm/SwiftLint/issues/1874)

* Add `last_where` opt-in rule that warns against using
  `.filter { /* ... */ }.last` in collections, as
  `.last(where: { /* ... */ })` is more efficient.  
  [Marcelo Fabri](https://github.com/marcelofabri)

* Add `unused_control_flow_label` rule to validate that control flow labels are
  used.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#2227](https://github.com/realm/SwiftLint/issues/2227)

#### Bug Fixes

* Fix false positives on `first_where` rule when calling `filter` without a
  closure parameter (for example on a Realm collection).  
  [Marcelo Fabri](https://github.com/marcelofabri)

* Fix false positives on `sorted_first_last` rule when calling `sorted` with
  a different argument than `by:` (e.g. on a Realm collection).  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#2533](https://github.com/realm/SwiftLint/issues/2533)

* Fix false positives on `redundant_objc_attribute` rule when using nested
  types.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#2539](https://github.com/realm/SwiftLint/issues/2539)

* Fix false positives on `vertical_whitespace_between_cases` rule when a blank
  line is present but it contains trailing whitespace.  
  [Ben Staveley-Taylor](https://github.com/BenStaveleyTaylor)
  [#2538](https://github.com/realm/SwiftLint/issues/2538)

## 0.29.2: Washateria

#### Breaking

* None.

#### Experimental

* None.

#### Enhancements

* Add new opt-in rule `vertical_whitespace_opening_braces` to warn against empty
  lines after opening braces.  
  [Cihat Gündüz](https://github.com/Dschee)
  [#1518](https://github.com/realm/SwiftLint/issues/1518)

* Add new opt-in rule `vertical_whitespace_closing_braces` to warn against empty
  lines before closing braces.  
  [Cihat Gündüz](https://github.com/Dschee)
  [#1518](https://github.com/realm/SwiftLint/issues/1518)

* Improve performance for `unused_private_declaration` and `unused_import` rules
  for large files.  
  [Niil Öhlin](https://github.com/niilohlin)

* Add new `legacy_hashing` rule to encourage the use of Swift 4.2's new hashing
  interface.  
  [Kim de Vos](https://github.com/kimdv)
  [#2108](https://github.com/realm/SwiftLint/issues/2108)

* Improve `private_unit_test` rule to allow private classes with `@objc`
  attribute.  
  [Kim de Vos](https://github.com/kimdv)
  [#2282](https://github.com/realm/SwiftLint/issues/2282)

* Support glob patterns without the star.  
  [Maksym Grebenets](https://github.com/mgrebenets)

* Make `modifier_order` rule autocorrectable.  
  [Timofey Solonin](https://github.com/biboran)
  [#2353](https://github.com/realm/SwiftLint/issues/2353)

#### Bug Fixes

* Fix false positives in `redundant_objc_attribute` for private declarations
  under `@objcMembers`.  
  [Daniel Metzing](https://github.com/dirtydanee)
  [#2499](https://github.com/realm/SwiftLint/issues/2499)

* Fix an error when pulling SwiftLint as a dependency using Carthage.  
  [JP Simard](https://github.com/jpsim)

* Non-string values specified in `swiftlint_version` now fail the lint if
  it doesn't match the version.  
  [JP Simard](https://github.com/jpsim)
  [#2518](https://github.com/realm/SwiftLint/issues/2518)

## 0.29.1: There’s Always More Laundry

#### Breaking

* None.

#### Experimental

* None.

#### Enhancements

* Add `redundant_objc_attribute` to warn against already implied `@objc`
  attribute.  
  [Daniel Metzing](https://github.com/dirtydanee)
  [#2193](https://github.com/realm/SwiftLint/issues/2193)

* Add `vertical_whitespace_between_cases` opt-in rule to enforce a single
  empty line between switch cases.  
  [Cihat Gündüz](https://github.com/Dschee)
  [#1517](https://github.com/realm/SwiftLint/issues/1517)

* Add `multiline_arguments_brackets` opt-in rule to warn against multiline
  function call arguments with surrounding brackets without newline.  
  [Cihat Gündüz](https://github.com/Dschee)
  [#2306](https://github.com/realm/SwiftLint/issues/2306)

* Add `multiline_literal_brackets` opt-in rule to warn against multiline
  literal arrays & dictionaries with surrounding brackets without newline.  
  [Cihat Gündüz](https://github.com/Dschee)
  [#2306](https://github.com/realm/SwiftLint/issues/2306)

* Add `multiline_parameters_brackets` opt-in rule to warn against multiline
  function definition parameters with surrounding brackets without newline.  
  [Cihat Gündüz](https://github.com/Dschee)
  [#2306](https://github.com/realm/SwiftLint/issues/2306)

* Ignore unspecified modifiers in `modifier_order`.  
  [Timofey Solonin](https://github.com/biboran)
  [#2435](https://github.com/realm/SwiftLint/issues/2435)

* The `lint` command now exits with a code of 2 when not using pinned
  version defined as `swiftlint_version` in the configuration file.  
  [Kim de Vos](https://github.com/kimdv)
  [#2074](https://github.com/realm/SwiftLint/issues/2074)

#### Bug Fixes

* Fix false positive in `nimble_operator` rule.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#2489](https://github.com/realm/SwiftLint/issues/2489)

* Fix false positives on `explicit_type_interface` rule when
  configured with option `allowRedundancy` set to `true`.  
  [Cihat Gündüz](https://github.com/Dschee)
  [#2425](https://github.com/realm/SwiftLint/issues/2425)

* Only mark custom rules as 'enabled in your config' in the output of the
  `rules` command when there are one or more configured custom rules.  
  [jhildensperger](https://github.com/jhildensperger)

* Fix wrong correction when removing testable imports with the `unused_import`
  rule.  
  [JP Simard](https://github.com/jpsim)

* Fix false positive with the `unused_import` rule when importing Foundation
  when there are attributes in that file requiring Foundation.  
  [JP Simard](https://github.com/jpsim)

## 0.29.0: A Laundry List of Changes

#### Breaking

* SwiftLint now requires Swift 4.2 or higher to build.  
  [JP Simard](https://github.com/jpsim)

#### Experimental

* None.

#### Enhancements

* Improve the performance of saving or reading cached lint results on platforms
  with CommonCrypto.  
  [JP Simard](https://github.com/jpsim)

* Add `markdown` reporter which outputs markdown-formatted tables, ideal for
  rendering in GitLab or GitHub.  
  [Dani Vela](https://github.com/madcato)

* Add `testSimulateHomebrewTest()` to `IntegrationTests` that simulates test in
  `homebrew-core/Formula/swiftlint.rb` within sandbox.  
  [Norio Nomura](https://github.com/norio-nomura)

#### Bug Fixes

* Fix compiler warnings when building with Swift 4.2 introduced in the last
  release.  
  [JP Simard](https://github.com/jpsim)

* Fix false positive in `explicit_init` rule.  
  [Dominic Freeston](https://github.com/dominicfreeston)

* Fix `toggle_bool` false positive violation when comparing object parameter to
  an equally named variable.  
  [Timofey Solonin](https://github.com/biboran)
  [#2471](https://github.com/realm/SwiftLint/issues/2471)

* Fix false positive on file_name rule with specific patterns.  
  [Cihat Gündüz](https://github.com/Dschee)
  [#2417](https://github.com/realm/SwiftLint/issues/2417)

* Fix crash in `no_fallthrough_only` and potentially other rules when linting
  files with unicode characters in certain locations.  
  [JP Simard](https://github.com/jpsim)
  [#2276](https://github.com/realm/SwiftLint/issues/2276)

* Fix violations with no character/column location not being reported in
  `xcpretty`. Now violations with no column location default to a column value
  of `1` indicating the start of the line.  
  [JP Simard](https://github.com/jpsim)
  [#2267](https://github.com/realm/SwiftLint/issues/2267)

## 0.28.2: EnviroBoost Plus

#### Breaking

* None.

#### Experimental

* None.

#### Enhancements

* Add `SWIFTLINT_DISABLE_SOURCEKIT` environment variable to allow running
  SwiftLint without connecting to SourceKit. This will run a subset of rules
  that don't require SourceKit, which is useful when running in a sandboxed
  setting such as in Homebrew's CI.  
  [Norio Nomura](https://github.com/norio-nomura)

#### Bug Fixes

* None.

## 0.28.1: EnviroBoost

This is the last release to support building with Swift 4.0 and Swift 4.1.

#### Breaking

* None.

#### Experimental

* None.

#### Enhancements

* None.

#### Bug Fixes

* Improve the performance of collecting which files to lint by up to 3.5x.  
  [JP Simard](https://github.com/jpsim)

* Improve the performance of looking up cached lint results by up to 10x for
  complex configurations.  
  [JP Simard](https://github.com/jpsim)

## 0.28.0: EcoBoost

#### Breaking

* Completely remove the `--use-tabs` option of the `autocorrect` command that
  was deprecated in 0.24.1. In its place, define an `indentation` key in your
  configuration files.  
  [JP Simard](https://github.com/jpsim)

#### Experimental

* Add a new `swiftlint analyze` command which can lint Swift files using the
  full type-checked AST. Rules of the `AnalyzerRule` type will be added over
  time. The compiler log path containing the clean `swiftc` build command
  invocation (incremental builds will fail) must be passed to `analyze` via
  the `--compiler-log-path` flag.
  e.g. `--compiler-log-path /path/to/xcodebuild.log`  
  [JP Simard](https://github.com/jpsim)

* Add an `explicit_self` analyzer rule to enforce the use of explicit references
  to `self.` when accessing instance variables or functions.  
  [JP Simard](https://github.com/jpsim)
  [#321](https://github.com/realm/SwiftLint/issues/321)

* Add an `unused_import` analyzer rule to lint for unnecessary imports.  
  [JP Simard](https://github.com/jpsim)
  [#2248](https://github.com/realm/SwiftLint/issues/2248)

* Add an `unused_private_declaration` analyzer rule to lint for unused private
  declarations.  
  [JP Simard](https://github.com/jpsim)

#### Enhancements

* Add `legacy_random` opt-in rule to encourage the use of `.random(in:)`
  instead of `arc4random`, `arc4random_uniform`, and `drand48`.  
  [Joshua Kaplan](https://github.com/yhkaplan)

* Improve performance of `line_length` and
  `multiple_closures_with_trailing_closure` rules.  
  [Marcelo Fabri](https://github.com/marcelofabri)

* Add `closure_body_length` opt-in rule to enforce the maximum number
  of lines a closure should have. Requires Swift 4.2.  
  [Ornithologist Coder](https://github.com/ornithocoder)
  [#52](https://github.com/realm/SwiftLint/issues/52)

* Add SonarQube reporter.  
  [Yusuke Ohashi](https://github.com/junkpiano)
  [#2350](https://github.com/realm/SwiftLint/issues/2350)

* Add `prohibited_interface_builder` opt-in rule to validate that `@IBOutlet`s
  and `@IBAction`s are not used.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#2365](https://github.com/realm/SwiftLint/issues/2365)

* Add `inert_defer` rule to validate that `defer` is not used at the end of a
  scope.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#2123](https://github.com/realm/SwiftLint/issues/2123)

* Add `toggle_bool` opt-in rule which suggests using `someBool.toggle()` over
  `someBool = !someBool`. Requires Swift 4.2.  
  [Dalton Claybrook](https://github.com/daltonclaybrook)
  [#2369](https://github.com/realm/SwiftLint/issues/2369)

* Add `identical_operands` opt-in rule to validate that operands are different
  expressions in comparisons.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#1371](https://github.com/realm/SwiftLint/issues/1371)

* Add `collection_alignment` opt-in rule to validate that all elements in a
  collection literal are aligned vertically.  
  [Dalton Claybrook](https://github.com/daltonclaybrook)
  [#2326](https://github.com/realm/SwiftLint/issues/2326)

* Add `static_operator` opt-in rule to enforce that operators are declared as
  static functions instead of free functions.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#2395](https://github.com/realm/SwiftLint/issues/2395)

* Specify what type of compiler protocol initializer violated the
  `compiler_protocol_init` rule.  
  [Timofey Solonin](https://github.com/biboran)
  [#2422](https://github.com/realm/SwiftLint/issues/2422)

#### Bug Fixes

* Fix `comma` rule false positives on object literals (for example, images).  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#2345](https://github.com/realm/SwiftLint/issues/2345)

* Fix false positive on `file_name` rule when using nested types.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#2325](https://github.com/realm/SwiftLint/issues/2325)

* Fix crash on `multiline_function_chains` rule when using some special
  characters inside the function calls.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#2360](https://github.com/realm/SwiftLint/issues/2360)

* Change `autocorrect --format` to run format before autocorrect, fixing
  conflicts between default indentation and rules which modify indentation
  (i.e. `closure_end_indentation`).  
  [Ornithologist Coder](https://github.com/ornithocoder)
  [#2374](https://github.com/realm/SwiftLint/issues/2374)

* Fix false positive on `empty_count` rule when assessing binary, octal and
  hexadecimal integer literals.  
  [Timofey Solonin](https://github.com/biboran)
  [#2423](https://github.com/realm/SwiftLint/issues/2423)

## 0.27.0: Heavy Duty

#### Breaking

* None.

#### Enhancements

* Append `modifier_order` description with failure reason.  
  [Daniel Metzing](https://github.com/dirtydanee)
  [#2269](https://github.com/realm/SwiftLint/pull/2269)

* Decrease default severity of `superfluous_disable_command` to `warning`.  
  [Frederick Pietschmann](https://github.com/fredpi)
  [#2250](https://github.com/realm/SwiftLint/issues/2250)

* Don't touch files when running `autocorrect --format` if the contents haven't
  changed.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#2249](https://github.com/realm/SwiftLint/issues/2249)

* Add `only_enforce_after_first_closure_on_first_line` configuration
  to `multiline_arguments`  
  [Mike Ciesielka](https://github.com/maciesielka)
  [#1896](https://github.com/realm/SwiftLint/issues/1896)

* Add `anyobject_protocol` opt-in rule which suggests using `AnyObject` over
  `class` for class-only protocols.  
  [Ornithologist Coder](https://github.com/ornithocoder)
  [#2283](https://github.com/realm/SwiftLint/issues/2283)

* Add options `prefix_pattern` and `suffix_pattern` to rule `file_name`.  
  [Cihat Gündüz](https://github.com/Dschee)
  [#2309](https://github.com/realm/SwiftLint/issues/2309)

* Add new bool config option `if_only` to rule `conditional_returns_on_newline`
  to specify that the rule should only be applied to `if` statements.  
  [Cihat Gündüz](https://github.com/Dschee)
  [#2307](https://github.com/realm/SwiftLint/issues/2307)

* Add support for globs in `excluded` file paths.  
  [Keith Smiley](https://github.com/keith)
  [#2316](https://github.com/realm/SwiftLint/pull/2316)

* Add `only_private` configuration to `prefixed_toplevel_constant` rule.  
  [Keith Smiley](https://github.com/keith)
  [#2315](https://github.com/realm/SwiftLint/pull/2315)

* Make rule `explicit_type_interface` compatible with rule
  `redundant_type_annotation` via new option `allow_redundancy`.  
  [Cihat Gündüz](https://github.com/Dschee)
  [#2312](https://github.com/realm/SwiftLint/issues/2312)

* Add `missing_docs` rule to warn against undocumented declarations.  
  [Nef10](https://github.com/Nef10)
  [Andrés Cecilia Luque](https://github.com/acecilia)
  [#1652](https://github.com/realm/SwiftLint/issues/1652)

#### Bug Fixes

* Fix an issue with `control_statement` where commas in clauses prevented the
  rule from applying.  
  [Allen Wu](https://github.com/allewun)

* Fix `explicit_enum_raw_value`, `generic_type_name`, `implicit_return`,
  `required_enum_case`, `quick_discouraged_call`, `array_init`,
  `closure_parameter_position` and `unused_closure_parameter` rules
  when linting with Swift 4.2.  
  [Marcelo Fabri](https://github.com/marcelofabri)

* Fix `identifier_name` rule false positives with `enum` when linting
  using Swift 4.2.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [Jacob Greenfield](https://github.com/Coder-256)
  [#2231](https://github.com/realm/SwiftLint/issues/2231)

* Fix a crash when running with Swift 4.2.  
  [Norio Nomura](https://github.com/norio-nomura)
  [SR-7954](https://bugs.swift.org/browse/SR-7954)

* Fix false positive on `attributes` rule when linting a line that is below
  a line with a declaration that has attributes.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#2297](https://github.com/realm/SwiftLint/issues/2297)

* `redundant_optional_initialization` rule now lints local variables.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#2233](https://github.com/realm/SwiftLint/issues/2233)

* Fix autocorrection for `redundant_type_annotation` rule.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#2314](https://github.com/realm/SwiftLint/issues/2314)

## 0.26.0: Maytagged Pointers

#### Breaking

* SwiftLint now requires Swift 4.0 or higher to build.  
  [JP Simard](https://github.com/jpsim)

* The `fallthrough` rule is now opt-in.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#1892](https://github.com/realm/SwiftLint/issues/1892)

#### Enhancements

* Add optional filename verification to the `file_header` rule.
  All occurrences in the pattern of the `SWIFTLINT_CURRENT_FILENAME`
  placeholder are replaced by the name of the validated file.  
  [Anders Hasselqvist](https://github.com/nevil)
  [#1079](https://github.com/realm/SwiftLint/issues/1079)

* Updates the `untyped_error_in_catch` rule to support autocorrection.  
  [Daniel Metzing](https://github.com/dirtydanee)

* Add `no_fallthrough_only` rule to check that `case` statements do not
  contain only a `fallthrough`.  
  [Austin Belknap](https://github.com/dabelknap)

* Add `indented_cases` support to `switch_case_alignment` rule.  
  [Shai Mishali](https://github.com/freak4pc)
  [#2119](https://github.com/realm/SwiftLint/issues/2119)

* Add opt-in `modifier_order` to enforce the order of declaration modifiers.
  Requires Swift 4.1 or later.  
  [Jose Cheyo Jimenez](https://github.com/masters3d)
  [Daniel Metzing](https://github.com/dirtydanee)
  [#1472](https://github.com/realm/SwiftLint/issues/1472)
  [#1585](https://github.com/realm/SwiftLint/issues/1585)

* Validate implicit `subscript` getter in `implicit_getter` rule when using
  Swift 4.1 or later.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#898](https://github.com/realm/SwiftLint/issues/898)

* Add `unavailable_function` opt-in rule to validate that functions that are
  currently unimplemented (using a placeholder `fatalError`) are marked with
  `@available(*, unavailable)`.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#2127](https://github.com/realm/SwiftLint/issues/2127)

* Updates the `closure_end_indentation` rule to support autocorrection.  
  [Eric Horacek](https://github.com/erichoracek)

* Updates the `literal_expression_end_indentation` rule to support
  autocorrection.  
  [Eric Horacek](https://github.com/erichoracek)

* Add a new `multiline_function_chains` rule to validate that chained function
  calls start either on the same line or one per line.  
  [Eric Horacek](https://github.com/erichoracek)
  [#2214](https://github.com/realm/SwiftLint/issues/2214)

* Improves the `mark` rule's autocorrection.  
  [Eric Horacek](https://github.com/erichoracek)

* Add `redundant_set_access_control` rule to warn against using redundant
  setter ACLs on variable declarations.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#1869](https://github.com/realm/SwiftLint/issues/1869)

* Add a new `ignores_interpolated_strings` config parameter to the `line_length`
  rule to ignore lines that include interpolated strings from this rule.  
  [Michael Gray](https://github.com/mishagray)
  [#2100](https://github.com/realm/SwiftLint/pull/2100)

* Add a new `ignores_default_parameters` config parameter to the
  `function_parameter_count` rule to ignore default parameter when calculating
  parameter count. True by default.  
  [Varun P M](https://github.com/varunpm1)
  [#2171](https://github.com/realm/SwiftLint/issues/2171)

* Add `empty_xctest_method` opt-in rule which warns against empty
  XCTest methods.  
  [Ornithologist Coder](https://github.com/ornithocoder)
  [#2190](https://github.com/realm/SwiftLint/pull/2190)

* Add `function_default_parameter_at_end` opt-in rule to validate that
  parameters with defaults are located toward the end of the parameter list in a
  function declaration.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#2176](https://github.com/realm/SwiftLint/issues/2176)

* Add `file_name` opt-in rule validating that file names contain the name of a
  type or extension declared in the file (if any).  
  [JP Simard](https://github.com/jpsim)
  [#1420](https://github.com/realm/SwiftLint/issues/1420)

* Add `redundant_type_annotation` opt-in rule which warns against
  unnecessary type annotations for variables.  
  [Šimon Javora](https://github.com/sjavora)
  [#2239](https://github.com/realm/SwiftLint/pull/2239)

* Add `convenience_type` opt-in rule to validate that types hosting only static
  members should be enums to avoid instantiation.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#1871](https://github.com/realm/SwiftLint/issues/1871)  

* Support for passing multiple path arguments.  
  [Ben Asher](https://github.com/benasher44)
  [#810](https://github.com/realm/SwiftLint/issues/810)

#### Bug Fixes

* Update `LowerACLThanParent` rule to not lint extensions.  
  [Keith Smiley](https://github.com/keith)
  [#2164](https://github.com/realm/SwiftLint/pull/2164)

* Fix operator usage spacing nested generics false positive.  
  [Eric Horacek](https://github.com/erichoracek)
  [#1341](https://github.com/realm/SwiftLint/issues/1341)
  [#1897](https://github.com/realm/SwiftLint/issues/1897)

* Fix autocorrection for several rules
  (`empty_parentheses_with_trailing_closure`, `explicit_init`,
  `joined_default_parameter`, `redundant_optional_initialization` and
  `unused_closure_parameter `) when used with preprocessor macros.  
  [John Szumski](https://github.com/jszumski)
  [Marcelo Fabri](https://github.com/marcelofabri)

* Fix `unneeded_parentheses_in_closure_argument` false negatives when multiple
  violations are nested.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#2188](https://github.com/realm/SwiftLint/issues/2188)

* Fix false negatives in `implicit_return` rule when using closures as
  function arguments.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#2187](https://github.com/realm/SwiftLint/issues/2187)

* Fix false positives in `attributes` rule when `@testable` is used.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#2211](https://github.com/realm/SwiftLint/issues/2211)

* Fix false positives in `prohibited_super_call` rule.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#2212](https://github.com/realm/SwiftLint/issues/2212)

* Fix a false positive in `unused_closure_parameter` rule when a parameter
  is used in a string interpolation.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#2062](https://github.com/realm/SwiftLint/issues/2062)

* Fixes a case where the `closure_end_indentation` rule wouldn't lint the end
  indentation of non-trailing closure parameters.  
  [Eric Horacek](https://github.com/erichoracek)
  [#2121](https://github.com/realm/SwiftLint/issues/2121)

## 0.25.1: Lid Locked

This is the last release to support building with Swift 3.2 and Swift 3.3.
The next release will require Swift 4.0 or higher to build.

#### Breaking

* None.

#### Enhancements

* Add `LowerACLThanParent` rule.  
  [Keith Smiley](https://github.com/keith)
  [#2136](https://github.com/realm/SwiftLint/pull/2136)

* Add `UIOffsetMake` to `legacy_constructor` rule.  
  [Nealon Young](https://github.com/nealyoung)
  [#2126](https://github.com/realm/SwiftLint/issues/2126)

* Add a new `excluded` config parameter to the `explicit_type_interface` rule
  to exempt certain types of variables from the rule.  
  [Rounak Jain](https://github.com/rounak)
  [#2028](https://github.com/realm/SwiftLint/issues/2028)

* Add `empty_string` opt-in rule to validate against comparing strings to `""`
  instead of using `.isEmpty`.  
  [Davide Sibilio](https://github.com/idevid)

* Add `untyped_error_in_catch` opt-in rule to warn against declaring errors
  without an explicit type in catch statements instead of using the implicit
  `error` variable.  
  [Daniel Metzing](https://github.com/dirtydanee)
  [#2045](https://github.com/realm/SwiftLint/issues/2045)

* Add `all` keyword for use in disable / enable statement:
  `// swiftlint:disable all`.
  It allows disabling SwiftLint entirely, in-code, for a particular section.  
  [fredpi](https://github.com/fredpi)
  [#2071](https://github.com/realm/SwiftLint/issues/2071)

* Adds `--force-exclude` option to `lint` and `autocorrect` commands, which will
  force SwiftLint to exclude files specified in the config `excluded` even if
  they are explicitly specified with `--path`.  
  [Ash Furrow](https://github.com/ashfurrow)
  [#2051](https://github.com/realm/SwiftLint/issues/2051)

* Adds `discouraged_optional_collection` opt-in rule to encourage the use of
  empty collections instead of optional collections.  
  [Ornithologist Coder](https://github.com/ornithocoder)
  [#1885](https://github.com/realm/SwiftLint/issues/1885)

* Add 4.1.0, 4.1.1 and 4.2.0 to Swift version detection.  
  [Norio Nomura](https://github.com/norio-nomura)
  [#2143](https://github.com/realm/SwiftLint/issues/2143)

* Support building with Swift 4.1.  
  [Norio Nomura](https://github.com/norio-nomura)
  [#2038](https://github.com/realm/SwiftLint/issues/2038)

#### Bug Fixes

* Fixes an issue with the `yoda_condition` rule where the severity would always
  display as a warning, and the reason would display as the severity type.  
  [Twig](https://github.com/Twigz)

* Fix TODOs lint message to state that TODOs should be resolved instead of
  avoided.  
  [Adonis Peralta](https://github.com/donileo)
  [#150](https://github.com/realm/SwiftLint/issues/150)

* Fix some cases where `colon` rule wouldn't autocorrect dictionary literals.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#2050](https://github.com/realm/SwiftLint/issues/2050)

* Fix linux crash on sources with surrogate pair emojis as variable names.  
  [Cyril Lashkevich](https://github.com/notorca)

* Make `legacy_constructor` rule more reliable, especially for autocorrecting.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#2098](https://github.com/realm/SwiftLint/issues/2098)

* Fix `colon` rule autocorrect when preprocessor macros are present.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#2099](https://github.com/realm/SwiftLint/issues/2099)

* Fix crash when saving cache if there're entries referring to the same path
  but with different capitalization.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#2032](https://github.com/realm/SwiftLint/issues/2032)

* Fix several rules (`empty_enum_arguments`, `explicit_init`
  `empty_parentheses_with_trailing_closure`, `joined_default_parameter`,
  `redundant_optional_initialization`, `redundant_void_return` and
  `unused_closure_parameter`) rules autocorrection inside functions or other
  declarations.  
  [Marcelo Fabri](https://github.com/marcelofabri)

* Fix `redundant_void_return` rule autocorrect when preprocessor macros are
  present.  
  [John Szumski](https://github.com/jszumski)
  [#2115](https://github.com/realm/SwiftLint/issues/2115)

* Fix issue where the autocorrect done message used the plural form of "files"
  even if only 1 file changed.  
  [John Szumski](https://github.com/jszumski)

* Fix false positives in `attributes` rule when using Swift 4.1.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#2125](https://github.com/realm/SwiftLint/issues/2125)
  [#2141](https://github.com/realm/SwiftLint/issues/2141)

## 0.25.0: Cleaning the Lint Filter

#### Breaking

* None.

#### Enhancements

* Adds `discouraged_optional_boolean` opt-in rule to discourage
  the use of optional booleans.  
  [Ornithologist Coder](https://github.com/ornithocoder)
  [#2011](https://github.com/realm/SwiftLint/issues/2011)

#### Bug Fixes

* Fix some cases where `colon` rule wouldn't be autocorrected.  
  [Manabu Nakazawa](https://github.com/mshibanami)

* Fix false positives in `explicit_acl` rule when declaring functions and
  properties in protocols or implementing `deinit`.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#2014](https://github.com/realm/SwiftLint/issues/2014)

* Fix false negatives in `unneeded_parentheses_in_closure_argument` rule
  when using `_` as one of the closure arguments.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#2017](https://github.com/realm/SwiftLint/issues/2017)

* Fix several rules that use attributes when linting with a Swift 4.1 toolchain.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#2019](https://github.com/realm/SwiftLint/issues/2019)

* Don't trigger violations in `let_var_whitespace` rule when using local
  variables when linting with a Swift 4.1 toolchain.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#2021](https://github.com/realm/SwiftLint/issues/2021)

* Improve `type_name` rule violations to be positioned on the type name.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#2021](https://github.com/realm/SwiftLint/issues/2021)

* Use SourceKit to validate `associatedtype` and `typealias` in `type_name` rule
  when linting with Swift 4.1.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#2021](https://github.com/realm/SwiftLint/issues/2021)

* Fix some cases where violations would still be triggered when using the
  `ignores_function_declarations` configuration of `line_length` rule.  
  [Manabu Nakazawa](https://github.com/mshibanami)

* Fix false positive in `empty_enum_arguments` rule when using closures.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#2041](https://github.com/realm/SwiftLint/issues/2041)

* Fix false positives in `force_unwrapping` rule when declaring functions that
  return implicitly unwrapped collections (for example `[Int]!` or
  `[AnyHashable: Any]!`).  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#2042](https://github.com/realm/SwiftLint/issues/2042)

* Fix directories with a `.swift` suffix being treated as files.  
  [Jamie Edge](https://github.com/JamieEdge)
  [#1948](https://github.com/realm/SwiftLint/issues/1948)

## 0.24.2: Dented Tumbler

#### Breaking

* None.

#### Enhancements

* None.

#### Bug Fixes

* No longer log if the `indentation` key isn't set in the configuration file.  
  [JP Simard](https://github.com/jpsim)
  [#1998](https://github.com/realm/SwiftLint/issues/1998)

## 0.24.1: Dented Tumbler

##### Breaking

* None.

##### Enhancements

* Invalidate cache when Swift patch version changes.  
  [Norio Nomura](https://github.com/norio-nomura)

* Add `private_action` opt-in rule which warns against public
  @IBAction methods.  
  [Ornithologist Coder](https://github.com/ornithocoder)
  [#1931](https://github.com/realm/SwiftLint/issues/1931)

* Add `yoda_condition` opt-in rule which warns when Yoda conditions are used.
  That is, when the constant portion of the expression is on the left side of a
  conditional statement.  
  [Daniel Metzing](https://github.com/dirtydanee)
  [#1924](https://github.com/realm/SwiftLint/issues/1924)

* Indentation can now be specified via a configuration file.  
  [Noah McCann](https://github.com/nmccann)
  [RubenSandwich](https://github.com/RubenSandwich)
  [#319](https://github.com/realm/SwiftLint/issues/319)

* Add `required_enum_case` opt-in rule which allows enums that
  conform to protocols to require one or more cases.  Useful for
  result enums.  
  [Donald Ritter](https://github.com/donald-m-ritter)

* Add `discouraged_object_literal` opt-in rule which encourages initializers
  over object literals.  
  [Ornithologist Coder](https://github.com/ornithocoder)
  [#1987](https://github.com/realm/SwiftLint/issues/1987)

* Adds `prefixed_toplevel_constant` opt-in rule which encourages top-level
  constants to be prefixed by `k`.  
  [Ornithologist Coder](https://github.com/ornithocoder)
  [#1907](https://github.com/realm/SwiftLint/issues/1907)

* Added `explicit_acl` opt-in rule to enforce explicit access control levels.  
  [Josep Rodriguez](https://github.com/joseprl89)
  [#1822](https://github.com/realm/SwiftLint/issues/1649)

##### Bug Fixes

* Fix false positives in `control_statement` rule when methods with keyword
  names are used.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#1946](https://github.com/realm/SwiftLint/issues/1946)

* Fix false positives in `for_where` rule when pattern matching (`if case`)
  is used.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#1968](https://github.com/realm/SwiftLint/issues/1968)

* Fix false positives in `unused_closure_parameter` rule when closure is wrapped
  in parentheses.  
  [JP Simard](https://github.com/jpsim)
  [#1979](https://github.com/realm/SwiftLint/issues/1979)

## 0.24.0: Timed Dry

##### Breaking

* SwiftLint now requires Xcode 9 and Swift 3.2+ to build.  
  [Marcelo Fabri](https://github.com/marcelofabri)

* Remove `SwiftExpressionKind.other`.  
  [Marcelo Fabri](https://github.com/marcelofabri)

##### Enhancements

* Add `sorted_first_last` opt-in rule to encourage using `min()` or `max()`
  over `sorted().first` or `sorted().last`.  
  [Tom Quist](https://github.com/tomquist)
  [#1932](https://github.com/realm/SwiftLint/issues/1932)

* Add `quick_discouraged_focused_test` opt-in rule which warns against
  focused tests in Quick tests.  
  [Ornithologist Coder](https://github.com/ornithocoder)
  [#1905](https://github.com/realm/SwiftLint/issues/1905)

* Add `override_in_extension` opt-in rule that warns against overriding
  declarations in an `extension`.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#1884](https://github.com/realm/SwiftLint/issues/1884)

* Add `[f,x]{describe, context, itBehavesLike}` to `quick_discouraged_call`
  rule.  
  [Ornithologist Coder](https://github.com/ornithocoder)
  [#1903](https://github.com/realm/SwiftLint/issues/1903)

* Add `quick_discouraged_pending_test` opt-in rule which warns against
  pending tests in Quick tests.  
  [Ornithologist Coder](https://github.com/ornithocoder)
  [#1909](https://github.com/realm/SwiftLint/issues/1909)

* Speed up equality tests for `[Rule]` and `Configuration` values.  
  [JP Simard](https://github.com/jpsim)

* Make `Configuration` conform to `Hashable`.  
  [JP Simard](https://github.com/jpsim)

* Speed up reading cached results by about 200%.  
  [JP Simard](https://github.com/jpsim)

* Add `catch` to the statements checked by the `control_statement` rule.  
  [JP Simard](https://github.com/jpsim)

* Make `sorted_imports` correctable.  
  [Samuel Susla](https://github.com/sammy-sc)
  [JP Simard](https://github.com/jpsim)
  [#1822](https://github.com/realm/SwiftLint/issues/1822)

* Make `sorted_imports` only validate within "groups" of imports on directly
  adjacent lines.  
  [Samuel Susla](https://github.com/sammy-sc)
  [JP Simard](https://github.com/jpsim)
  [#1822](https://github.com/realm/SwiftLint/issues/1822)

##### Bug Fixes

* Extend `first_where` and `contains_over_first_not_nil` rules to also detect
  cases where calls to `filter` and `first` are parenthesized.  
  [Tom Quist](https://github.com/tomquist)

* Correct equality tests for `Configuration` values. They previously didn't
  account for `warningThreshold` or `cachePath`.  
  [JP Simard](https://github.com/jpsim)

* Fix false positive in `multiline_parameters` rule when parameter is a closure
  with default value.  
  [Ornithologist Coder](https://github.com/ornithocoder)
  [#1912](https://github.com/realm/SwiftLint/issues/1912)

* Fix caching on Linux.  
  [JP Simard](https://github.com/jpsim)

* Fix crashes due to races.  
  [JP Simard](https://github.com/jpsim)

* Fix `String.characters` deprecation warnings when compiling with Swift
  4.0.2.  
  [JP Simard](https://github.com/jpsim)

## 0.23.1: Rewash: Forgotten Load Edition

##### Breaking

* None.

##### Enhancements

* None.

##### Bug Fixes

* Fix false positive in `array_init` rule when using a `map` that
  doesn't take a closure.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#1878](https://github.com/realm/SwiftLint/issues/1878)

* `superfluous_disable_command` rule can now be disabled as expected when
  using `// swiftlint:disable superfluous_disable_command`.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#1890](https://github.com/realm/SwiftLint/issues/1890)

## 0.23.0: Permanent Press Cycle

##### Breaking

* None.

##### Enhancements

* Fix csv reporter to output records with new lines.  
  [atetlaw](https://github.com/atetlaw)

* Add `contains_over_first_not_nil` rule to encourage using `contains` over
  `first(where:) != nil`.  
  [Samuel Susla](https://github.com/sammy-sc)
  [#1514](https://github.com/realm/SwiftLint/issues/1514)

* Add `fallthrough` rule that flags usage of `fallthrough`.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#1834](https://github.com/realm/SwiftLint/issues/1834)

* Improve `colon` rule to catch violations in dictionary types
  (e.g. `[String: Int]`), when using `Any` and on function calls.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#1074](https://github.com/realm/SwiftLint/issues/1074)
  [#1389](https://github.com/realm/SwiftLint/issues/1389)

* Add `switch_case_alignment` rule to validate that `case` and `default`
  statements are vertically aligned with their enclosing `switch` statement.  
  [Austin Lu](https://github.com/austinlu)

* Add `array_init` opt-in rule to validate that `Array(foo)` should be preferred
  over `foo.map({ $0 })`.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#1271](https://github.com/realm/SwiftLint/issues/1271)

* Truncate long configuration console descriptions to fit in the console window
  when running `swiftlint rules`.  
  [JP Simard](https://github.com/jpsim)
  [#1002](https://github.com/realm/SwiftLint/issues/1002)

* Add `multiline_arguments` opt-in rule that warns to either keep
  all the arguments of a function call on the same line,
  or one per line.  
  [Marcel Jackwerth](https://github.com/sirlantis)

* Add `unneeded_break_in_switch` rule to validate that no extra `break`s are
  added in `switch` statements.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#1870](https://github.com/realm/SwiftLint/issues/1870)

* Add `literal_expression_end_indentation` opt-in rule to validate that
  array and dictionary literals ends have the same indentation as the line
  that started them.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#1435](https://github.com/realm/SwiftLint/issues/1435)

##### Bug Fixes

* Improve how `opening_brace` rule reports violations locations.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#1811](https://github.com/realm/SwiftLint/issues/1811)

* Fix false negatives in `unneeded_parentheses_in_closure_argument` rule
  when using capture lists.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#1817](https://github.com/realm/SwiftLint/issues/1817)

* Fix handling of attributes (`lazy`, `objc`, etc.) for the `let_var_whitespace`
  rule.  
  [David Catmull](https://github.com/Uncommon)
  [#1770](https://github.com/realm/SwiftLint/issues/1770)
  [#1812](https://github.com/realm/SwiftLint/issues/1812)

* Fix false positives in `for_where` rule when using `if var` inside `for`.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#1838](https://github.com/realm/SwiftLint/issues/1838)

* Fix false positive in `class_delegate_protocol` rule when using Swift 4.0.1.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#1856](https://github.com/realm/SwiftLint/issues/1856)

* Print multi-line configuration values in a single line when running
  `swiftlint rules` to avoid breaking the table format.  
  [JP Simard](https://github.com/jpsim)
  [#1002](https://github.com/realm/SwiftLint/issues/1002)

* Ignore SwiftLint commands (`swiftlint:(disable|enable)`) in `file_header`
  rule, making it work better with `superfluous_disable_command` rule.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#1810](https://github.com/realm/SwiftLint/issues/1810)

* Fix false negatives in `generic_type_name`, `identifier_name` and `type_name`
  rules when using `allowed_symbols`.  
  [Marcelo Fabri](https://github.com/marcelofabri)

## 0.22.0: Wrinkle-free

##### Breaking

* Nested configurations will now be merged with parent configurations rather
  than replace them outright.  
  [Stéphane Copin](https://github.com/stephanecopin)
  [JP Simard](https://github.com/jpsim)
  [#676](https://github.com/realm/SwiftLint/issues/676)

##### Enhancements

* Add `is_disjoint` rule to encourage using `Set.isDisjoint(with:)` over
  `Set.intersection(_:).isEmpty`.  
  [JP Simard](https://github.com/jpsim)

* Add `xctfail_message` rule to enforce XCTFail
  calls to include a description of the assertion.  
  [Ornithologist Coder](https://github.com/ornithocoder)
  [#1370](https://github.com/realm/SwiftLint/issues/1370)

* Add `joined_default_parameter` correctable opt-in rule to discourage
  explicit usage of the default separator.  
  [Ornithologist Coder](https://github.com/ornithocoder)
  [#1093](https://github.com/realm/SwiftLint/issues/1093)
  [#1757](https://github.com/realm/SwiftLint/issues/1757)

* Files with extensions other than `.swift` can now be used as arguments
  to `--file` when linting or autocorrecting.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#1721](https://github.com/realm/SwiftLint/issues/1721)

* Allow `()?`, `Void?`, `()!`, and `Void!` as return types in
  `redundant_void_return` rule.  
  [Ryan Booker](https://github.com/ryanbooker)
  [#1761](https://github.com/realm/SwiftLint/issues/1761)

* Add `single_test_class` opt-in rule to validate that test files
  only contain a single `QuickSpec` or `XCTestCase` subclass.  
  [Ornithologist Coder](https://github.com/ornithocoder)
  [#1779](https://github.com/realm/SwiftLint/issues/1779)

* Produce an error when a `// swiftlint:disable` command does not silence
  any violations.  
  [JP Simard](https://github.com/jpsim)
  [#1102](https://github.com/realm/SwiftLint/issues/1102)

* Add `quick_discouraged_call` opt-in rule to discourage calls and object
  initialization inside 'describe' and 'context' block in Quick tests.  
  [Ornithologist Coder](https://github.com/ornithocoder)
  [#1781](https://github.com/realm/SwiftLint/issues/1781)

* Invalidate cache when Swift version changes.  
  [Marcelo Fabri](https://github.com/marcelofabri)

* Add `pattern_matching_keywords` opt-in rule to enforce moving `let` and `var`
  keywords outside tuples in a `switch`.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#202](https://github.com/realm/SwiftLint/issues/202)

* Add `explicit_enum_raw_value` opt-in rule to allow refactoring the
  Swift API without breaking the API contract.  
  [Mazyod](https://github.com/mazyod)
  [#1778](https://github.com/realm/SwiftLint/issues/1778)

* Add `no_grouping_extension` opt-in rule to disallow the use of extensions
  for code grouping purposes within the same file.  
  [Mazyod](https://github.com/mazyod)
  [#1767](https://github.com/realm/SwiftLint/issues/1767)

* Improve `syntactic_sugar` violation message to be type-specific.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#1803](https://github.com/realm/SwiftLint/issues/1803)

* Add `multiple_closures_with_trailing_closure` rule that disallows trailing
  closure syntax when passing more than one closure argument to a function.  
  [Erik Strottmann](https://github.com/erikstrottmann)
  [#1801](https://github.com/realm/SwiftLint/issues/1801)

##### Bug Fixes

* Fix false positive on `force_unwrapping` rule when declaring
  local variable with implicity unwrapped type.  
  [Otávio Lima](https://github.com/otaviolima)
  [#1710](https://github.com/realm/SwiftLint/issues/1710)

* Fix the warning message and autocorrection of `vertical_whitespace` rule to
  display the maximum empty lines allowed if `max_empty_lines` is greater
  than 1.  
  [Hossam Ghareeb](https://github.com/hossamghareeb)
  [#1763](https://github.com/realm/SwiftLint/issues/1763)

* Fix for the wrong configuration being used when using `--path` and a
  configuration exists in a parent directory.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#1744](https://github.com/realm/SwiftLint/issues/1744)

* Fix false positive on `unused_enumerated` rule with complex variable
  bindings.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#1787](https://github.com/realm/SwiftLint/issues/1787)

* Fix incorrect violations and autocorrections on
  `unneeded_parentheses_in_closure_argument` rule that were generated in some
  cases (mainly when using chained method calls with closures).  
  [Marcelo Fabri](https://github.com/marcelofabri)

## 0.21.0: Vintage Washboard

##### Breaking

* Xcode 8.3 or later and Swift 3.1 or later are required to build.  
  [Norio Nomura](https://github.com/norio-nomura)

##### Enhancements

* Rules are now categorized as `lint`, `idiomatic`, `style`, `metrics`
  or `performance`. Currently this is just used for documentation purposes
  when you run `swiftlint rules` or `swiftlint generate-docs`.  
  [Marcelo Fabri](https://github.com/marcelofabri)

* Add [rules documentation](Rules.md) generation.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#1078](https://github.com/realm/SwiftLint/issues/1078)

* Add `private_over_fileprivate` correctable rule to check for top-level usages
  of `fileprivate` and recommend `private` instead. This is in line with
  SE-0169's goal "for `fileprivate` to be used rarely". There is a also a new
  `strict_fileprivate` opt-in rule that will mark every `fileprivate`
  as a violation (especially useful with Swift 4).  
  [Jose Cheyo Jimenez](https://github.com/masters3d)
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#1469](https://github.com/realm/SwiftLint/issues/1469)
  [#1058](https://github.com/realm/SwiftLint/issues/1058)

* Add `let_var_whitespace` opt-in rule to enforce that `let`/`var` declarations
  should be separated from other statements by a single blank line.  
  [Uncommon](https://github.com/Uncommon)
  [#1461](https://github.com/realm/SwiftLint/issues/1461)

* Improve performance when linting and correcting on Linux,
  matching macOS behavior.  
  [JP Simard](https://github.com/jpsim)
  [#1577](https://github.com/realm/SwiftLint/issues/1577)

* Don't trigger `implicit_getter` violations when attributes (such as `mutating`
  or `@inline`) are present.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#1309](https://github.com/realm/SwiftLint/issues/1309)
  [#1589](https://github.com/realm/SwiftLint/issues/1589)

* Add `--use-tabs` option to `AutoCorrectOptions`, enabling formatting using
  tabs over spaces.  
  [Cody Winton](https://github.com/codytwinton)
  [#1327](https://github.com/realm/SwiftLint/issues/1327)

* Improve `autocorrect` performance by running it in parallel.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#1578](https://github.com/realm/SwiftLint/issues/1578)

* Support building with Xcode 9 beta 3 in Swift 3.2 mode.  
  [JP Simard](https://github.com/jpsim)

* Add support for optional `error` severity level configuration.  
  [Jamie Edge](https://github.com/JamieEdge)
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#1647](https://github.com/realm/SwiftLint/issues/1647)

* Add `unneeded_parentheses_in_closure_argument` opt-in correctable rule that
  warns against using parentheses around argument declarations in closures.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#1483](https://github.com/realm/SwiftLint/issues/1483)

* Add `--disabled` flag to `swiftlint rules` to print only rules that are
  not enabled in the configuration.  
  [Marcelo Fabri](https://github.com/marcelofabri)

* Add `ignore_comment_only_lines` boolean configuration option
  to `file_length` rule. With the option enabled, `file_length` will
  ignore lines which have only comments.  
  [Samuel Susla](https://github.com/sammy-SC)
  [#1165](https://github.com/realm/SwiftLint/issues/1165)

* Improve `file_header` rule description.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#1492](https://github.com/realm/SwiftLint/issues/1492)

* Add `trailing_closure` opt-in rule that validates that trailing
  closure syntax should be used whenever possible.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#54](https://github.com/realm/SwiftLint/issues/54)

* Shebang (`#!`) in the beginning of a file is now ignored by all rules.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#1294](https://github.com/realm/SwiftLint/issues/1294)

* Add `block_based_kvo` rule that enforces the usage of the new block based
  KVO API added when linting with Swift 3.2 or later.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#1714](https://github.com/realm/SwiftLint/issues/1714)

* Make `file_header` rule ignore doc comments.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#1719](https://github.com/realm/SwiftLint/issues/1719)

* Allow using environment variables in a configuration file in the form of
  `${SOME_VARIABLE}`. The variables will be expanded when the configuration
  is first loaded.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#1512](https://github.com/realm/SwiftLint/issues/1512)

* Treat `yes`, `no`, `on` and `off` as strings (and not booleans) when loading
  configuration files.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#1424](https://github.com/realm/SwiftLint/issues/1424)

* Add `discouraged_direct_init` rule that discourages direct
  initialization of certain types.  
  [Ornithologist Coder](https://github.com/ornithocoder)
  [#1306](https://github.com/realm/SwiftLint/issues/1306)

##### Bug Fixes

* Fix false positive on `redundant_discardable_let` rule when using
  `while` statements.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#1669](https://github.com/realm/SwiftLint/issues/1669)

* Fix all custom rules not being applied when any rule is configured
  incorrectly.  
  [Jamie Edge](https://github.com/JamieEdge)
  [#1586](https://github.com/realm/SwiftLint/issues/1586)

* Fix crash when using `--config` with a relative path and
  `--path` with a file.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#1694](https://github.com/realm/SwiftLint/issues/1694)

* Fix `mark` rule corrections generating invalid code in some cases.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#1029](https://github.com/realm/SwiftLint/issues/1029)

* Fix false positive in `empty_enum_arguments` rule when using wildcards and
  `where` clauses.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#1722](https://github.com/realm/SwiftLint/issues/1722)

* Fix false positive in `large_tuple` rule when using throwing closure.  
  [Liquidsoul](https://github.com/liquidsoul)

* Make `vertical_parameter_alignment` more robust, fixing false positives and
  detecting previously missed violations.  
  [JP Simard](https://github.com/jpsim)
  [#1488](https://github.com/realm/SwiftLint/issues/1488)

## 0.20.1: More Liquid Fabric Softener

##### Breaking

* None.

##### Enhancements

* None.

##### Bug Fixes

* Fix typo in `FatalErrorMessageRule`.  
  [Alexander Lash](https://github.com/abl)

* Don't trigger an `extension_access_modifier` violation when all extension
  members are `open`, as `open extension` is not supported by Swift.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#1629](https://github.com/realm/SwiftLint/issues/1629)

* Don't trigger a `vertical_parameter_alignment_on_call` violation when
  trailing closures are used.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#1635](https://github.com/realm/SwiftLint/issues/1635)

* Make `vertical_parameter_alignment_on_call` more flexible when multiline
  parameters are used.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#1630](https://github.com/realm/SwiftLint/issues/1630)
  [#1643](https://github.com/realm/SwiftLint/issues/1643)

* Use the directory's `.swiftlint.yml` when `--path` is used.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#1631](https://github.com/realm/SwiftLint/issues/1631)

## 0.20.0: Liquid Fabric Softener

##### Breaking

* None.

##### Enhancements

* Detect more violations of `force_unwrapping` when using subscripts.  
  [Otávio Lima](https://github.com/otaviolima)

* Match `(Void)` as return type in the `void_return` rule.  
  [Anders Hasselqvist](https://github.com/nevil)

* Add `multiline_parameters` opt-in rule that warns to either keep
  all the parameters of a method or function on the same line,
  or one per line.  
  [Ornithologist Coder](https://github.com/ornithocoder)

* Update `function_parameter_count` rule to ignore overridden methods.  
  [Markus Gasser](https://github.com/frenetisch-applaudierend)
  [#1562](https://github.com/realm/SwiftLint/issues/1562)

* Skip files with valid cache & no violations when auto correcting.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#1554](https://github.com/realm/SwiftLint/issues/1554)

* Don't trigger violations from the `private_unit_test` rule when a method has
  parameters.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#1532](https://github.com/realm/SwiftLint/issues/1532)

* Don't trigger violations from the `discarded_notification_center_observer`
  rule when the observer is being returned from a function that is not marked
  as `@discardableResult`.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#1525](https://github.com/realm/SwiftLint/issues/1525)

* Add `extension_access_modifier` opt-in rule validating that if all the
  declarations in a given extension have the same Access Control Level, the ACL
  keyword should be applied to the top-level extension.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#1546](https://github.com/realm/SwiftLint/issues/1546)

* Add `vertical_parameter_alignment_on_call` opt-in rule that validates that
  parameters are vertically aligned on a method call.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#1037](https://github.com/realm/SwiftLint/issues/1037)

* Add `code_literal` and `image_literal` boolean configuration options to
  `object_literal` rule. They allow to only check for one or the other
  literal type instead of both together.  
  [Cihat Gündüz](https://github.com/Dschee)
  [#1587](https://github.com/realm/SwiftLint/issues/1587)

##### Bug Fixes

* Fix false positive in `empty_enum_arguments` rule when calling methods.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#1597](https://github.com/realm/SwiftLint/issues/1597)

* Fix crash in `unused_closure_parameter` rule when using unicode identifiers.  
  [Woo-Sik Byun](https://github.com/woosiki)
  [Marcelo Fabri](https://github.com/marcelofabri)

* Fix two false positives in `force_unwrapping` rule.  
  [Otávio Lima](https://github.com/otaviolima)
  [#614](https://github.com/realm/SwiftLint/issues/614)
  [#977](https://github.com/realm/SwiftLint/issues/977)
  [#1614](https://github.com/realm/SwiftLint/issues/1614)

* Fix custom rules not working correctly with comment commands.  
  [JP Simard](https://github.com/jpsim)
  [#1558](https://github.com/realm/SwiftLint/issues/1558)

* Fix incorrectly using configuration files named `.swiftlint.yml` when they are
  located in the same directory as a differently-named, user-provided custom
  configuration file.  
  [JP Simard](https://github.com/jpsim)
  [#1531](https://github.com/realm/SwiftLint/issues/1531)

* Fix `empty_count` rule false positive in words that include "count".  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#1622](https://github.com/realm/SwiftLint/issues/1622)

* Use `validates_start_with_lowercase` key when decoding configurations for
  `generic_type_name`, `identifier_name` and `type_name` rules. This key was
  used on the docs, but internally `validates_start_lowercase` was used.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#1626](https://github.com/realm/SwiftLint/issues/1626)

## 0.19.0: Coin-Operated Machine

##### Breaking

* Remove support for Swift 2.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#1453](https://github.com/realm/SwiftLint/issues/1453)

* Remove `missing_docs` and `valid_docs` rules since
  they were already disabled.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#1453](https://github.com/realm/SwiftLint/issues/1453)

* Add `modificationDate(forFileAtPath:)` function requirement to
  `LintableFileManager` protocol.  
  [Victor Pimentel](https://github.com/victorpimentel)

* Several breaking changes to `LinterCache`.  
  [Victor Pimentel](https://github.com/victorpimentel)
  [JP Simard](https://github.com/jpsim)

* Remove `Configuration.hash` property.  
  [Victor Pimentel](https://github.com/victorpimentel)

* Rename `ConditionalReturnsOnNewline` struct to
  `ConditionalReturnsOnNewlineRule` to match rule naming conventions.  
  [JP Simard](https://github.com/jpsim)

##### Enhancements

* Cache linter results for files unmodified since the previous linter run.  
  [Victor Pimentel](https://github.com/victorpimentel)
  [JP Simard](https://github.com/jpsim)
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#1184](https://github.com/realm/SwiftLint/issues/1184)
  [#1550](https://github.com/realm/SwiftLint/issues/1550)

* Add opt-in configurations to `generic_type_name`, `identifier_name` and
  `type_name` rules to allow excluding non-alphanumeric characters and names
  that start with uppercase.  
  [Javier Hernández](https://github.com/jaherhi)
  [#541](https://github.com/realm/SwiftLint/issues/541)

* Adds support for `excluded` in custom rules to exclude files.  
  [Nigel Flack](https://github.com/nigelflack)
  [#1437](https://github.com/realm/SwiftLint/issues/1437)

* Make `trailing_comma` rule autocorrectable.  
  [Samuel Susla](https://github.com/sammy-SC)
  [Jeremy David Giesbrecht](https://github.com/SDGGiesbrecht)
  [#1326](https://github.com/realm/SwiftLint/issues/1326)

* Added `no_extension_access_modifier` opt-in rule to disallow access modifiers
  completely, à la SE-0119.  
  [Jose Cheyo Jimenez](https://github.com/masters3d)
  [#1457](https://github.com/realm/SwiftLint/issues/1457)

* Add lowercase and missing colon checks to the `mark` rule.  
  [Jason Moore](https://github.com/xinsight)

* Improve violation reason wording in `function_body_length`,
  `large_type`, and `type_body_length` rules.  
  [ultimatedbz](https://github.com/ultimatedbz)

* Add `explicit_top_level_acl` opt-in rule that validates that all top
  level declarations should explicitly be marked with an Access Control
  Level (`private`, `fileprivate`, `internal`, `public` or `open`).  
  [J. Cheyo Jimenez](https://github.com/masters3d)
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#58](https://github.com/realm/SwiftLint/issues/58)

* Add `implicit_return` opt-in rule that warns against using the `return`
  keyword when it can be omitted inside closures.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#1194](https://github.com/realm/SwiftLint/issues/1194)

* Add option to `unused_optional_binding` rule to ignore `try?`
  in `guard` statements.  
  [Sega-Zero](https://github.com/Sega-Zero)
  [#1432](https://github.com/realm/SwiftLint/issues/1432)

* Add `empty_enum_arguments` correctable rule that warns against using
  silent associated values inside a `case`.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#1425](https://github.com/realm/SwiftLint/issues/1425)
  [#1549](https://github.com/realm/SwiftLint/issues/1549)

* Remove `file.zip` from the `Pods` directory when installing SwiftLint via
  CocoaPods.  
  [Hesham Salman](https://github.com/heshamsalman)
  [#1507](https://github.com/realm/SwiftLint/issues/1507)

* Add `protocol_property_accessors_order` correctable rule that validates
  that the order of accessors is `get set` when declaring variables
  in protocols.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#1504](https://github.com/realm/SwiftLint/issues/1504)

* Make `Region` & `Command` structs conform to `Equatable`.  
  [JP Simard](https://github.com/jpsim)

* Make `closure_spacing` a `CorrectableRule`.  
  [J. Cheyo Jimenez](https://github.com/masters3d)

##### Bug Fixes

* `emoji` and `checkstyle` reporter output report sorted by file name.  
  [norio-nomura](https://github.com/norio-nomura)
  [#1429](https://github.com/realm/SwiftLint/issues/1429)

* Prevent false positive in `shorthand_operator` rule.  
  [sammy-SC](https://github.com/sammy-SC)
  [#1254](https://github.com/realm/SwiftLint/issues/1254)

* Fix typo in `DiscardedNotificationCenterObserverRule`.  
  [Spencer Kaiser](https://github.com/spencerkaiser)

* Fix `empty_parameters` rule with Swift 3.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#1460](https://github.com/realm/SwiftLint/issues/1460)

* Prevent triggering `redundant_optional_initialization` rule
  on a `lazy var` since it needs initialization.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#1334](https://github.com/realm/SwiftLint/issues/1334)

* Fix `ignores_case_statements` key in `cyclomatic_complexity` description.  
  [Jeff Blagdon](https://github.com/jefflovejapan)
  [#1434](https://github.com/realm/SwiftLint/issues/1434)

* Fall back to reporting violations on line `1` if no line was provided for the
  violation's location, ensuring Xcode always displays the warning or error.  
  [rjhodge](https://github.com/rjhodge)
  [JP Simard](https://github.com/jpsim)
  [#1520](https://github.com/realm/SwiftLint/issues/1520)

* Fix crash or incorrect violation location with strings including multi-byte
  unicode characters.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#1006](https://github.com/realm/SwiftLint/issues/1006)

* Fix false positive in `syntactic_sugar` rule when using nested types named
  `Optional`, `ImplicitlyUnwrappedOptional`, `Array` or `Dictionary`.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#1508](https://github.com/realm/SwiftLint/issues/1508)

* Fix false positives in `prohibited_super_call` & `overridden_super_call` rules
  where calls to `super` were done in nested scopes such as `defer` blocks.  
  [JP Simard](https://github.com/jpsim)
  [#1301](https://github.com/realm/SwiftLint/issues/1301)

* Fix non-root configurations logging configuration warnings more than once.  
  [JP Simard](https://github.com/jpsim)
  [#949](https://github.com/realm/SwiftLint/issues/949)

* Fix some overlapping `// swiftlint` commands not being applied.  
  [JP Simard](https://github.com/jpsim)
  [#1388](https://github.com/realm/SwiftLint/issues/1388)

## 0.18.1: Misaligned Drum

##### Breaking

* None.

##### Enhancements

* None.

##### Bug Fixes

* Compile releases in the 'Release' configuration rather than 'Debug'.

## 0.18.0: Misaligned Drum

##### Breaking

* Replace YamlSwift with Yams. SwiftLint no longer includes YamlSwift. If your
  project implicitly depends on YamlSwift, you need to modify it to depend on
  YamlSwift explicitly.  
  [norio-nomura](https://github.com/norio-nomura)
  [#1412](https://github.com/realm/SwiftLint/issues/1412)

* Yams interprets YAML more strictly than YamlSwift, so if your YAML
  configurations previously worked with SwiftLint but didn't fully conform to
  the YAML 1.2 standard, you'll need to fix those validation errors.
  For example:
  ```yaml
  custom_rules:
    wrong_regex:
      name: "wrong regex"
      regex: "((assert|precondition)\(false)" # '\' in "" means escape sequence
    strict_regex:
      name: "strict regex"
      regex: '((assert|precondition)\(false)' # Use single quotes
  ```

##### Enhancements

* Support compiling with Xcode 8.3 and Swift 3.1.  
  [Keith Smiley](https://github.com/keith)

* Fix false positives on `for_where` rule and skip violation on
  complex conditions.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#1387](https://github.com/realm/SwiftLint/issues/1387)

* Print YAML configuration errors in locatable format compatible with Xcode's
  Issue Navigator.  
  ![](https://cloud.githubusercontent.com/assets/33430/24688866/f18d40f4-19fd-11e7-8f17-72f1fca20406.png)

##### Bug Fixes

* Fix --lenient enforcement not being applied to all violations.  
  [aaroncrespo](https://github.com/aaroncrespo)
  [#1391](https://github.com/realm/SwiftLint/issues/1391)

* Fix false positives in `unused_optional_binding` rule.  
  [Daniel Rodríguez Troitiño](https://github.com/drodriguez)
  [#1376](https://github.com/realm/SwiftLint/issues/1376)

* Fix false positives in `redundant_discardable_let` rule.  
  [Jeremy David Giesbrecht](https://github.com/SDGGiesbrecht)
  [#1415](https://github.com/realm/SwiftLint/issues/1415)

## 0.17.0: Extra Rinse Cycle

##### Breaking

* `variable_name` rule (`VariableNameRule`) is now `identifier_name`
  (`IdentifierNameRule`) as it validates other identifiers as well.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#663](https://github.com/realm/SwiftLint/issues/663)

* Fix `sorted_imports` rule to sort ignoring case.  
  [Keith Smiley](https://github.com/keith)
  [#1185](https://github.com/realm/SwiftLint/issues/1185)

* Temporarily disable cache when linting. This will be re-enabled in a future
  version after important cache-related issues have been addressed.  
  [Marcelo Fabri](https://github.com/marcelofabri)

##### Enhancements

* Add `implicitly_unwrapped_optional` opt-in rule that warns against using
  implicitly unwrapped optionals, except cases when this IUO is an IBOutlet.  
  [Siarhei Fedartsou](https://github.com/SiarheiFedartsou)
  [#56](https://github.com/realm/SwiftLint/issues/56)

* Performance improvements to `generic_type_name`,
  `redundant_nil_coalescing`, `mark`, `first_where` and
  `vertical_whitespace` rules.  
  [Marcelo Fabri](https://github.com/marcelofabri)

* Add `discarded_notification_center_observer` rule that warns when the result
  of `NotificationCenter.addObserver(forName:object:queue:using:)` is not stored
  so it can be removed later.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#1062](https://github.com/realm/SwiftLint/issues/1062)

* Add `notification_center_detachment` rule that warns against an object
  removing itself from `NotificationCenter` in an unsafe location.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#1061](https://github.com/realm/SwiftLint/issues/1061)

* Accept `AnyObject` and `NSObjectProtocol` in `class_delegate_protocol`.  
  [Jon Shier](https://github.com/jshier)
  [#1261](https://github.com/realm/SwiftLint/issues/1261)

* Add `ignores_function_declarations` and `ignores_comments` as options to
  `LineLengthRule`.  
  [Michael L. Welles](https://github.com/mlwelles)
  [#598](https://github.com/realm/SwiftLint/issues/598)
  [#975](https://github.com/realm/SwiftLint/issues/975)

* Add `for_where` rule that validates that `where` is used in a `for` loop
  instead of a single `if` expression inside the loop.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#1228](https://github.com/realm/SwiftLint/issues/1228)

* `unused_enumerated` rule now warns when only the index is being used.
  You should use `.indices` instead of `.enumerated()` in this case.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#1278](https://github.com/realm/SwiftLint/issues/1278)

* Add `ignores_case_statements` as option to `CyclomaticComplexityRule`.  
  [Michael L. Welles](https://github.com/mlwelles)
  [#1298](https://github.com/realm/SwiftLint/issues/1298)

* Add correctable `redundant_discardable_let` rule that warns when
  `let _ = foo()` is used to discard a result from a function instead of
  `_ = foo()`.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#1232](https://github.com/realm/SwiftLint/issues/1232)

* Accept global and local variables in `implicit_getter` rule.  
  [Marcelo Fabri](https://github.com/marcelofabri)

* Add `--enabled` (or `-e`) switch to the `rules` CLI command, to only display
  enabled rules.  
  [Natan Rolnik](https://github.com/NatanRolnik)
  [#1270](https://github.com/realm/SwiftLint/issues/1270)

* Now `nesting` rule can be configured with a type and statement level.  
  [Hayashi Tatsuya](https://github.com/sora0077)
  [#1318](https://github.com/realm/SwiftLint/issues/1318)

* Add `explicit_type_interface` opt-in rule that validates that the properties
  have an explicit type interface.  
  [Kim de Vos](https://github.com/kimdv)

* Add `--lenient` CLI option to `lint` command. Facilitates running a lint task
  that doesn't fail a pipeline of other tasks.  
  [aaroncrespo](https://github.com/aaroncrespo)
  [#1322](https://github.com/realm/SwiftLint/issues/1322)

* Add `fatal_error_message` opt-in rule that validates that `fatalError()` calls
  have a message.  
  [Kim de Vos](https://github.com/kimdv)
  [#1348](https://github.com/realm/SwiftLint/issues/1348)

##### Bug Fixes

* Fix crashes when accessing cached regular expressions when linting in
  parallel.  
  [JP Simard](https://github.com/jpsim)
  [#1344](https://github.com/realm/SwiftLint/issues/1344)

* Fix a false positive on `large_tuple` rule when using closures.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#1234](https://github.com/realm/SwiftLint/issues/1234)

* Fix `force_unwrap` false positive for bool negation.  
  [Aaron McTavish](https://github.com/aamctustwo)
  [#918](https://github.com/realm/SwiftLint/issues/918)

* Fix false positive and wrong correction on `number_separator` rule.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#1242](https://github.com/realm/SwiftLint/issues/1242)

* Retain closure parameter types when they are specified during autocorrect.  
  [Allen Zeng](https://github.com/allen-zeng)
  [#1175](https://github.com/realm/SwiftLint/issues/1175)

* Fix `redundant_void_return` matches if return type starts with Void~.  
  [Hayashi Tatsuya](https://github.com/sora0077)

* Ignore `unused_closure_parameter` rule on closures that are called inline.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#1161](https://github.com/realm/SwiftLint/issues/1161)

* Disable `valid_docs` and `missing_docs` rules when running in Swift 2.3 or
  later as they have not been updated to work with those versions of Swift.
  Both rules are now opt-in because of this.  
  [JP Simard](https://github.com/jpsim)
  [#728](https://github.com/realm/SwiftLint/issues/728)

* Fix false positive on `large_tuple` rule when using generics inside a tuple.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#1257](https://github.com/realm/SwiftLint/issues/1257)

* Make `ASTRule` default implementation to navigate through the substructure
  even if its children are from a different kind. This fixes some violations not
  being reported in some contexts.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#1237](https://github.com/realm/SwiftLint/issues/1237)

* Reimplement `switch_case_on_newline` rule to be an `ASTRule` and be more
  reliable, fixing some false negatives and false positives.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#1268](https://github.com/realm/SwiftLint/issues/1268)

* Fix `closure_end_indentation` rule false positive when using single-line
  closures.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#1216](https://github.com/realm/SwiftLint/issues/1216)

* Fix `todo` rule messages when the comment is not on a new line.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#1304](https://github.com/realm/SwiftLint/issues/1304)

* Fix false negative on `unused_closure_parameter` rule.  
  [Hayashi Tatsuya](https://github.com/sora0077)

* Fix `checkstyle` report format.  
  [Yuki Oya](https://github.com/YukiOya)

## 0.16.1: Commutative Fabric Sheets

##### Breaking

* None.

##### Enhancements

* Improve `unused_optional_binding` rule on tuples check.  
  [Rafael Machado](https://github.com/rakaramos)

* Update `variable_name` to ignore overrides.  
  [Aaron McTavish](https://github.com/aamctustwo)
  [#1169](https://github.com/realm/SwiftLint/issues/1169)

* Update `number_separator` rule to allow for specifying
  minimum length of fraction.  
  [Bjarke Søndergaard](https://github.com/bjarkehs)
  [#1200](https://github.com/realm/SwiftLint/issues/1200)

* Update `legacy_constant` rule to support `CGFloat.pi` and `Float.pi`.  
  [Aaron McTavish](https://github.com/aamctustwo)
  [#1198](https://github.com/realm/SwiftLint/issues/1198)

##### Bug Fixes

* Fix false positives on `shorthand_operator` rule.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#1156](https://github.com/realm/SwiftLint/issues/1156)
  [#1163](https://github.com/realm/SwiftLint/issues/1163)

* Fix false positive on `redundant_optional_initialization` rule.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#1159](https://github.com/realm/SwiftLint/issues/1159)

* Fix false positive on `operator_usage_whitespace` rule with decimal
  literals in exponent format.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#1153](https://github.com/realm/SwiftLint/issues/1153)

* Fix `excluded` configuration not excluding files.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#1166](https://github.com/realm/SwiftLint/issues/1166)

* Disable commutative operations on `shorthand_operator` rule.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#1182](https://github.com/realm/SwiftLint/issues/1182)
  [#1183](https://github.com/realm/SwiftLint/issues/1183)
  [#1211](https://github.com/realm/SwiftLint/issues/1211)

* Fix crash when running in a Sandboxed environment, which also fixes Homebrew
  distribution. Set the `SWIFTLINT_SWIFT_VERSION` environment variable to either
  `2` or `3` to force that operation mode, bypassing the Swift version
  determined from SourceKit.  
  [JP Simard](https://github.com/jpsim)

## 0.16.0: Maximum Energy Efficiency Setting

##### Breaking

* Several API breaking changes were made to conform to the Swift 3 API Design
  Guidelines. We apologize for any inconvenience this may have caused.

##### Enhancements

* Speed up linting by caching linter results across invocations.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#868](https://github.com/realm/SwiftLint/issues/868)

* Speed up linting by processing multiple files and rules concurrently.  
  [JP Simard](https://github.com/jpsim)
  [#1077](https://github.com/realm/SwiftLint/issues/1077)

* Make many operations in SwiftLintFramework safe to call in multithreaded
  scenarios, including accessing `Linter.styleViolations`.  
  [JP Simard](https://github.com/jpsim)
  [#1077](https://github.com/realm/SwiftLint/issues/1077)

* Permit unsigned and explicitly-sized integer types in `valid_ibinspectable`  
  [Daniel Duan](https://github.com/dduan)

* Make `nimble_operator` rule correctable.  
  [Vojta Stavik](https://github.com/VojtaStavik)

* Add `vertical_parameter_alignment` rule that checks if parameters are
  vertically aligned for multi-line function declarations.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#1033](https://github.com/realm/SwiftLint/issues/1033)

* Add more helpful reason strings to TrailingCommaRule.  
  [Matt Rubin](https://github.com/mattrubin)

* Add `class_delegate_protocol` rule that warns against protocol declarations
  that aren't marked as `: class` or `@objc`.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#1039](https://github.com/realm/SwiftLint/issues/1039)

* Add correctable `redundant_optional_initialization` rule that warns against
  initializing optional variables with `nil`.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#1052](https://github.com/realm/SwiftLint/issues/1052)

* `redundant_nil_coalescing` rule is now correctable.  
  [Marcelo Fabri](https://github.com/marcelofabri)

* Make `number_separator` rule correctable.  
  [Marcelo Fabri](https://github.com/marcelofabri)

* `empty_parentheses_with_trailing_closure` rule is now correctable.  
  [Marcelo Fabri](https://github.com/marcelofabri)

* Add correctable `redundant_void_return` rule that warns against
  explicitly adding `-> Void` to functions.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#1066](https://github.com/realm/SwiftLint/issues/1066)

* Add an opt-in rule that enforces alphabetical sorting of imports.  
  [Scott Berrevoets](https://github.com/sberrevoets)
  [#900](https://github.com/realm/SwiftLint/issues/900)

* `type_name` rule forces enum values to be UpperCamelCase again
  when used with Swift 2.3.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#1090](https://github.com/realm/SwiftLint/issues/1090)

* Make `weak_delegate` rule ignore computed properties.  
  [Rafael Machado](https://github.com/rakaramos)
  [#1089](https://github.com/realm/SwiftLint/issues/1089)

* Add `object_literal` opt-in rule that warns against using image and color
  inits that can be replaced for `#imageLiteral` or `#colorLiteral` in
  Swift 3.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#1060](https://github.com/realm/SwiftLint/issues/1060)

* Now `number_separator` rule can be configured with a minimum length.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#1109](https://github.com/realm/SwiftLint/issues/1109)

* Add `compiler_protocol_init` rule that flags usage of initializers
  declared in protocols used by the compiler such as `ExpressibleByArrayLiteral`
  that shouldn't be called directly. Instead, you should use a literal anywhere
  a concrete type conforming to the protocol is expected by the context.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#1096](https://github.com/realm/SwiftLint/issues/1096)

* Add `large_tuple` configurable rule that validates that tuples shouldn't
  have too many members.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#1065](https://github.com/realm/SwiftLint/issues/1065)

* Add `generic_type_name` rule that validates generic constraint type names.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#51](https://github.com/realm/SwiftLint/issues/51)

* Update `vertical_whitespace` rule to allow configuration of the number of
  consecutive empty lines before a violation using `max_empty_lines`.
  The default value is still 1 line.  
  [Aaron McTavish](https://github.com/aamctustwo)
  [#769](https://github.com/realm/SwiftLint/issues/769)

* Add check to ignore urls in `line_length` rule when `ignores_urls`
  configuration is enabled.  
  [Javier Hernández](https://github.com/jaherhi)
  [#384](https://github.com/realm/SwiftLint/issues/384)

* Add `shorthand_operator` rule that validates that shorthand operators should
  be used when possible.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#902](https://github.com/realm/SwiftLint/issues/902)

* Allow specifying a `swiftlint_version` configuration key which will log a
  warning if the current running version of SwiftLint is different than this
  value.  
  [JP Simard](https://github.com/jpsim)
  [#221](https://github.com/realm/SwiftLint/issues/221)

* Add internal support for deprecated rule aliases.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#973](https://github.com/realm/SwiftLint/issues/973)

* Add `unused_optional_binding` rule that will check for optional bindings
  not being used.  
  [Rafael Machado](https://github.com/rakaramos)
  [#1116](https://github.com/realm/SwiftLint/issues/1116)

##### Bug Fixes

* Ignore close parentheses on `vertical_parameter_alignment` rule.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#1042](https://github.com/realm/SwiftLint/issues/1042)

* `syntactic_sugar` rule now doesn't flag declarations that can't be fixed.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#928](https://github.com/realm/SwiftLint/issues/928)

* Fix false positives on `closure_parameter_position` and
  `unused_closure_parameter` rules with Swift 2.3.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#1019](https://github.com/realm/SwiftLint/issues/1019)

* Fix crash on `trailing_comma` rule with Swift 2.3.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#921](https://github.com/realm/SwiftLint/issues/921)

* Fix out of range exception in `AttributesRule`.  
  [JP Simard](https://github.com/jpsim)
  [#1105](https://github.com/realm/SwiftLint/issues/1105)

* Fix `variable_name` and `type_name` rules on Linux.  
  [Marcelo Fabri](https://github.com/marcelofabri)

* Fix linting directories with names ending with `.swift`.  
  [JP Simard](https://github.com/jpsim)

* Fix running `swiftlint version` when building with Swift Package Manager.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#1045](https://github.com/realm/SwiftLint/issues/1045)

* Fix false positive on `vertical_parameter_alignment` rule when breaking line
  in a default parameter declaration.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#1129](https://github.com/realm/SwiftLint/issues/1129)

## 0.15.0: Hand Washable Holiday Linens 🎄

##### Breaking

* `line_length` rule now has a default value of `120` for warnings.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#1008](https://github.com/realm/SwiftLint/issues/1008)

##### Enhancements

* Add `closure_end_indentation` opt-in rule that validates closure closing
  braces according to these rules:
  * If the method call has chained breaking lines on each method
    (`.` is on a new line), the closing brace should be vertically aligned
    with the `.`.
  * Otherwise, the closing brace should be vertically aligned with
    the beginning of the statement in the first line.  

  [Marcelo Fabri](https://github.com/marcelofabri)
  [#326](https://github.com/realm/SwiftLint/issues/326)

* `operator_usage_whitespace` rule is now correctable.  
  [Marcelo Fabri](https://github.com/marcelofabri)

* `implicit_getter` and `mark` rule performance improvements.  
  [Marcelo Fabri](https://github.com/marcelofabri)

* HTML reports now display a relative path to files.  
  [Jamie Edge](https://github.com/JamieEdge)

* `colon` rule now validates colon position in dictionaries too. You can disable
  this new validation with the `apply_to_dictionaries` configuration.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#603](https://github.com/realm/SwiftLint/issues/603)

* Add `first_where` opt-in rule that warns against using
  `.filter { /* ... */ }.first` in collections, as
  `.first(where: { /* ... */ })` is often more efficient.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#1005](https://github.com/realm/SwiftLint/issues/1005)

##### Bug Fixes

* `FunctionParameterCountRule` also ignores generic initializers.  
  [Mauricio Hanika](https://github.com/mAu888)

* Grammar checks.  
  [Michael Helmbrecht](https://github.com/mrh-is)

* Fix the validity and styling of the HTML reporter.  
  [Jamie Edge](https://github.com/JamieEdge)

* Fix false positive in `empty_parentheses_with_trailing_closure` rule.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#1021](https://github.com/realm/SwiftLint/issues/1021)

* Fix false positive in `switch_case_on_newline` when switching
  over a selector.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#1020](https://github.com/realm/SwiftLint/issues/1020)

* Fix crash in `closure_parameter_position` rule.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#1026](https://github.com/realm/SwiftLint/issues/1026)

* Fix false positive in `operator_usage_whitespace` rule when
  using image literals.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#1028](https://github.com/realm/SwiftLint/issues/1028)

## 0.14.0: Super Awesome Retractable Drying Rack

##### Breaking

* SwiftLint now requires Xcode 8.x and Swift 3.x to build.
  APIs have not yet been adapted to conform to the Swift 3 API Design
  Guidelines but will shortly.  
  [JP Simard](https://github.com/jpsim)
  [Norio Nomura](https://github.com/norio-nomura)

##### Enhancements

* Now builds and passes most tests on Linux using the Swift Package Manager with
  Swift 3. This requires `libsourcekitdInProc.so` to be built and located in
  `/usr/lib`, or in another location specified by the `LINUX_SOURCEKIT_LIB_PATH`
  environment variable. A preconfigured Docker image is available on Docker Hub
  by the ID of `norionomura/sourcekit:302`.  
  [JP Simard](https://github.com/jpsim)
  [Norio Nomura](https://github.com/norio-nomura)
  [#732](https://github.com/realm/SwiftLint/issues/732)

* Add `dynamic_inline` rule to discourage combination of `@inline(__always)`
  and `dynamic` function attributes.  
  [Daniel Duan](https://github.com/dduan)

* Add `number_separator` opt-in rule that enforces that underscores are
  used as thousand separators in large numbers.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#924](https://github.com/realm/SwiftLint/issues/924)

* Add `file_header` opt-in rule that warns when a file contains a
  copyright comment header, such as the one Xcode adds by default.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#844](https://github.com/realm/SwiftLint/issues/844)

* `FunctionParameterCountRule` now ignores initializers.  
  [Denis Lebedev](https://github.com/garnett)
  [#544](https://github.com/realm/SwiftLint/issues/544)

* Add `EmojiReporter`: a human friendly reporter.  
  [Michał Kałużny](https://github.com/justMaku)

* Add `redundant_string_enum_value` rule that warns against String enums
  with redundant value assignments.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#946](https://github.com/realm/SwiftLint/issues/946)

* Add `attributes` opt-in rule which validates if an attribute (`@objc`,
  `@IBOutlet`, `@discardableResult`, etc) is in the right position:
    - If the attribute is `@IBAction` or `@NSManaged`, it should always be on
    the same line as the declaration
    - If the attribute has parameters, it should always be on the line above
    the declaration
    - Otherwise:
      - if the attribute is applied to a variable, it should be on the same line
      - if it's applied to a type or function, it should be on the line above
      - if it's applied to an import (the only option is `@testable import`),
      it should be on the same line.
  You can also configure what attributes should be always on a new line or on
  the same line as the declaration with the `always_on_same_line` and
  `always_on_line_above` keys.  

  [Marcelo Fabri](https://github.com/marcelofabri)
  [#846](https://github.com/realm/SwiftLint/issues/846)

* Add `empty_parentheses_with_trailing_closure` rule that checks for
  empty parentheses after method call when using trailing closures.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#885](https://github.com/realm/SwiftLint/issues/885)

* Add `closure_parameter_position` rule that validates that closure
  parameters are in the same line as the opening brace.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#931](https://github.com/realm/SwiftLint/issues/931)

* `type_name` rule now validates `typealias` and `associatedtype` too.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#49](https://github.com/realm/SwiftLint/issues/49)
  [#956](https://github.com/realm/SwiftLint/issues/956)

* Add `ProhibitedSuperRule` opt-in rule that warns about methods calling
  to super that should not, for example `UIViewController.loadView()`.  
  [Aaron McTavish](https://github.com/aamctustwo)
  [#970](https://github.com/realm/SwiftLint/issues/970)

* Add correctable `void_return` rule to validate usage of `-> Void`
  over `-> ()`.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [JP Simard](https://github.com/jpsim)
  [#964](https://github.com/realm/SwiftLint/issues/964)

* Add correctable `empty_parameters` rule to validate usage of `() -> `
  over `Void -> `.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#573](https://github.com/realm/SwiftLint/issues/573)

* Add `operator_usage_whitespace` opt-in rule to validate that operators are
  surrounded by a single whitespace when they are being used.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#626](https://github.com/realm/SwiftLint/issues/626)

* Add `unused_closure_parameter` correctable rule that validates if all closure
  parameters are being used. If a parameter is unused, it should be replaced by
  `_`.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [JP Simard](https://github.com/jpsim)
  [#982](https://github.com/realm/SwiftLint/issues/982)

* Add `unused_enumerated` rule that warns against unused indexes when using
  `.enumerated()` on a for loop, e.g. `for (_, foo) in bar.enumerated()`.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#619](https://github.com/realm/SwiftLint/issues/619)

##### Bug Fixes

* Fix `weak_delegate` rule reporting a violation for variables containing
  but not ending in `delegate`.  
  [Phil Webster](https://github.com/philwebster)

* Fix `weak_delegate` rule reporting a violation for variables in protocol
  declarations.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#934](https://github.com/realm/SwiftLint/issues/934)

* Fix `trailing_comma` rule reporting a violation for commas in comments.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#940](https://github.com/realm/SwiftLint/issues/940)

* Fix XML reporters not escaping characters.  
  [Fabian Ehrentraud](https://github.com/fabb)
  [#968](https://github.com/realm/SwiftLint/issues/968)

* Fix specifying multiple rule identifiers in comment commands.  
  [JP Simard](https://github.com/jpsim)
  [#976](https://github.com/realm/SwiftLint/issues/976)

* Fix invalid CSS in HTML reporter template.  
  [Aaron McTavish](https://github.com/aamctustwo)
  [#981](https://github.com/realm/SwiftLint/issues/981)

* Fix crash when correcting `statement_position` rule when there are
  multi-byte characters in the file.  
  [Marcelo Fabri](https://github.com/marcelofabri)

## 0.13.2: Light Cycle

##### Breaking

* None.

##### Enhancements

* `TrailingCommaRule` now only triggers when a declaration is multi-line
  when using `mandatory_comma: true`.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#910](https://github.com/realm/SwiftLint/issues/910)
  [#911](https://github.com/realm/SwiftLint/issues/911)

##### Bug Fixes

* Fix `MarkRule` reporting a violation for `// MARK: -`, which is valid.  
  [JP Simard](https://github.com/jpsim)
  [#778](https://github.com/realm/SwiftLint/issues/778)

## 0.13.1: Heavy Cycle

##### Breaking

* None.

##### Enhancements

* Add `ImplicitGetterRule` to warn against using `get` on computed read-only
  properties.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#57](https://github.com/realm/SwiftLint/issues/57)

* Add `WeakDelegateRule` rule to enforce delegate instance variables to be
  marked as `weak`.  
  [Olivier Halligon](https://github.com/AliSoftware)

* Add `SyntacticSugar` rule that enforces that shorthanded syntax should be
  used when possible, for example `[Int]` instead of `Array<Int>`.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#319](https://github.com/realm/SwiftLint/issues/319)

* Allow specifying multiple rule identifiers in comment commands. For example,
  `// swiftlint:disable:next force_cast force_try`. Works with all command types
  (`disable`/`enable`) and modifiers (`next`, `this`, `previous` or blank).  
  [JP Simard](https://github.com/jpsim)
  [#861](https://github.com/realm/SwiftLint/issues/861)

* Add `NimbleOperatorRule` opt-in rule that enforces using
  [operator overloads](https://github.com/Quick/Nimble/#operator-overloads)
  instead of free matcher functions when using
  [Nimble](https://github.com/Quick/Nimble).  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#881](https://github.com/realm/SwiftLint/issues/881)

* `closure_spacing` rule now accepts empty bodies with a space.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#875](https://github.com/realm/SwiftLint/issues/875)

* Add `TrailingCommaRule` to enforce/forbid trailing commas in arrays and
  dictionaries. The default is to forbid them, but this can be changed with
  the `mandatory_comma` configuration.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#883](https://github.com/realm/SwiftLint/issues/883)

* Add support for `fileprivate` in `PrivateOutletRule` and
  `PrivateUnitTestRule`.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#781](https://github.com/realm/SwiftLint/issues/781)
  [#831](https://github.com/realm/SwiftLint/issues/831)

* Make `MarkRule` correctable.  
  [kohtenko](https://github.com/kohtenko)

##### Bug Fixes

* Rule out a few invalid `@IBInspectable` cases in `valid_ibinspectable`.  
  [Daniel Duan](https://github.com/dduan)

* Fix a few edge cases where malformed `MARK:` comments wouldn't trigger a
  violation.  
  [JP Simard](https://github.com/jpsim)
  [#805](https://github.com/realm/SwiftLint/issues/805)

* Now lints single files passed to `--path` even if this file is excluded
  from the configuration file (`.swiftlint.yml`).  
  [JP Simard](https://github.com/jpsim)

* Fixed error severity configuration in `colon` rule.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#863](https://github.com/realm/SwiftLint/issues/863)

* `switch_case_on_newline` rule should ignore trailing comments.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#874](https://github.com/realm/SwiftLint/issues/874)

* `switch_case_on_newline` rule shouldn't trigger on enums.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#878](https://github.com/realm/SwiftLint/issues/878)

* Fix regex bug in Comma Rule causing some violations to not be triggered
  when there were consecutive violations in the same expression.  
  [Savio Figueiredo](https://github.com/sadefigu)
  [#872](https://github.com/realm/SwiftLint/issues/872)

## 0.13.0: MakeYourClothesCleanAgain

##### Breaking

* None.

##### Enhancements

* Add `ignores_comment` configuration for `trailing_whitespace` rule.  
  [Javier Hernández](https://github.com/jaherhi)
  [#576](https://github.com/realm/SwiftLint/issues/576)

* Added HTML reporter, identifier is `html`.  
  [Johnykutty Mathew](https://github.com/Johnykutty)

* Add `SuperCallRule` opt-in rule that warns about methods not calling to super.  
  [Angel G. Olloqui](https://github.com/angelolloqui)
  [#803](https://github.com/realm/SwiftLint/issues/803)

* Add `RedundantNilCoalesingRule` opt-in rule that warns against `?? nil`.  
  [Daniel Beard](https://github.com/daniel-beard)
  [#764](https://github.com/realm/SwiftLint/issues/764)

* Added opt-in rule to makes closure expressions spacing consistent.  
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

* Add `SwitchCaseOnNewlineRule` opt-in rule that enforces a newline after
  `case pattern:` in a `switch`.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#681](https://github.com/realm/SwiftLint/issues/681)

* Add `ValidIBInspectableRule` rule that checks if `@IBInspectable` declarations
  are valid. An `@IBInspectable` is valid if:
  * It's declared as a `var` (not `let`)
  * Its type is explicit (not inferred)
  * Its type is one of the
  [supported types](http://help.apple.com/xcode/mac/8.0/#/devf60c1c514)  

  [Marcelo Fabri](https://github.com/marcelofabri)
  [#756](https://github.com/realm/SwiftLint/issues/756)

* Add `ExplicitInitRule` opt-in rule to discourage calling `init` directly.  
  [Matt Taube](https://github.com/mtaube)
  [#715](https://github.com/realm/SwiftLint/pull/715)

##### Bug Fixes

* Fixed whitespace being added to TODO messages.  
  [W. Bagdon](https://github.com/wbagdon)
  [#792](https://github.com/realm/SwiftLint/issues/792)

* Fixed regex bug in Vertical Whitespace Rule by using SourceKitten instead.
  The rule now enabled by default again (no longer opt-in).  
  [J. Cheyo Jimenez](https://github.com/masters3d)
  [#772](https://github.com/realm/SwiftLint/issues/772)

* Correctable rules no longer apply corrections if the rule is locally disabled.  
  [J. Cheyo Jimenez](https://github.com/masters3d)  
  [#601](https://github.com/realm/SwiftLint/issues/601)

* Fixed regex bug in Mark Rule where MARK could not be used with only a hyphen
  but no descriptive text: `// MARK: -`.  
  [Ruotger Deecke](https://github.com/roddi)
  [#778](https://github.com/realm/SwiftLint/issues/778)

* Fixed: Private unit test rule not scoped to test classes.  
  Fixed: Private unit test rule config is ignored if regex is missing.  
  [Cristian Filipov](https://github.com/cfilipov)
  [#786](https://github.com/realm/SwiftLint/issues/786)

* Fixed: `ConditionalReturnsOnNewline` now respects severity configuration.  
  [Rohan Dhaimade](https://github.com/HaloZero)
  [#783](https://github.com/realm/SwiftLint/issues/783)

* Fixed: `ConditionalReturnsOnNewline` now checks if `return` is a keyword,
  avoiding false positives.  
  [Marcelo Fabri](https://github.com/marcelofabri)
  [#784](https://github.com/realm/SwiftLint/issues/784)

* `ForceUnwrappingRule` did not recognize force unwraps in return statements
  using subscript.  
  [Norio Nomura](https://github.com/norio-nomura)
  [#813](https://github.com/realm/SwiftLint/issues/813)

## 0.12.0: Vertical Laundry

##### Breaking

* Fixed: SwiftLint assumes paths in the YAML config file are relative to the
  current directory even when `--path` is passed as an argument.  
  [Cristian Filipov](https://github.com/cfilipov)

##### Enhancements

* Add `--enable-all-rules` CLI option to `lint` command to facilitate running
  all rules, even opt-in and disabled ones, ignoring `whitelist_rules`.  
  [JP Simard](https://github.com/jpsim)
  [#1170](https://github.com/realm/SwiftLint/issues/1170)

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

* Add `PrivateOutletRule` opt-in rule to enforce `@IBOutlet`
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
