
# Rules

* [AnyObject Protocol](#anyobject-protocol)
* [Array Init](#array-init)
* [Attributes](#attributes)
* [Block Based KVO](#block-based-kvo)
* [Class Delegate Protocol](#class-delegate-protocol)
* [Closing Brace Spacing](#closing-brace-spacing)
* [Closure Body Length](#closure-body-length)
* [Closure End Indentation](#closure-end-indentation)
* [Closure Parameter Position](#closure-parameter-position)
* [Closure Spacing](#closure-spacing)
* [Collection Element Alignment](#collection-element-alignment)
* [Colon](#colon)
* [Comma Spacing](#comma-spacing)
* [Compiler Protocol Init](#compiler-protocol-init)
* [Conditional Returns on Newline](#conditional-returns-on-newline)
* [Contains over first not nil](#contains-over-first-not-nil)
* [Control Statement](#control-statement)
* [Convenience Type](#convenience-type)
* [Custom Rules](#custom-rules)
* [Cyclomatic Complexity](#cyclomatic-complexity)
* [Deployment Target](#deployment-target)
* [Discarded Notification Center Observer](#discarded-notification-center-observer)
* [Discouraged Direct Initialization](#discouraged-direct-initialization)
* [Discouraged Object Literal](#discouraged-object-literal)
* [Discouraged Optional Boolean](#discouraged-optional-boolean)
* [Discouraged Optional Collection](#discouraged-optional-collection)
* [Duplicate Enum Cases](#duplicate-enum-cases)
* [Duplicate Imports](#duplicate-imports)
* [Dynamic Inline](#dynamic-inline)
* [Empty Count](#empty-count)
* [Empty Enum Arguments](#empty-enum-arguments)
* [Empty Parameters](#empty-parameters)
* [Empty Parentheses with Trailing Closure](#empty-parentheses-with-trailing-closure)
* [Empty String](#empty-string)
* [Empty XCTest Method](#empty-xctest-method)
* [Explicit ACL](#explicit-acl)
* [Explicit Enum Raw Value](#explicit-enum-raw-value)
* [Explicit Init](#explicit-init)
* [Explicit Self](#explicit-self)
* [Explicit Top Level ACL](#explicit-top-level-acl)
* [Explicit Type Interface](#explicit-type-interface)
* [Extension Access Modifier](#extension-access-modifier)
* [Fallthrough](#fallthrough)
* [Fatal Error Message](#fatal-error-message)
* [File Header](#file-header)
* [File Line Length](#file-line-length)
* [File Name](#file-name)
* [File Types Order](#file-types-order)
* [First Where](#first-where)
* [For Where](#for-where)
* [Force Cast](#force-cast)
* [Force Try](#force-try)
* [Force Unwrapping](#force-unwrapping)
* [Function Body Length](#function-body-length)
* [Function Default Parameter at End](#function-default-parameter-at-end)
* [Function Parameter Count](#function-parameter-count)
* [Generic Type Name](#generic-type-name)
* [Identical Operands](#identical-operands)
* [Identifier Name](#identifier-name)
* [Implicit Getter](#implicit-getter)
* [Implicit Return](#implicit-return)
* [Implicitly Unwrapped Optional](#implicitly-unwrapped-optional)
* [Inert Defer](#inert-defer)
* [Is Disjoint](#is-disjoint)
* [Joined Default Parameter](#joined-default-parameter)
* [Large Tuple](#large-tuple)
* [Last Where](#last-where)
* [Leading Whitespace](#leading-whitespace)
* [Legacy CGGeometry Functions](#legacy-cggeometry-functions)
* [Legacy Constant](#legacy-constant)
* [Legacy Constructor](#legacy-constructor)
* [Legacy Hashing](#legacy-hashing)
* [Legacy Multiple](#legacy-multiple)
* [Legacy NSGeometry Functions](#legacy-nsgeometry-functions)
* [Legacy Random](#legacy-random)
* [Variable Declaration Whitespace](#variable-declaration-whitespace)
* [Line Length](#line-length)
* [Literal Expression End Indentation](#literal-expression-end-indentation)
* [Lower ACL than parent](#lower-acl-than-parent)
* [Mark](#mark)
* [Missing Docs](#missing-docs)
* [Modifier Order](#modifier-order)
* [Multiline Arguments](#multiline-arguments)
* [Multiline Arguments Brackets](#multiline-arguments-brackets)
* [Multiline Function Chains](#multiline-function-chains)
* [Multiline Literal Brackets](#multiline-literal-brackets)
* [Multiline Parameters](#multiline-parameters)
* [Multiline Parameters Brackets](#multiline-parameters-brackets)
* [Multiple Closures with Trailing Closure](#multiple-closures-with-trailing-closure)
* [Nesting](#nesting)
* [Nimble Operator](#nimble-operator)
* [No Extension Access Modifier](#no-extension-access-modifier)
* [No Fallthrough Only](#no-fallthrough-only)
* [No Grouping Extension](#no-grouping-extension)
* [Notification Center Detachment](#notification-center-detachment)
* [NSLocalizedString Key](#nslocalizedstring-key)
* [NSLocalizedString Require Bundle](#nslocalizedstring-require-bundle)
* [NSObject Prefer isEqual](#nsobject-prefer-isequal)
* [Number Separator](#number-separator)
* [Object Literal](#object-literal)
* [Opening Brace Spacing](#opening-brace-spacing)
* [Operator Usage Whitespace](#operator-usage-whitespace)
* [Operator Function Whitespace](#operator-function-whitespace)
* [Overridden methods call super](#overridden-methods-call-super)
* [Override in Extension](#override-in-extension)
* [Pattern Matching Keywords](#pattern-matching-keywords)
* [Prefixed Top-Level Constant](#prefixed-top-level-constant)
* [Private Actions](#private-actions)
* [Private Outlets](#private-outlets)
* [Private over fileprivate](#private-over-fileprivate)
* [Private Unit Test](#private-unit-test)
* [Prohibited Interface Builder](#prohibited-interface-builder)
* [Prohibited calls to super](#prohibited-calls-to-super)
* [Protocol Property Accessors Order](#protocol-property-accessors-order)
* [Quick Discouraged Call](#quick-discouraged-call)
* [Quick Discouraged Focused Test](#quick-discouraged-focused-test)
* [Quick Discouraged Pending Test](#quick-discouraged-pending-test)
* [Reduce Boolean](#reduce-boolean)
* [Reduce Into](#reduce-into)
* [Redundant Discardable Let](#redundant-discardable-let)
* [Redundant Nil Coalescing](#redundant-nil-coalescing)
* [Redundant @objc Attribute](#redundant-objc-attribute)
* [Redundant Optional Initialization](#redundant-optional-initialization)
* [Redundant Set Access Control Rule](#redundant-set-access-control-rule)
* [Redundant String Enum Value](#redundant-string-enum-value)
* [Redundant Type Annotation](#redundant-type-annotation)
* [Redundant Void Return](#redundant-void-return)
* [Required Deinit](#required-deinit)
* [Required Enum Case](#required-enum-case)
* [Returning Whitespace](#returning-whitespace)
* [Shorthand Operator](#shorthand-operator)
* [Single Test Class](#single-test-class)
* [Min or Max over Sorted First or Last](#min-or-max-over-sorted-first-or-last)
* [Sorted Imports](#sorted-imports)
* [Statement Position](#statement-position)
* [Static Operator](#static-operator)
* [Strict fileprivate](#strict-fileprivate)
* [Strong IBOutlet](#strong-iboutlet)
* [Superfluous Disable Command](#superfluous-disable-command)
* [Switch and Case Statement Alignment](#switch-and-case-statement-alignment)
* [Switch Case on Newline](#switch-case-on-newline)
* [Syntactic Sugar](#syntactic-sugar)
* [Todo](#todo)
* [Toggle Bool](#toggle-bool)
* [Trailing Closure](#trailing-closure)
* [Trailing Comma](#trailing-comma)
* [Trailing Newline](#trailing-newline)
* [Trailing Semicolon](#trailing-semicolon)
* [Trailing Whitespace](#trailing-whitespace)
* [Type Body Length](#type-body-length)
* [Type Contents Order](#type-contents-order)
* [Type Name](#type-name)
* [Unavailable Function](#unavailable-function)
* [Unneeded Break in Switch](#unneeded-break-in-switch)
* [Unneeded Parentheses in Closure Argument](#unneeded-parentheses-in-closure-argument)
* [Unowned Variable Capture](#unowned-variable-capture)
* [Untyped Error in Catch](#untyped-error-in-catch)
* [Unused Capture List](#unused-capture-list)
* [Unused Closure Parameter](#unused-closure-parameter)
* [Unused Control Flow Label](#unused-control-flow-label)
* [Unused Declaration](#unused-declaration)
* [Unused Enumerated](#unused-enumerated)
* [Unused Import](#unused-import)
* [Unused Optional Binding](#unused-optional-binding)
* [Unused Setter Value](#unused-setter-value)
* [Valid IBInspectable](#valid-ibinspectable)
* [Vertical Parameter Alignment](#vertical-parameter-alignment)
* [Vertical Parameter Alignment On Call](#vertical-parameter-alignment-on-call)
* [Vertical Whitespace](#vertical-whitespace)
* [Vertical Whitespace Between Cases](#vertical-whitespace-between-cases)
* [Vertical Whitespace before Closing Braces](#vertical-whitespace-before-closing-braces)
* [Vertical Whitespace after Opening Braces](#vertical-whitespace-after-opening-braces)
* [Void Return](#void-return)
* [Weak Delegate](#weak-delegate)
* [XCTest Specific Matcher](#xctest-specific-matcher)
* [XCTFail Message](#xctfail-message)
* [Yoda condition rule](#yoda-condition-rule)
--------

## AnyObject Protocol

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`anyobject_protocol` | Disabled | Yes | lint | No | 4.1.0 

Prefer using `AnyObject` over `class` for class-only protocols.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
protocol SomeProtocol {}

```

```swift
protocol SomeClassOnlyProtocol: AnyObject {}

```

```swift
protocol SomeClassOnlyProtocol: AnyObject, SomeInheritedProtocol {}

```

```swift
@objc protocol SomeClassOnlyProtocol: AnyObject, SomeInheritedProtocol {}

```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
protocol SomeClassOnlyProtocol: ↓class {}

```

```swift
protocol SomeClassOnlyProtocol: ↓class, SomeInheritedProtocol {}

```

```swift
@objc protocol SomeClassOnlyProtocol: ↓class, SomeInheritedProtocol {}

```

</details>



## Array Init

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`array_init` | Disabled | No | lint | No | 3.0.0 

Prefer using `Array(seq)` over `seq.map { $0 }` to convert a sequence into an Array.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
Array(foo)

```

```swift
foo.map { $0.0 }

```

```swift
foo.map { $1 }

```

```swift
foo.map { $0() }

```

```swift
foo.map { ((), $0) }

```

```swift
foo.map { $0! }

```

```swift
foo.map { $0! /* force unwrap */ }

```

```swift
foo.something { RouteMapper.map($0) }

```

```swift
foo.map { !$0 }

```

```swift
foo.map { /* a comment */ !$0 }

```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
↓foo.map({ $0 })

```

```swift
↓foo.map { $0 }

```

```swift
↓foo.map { return $0 }

```

```swift
↓foo.map { elem in
   elem
}

```

```swift
↓foo.map { elem in
   return elem
}

```

```swift
↓foo.map { (elem: String) in
   elem
}

```

```swift
↓foo.map { elem -> String in
   elem
}

```

```swift
↓foo.map { $0 /* a comment */ }

```

```swift
↓foo.map { /* a comment */ $0 }

```

</details>



## Attributes

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`attributes` | Disabled | No | style | No | 3.0.0 

Attributes should be on their own lines in functions and types, but on the same line as variables and imports.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
@objc var x: String
```

```swift
@objc private var x: String
```

```swift
@nonobjc var x: String
```

```swift
@IBOutlet private var label: UILabel
```

```swift
@IBOutlet @objc private var label: UILabel
```

```swift
@NSCopying var name: NSString
```

```swift
@NSManaged var name: String?
```

```swift
@IBInspectable var cornerRadius: CGFloat
```

```swift
@available(iOS 9.0, *)
 let stackView: UIStackView
```

```swift
@NSManaged func addSomeObject(book: SomeObject)
```

```swift
@IBAction func buttonPressed(button: UIButton)
```

```swift
@objc
 @IBAction func buttonPressed(button: UIButton)
```

```swift
@available(iOS 9.0, *)
 func animate(view: UIStackView)
```

```swift
@available(iOS 9.0, *, message="A message")
 func animate(view: UIStackView)
```

```swift
@nonobjc
 final class X
```

```swift
@available(iOS 9.0, *)
 class UIStackView
```

```swift
@NSApplicationMain
 class AppDelegate: NSObject, NSApplicationDelegate
```

```swift
@UIApplicationMain
 class AppDelegate: NSObject, UIApplicationDelegate
```

```swift
@IBDesignable
 class MyCustomView: UIView
```

```swift
@testable import SourceKittenFramework
```

```swift
@objc(foo_x)
 var x: String
```

```swift
@available(iOS 9.0, *)
@objc(abc_stackView)
 let stackView: UIStackView
```

```swift
@objc(abc_addSomeObject:)
 @NSManaged func addSomeObject(book: SomeObject)
```

```swift
@objc(ABCThing)
 @available(iOS 9.0, *)
 class Thing
```

```swift
class Foo: NSObject {
 override var description: String { return "" }
}
```

```swift
class Foo: NSObject {

 override func setUp() {}
}
```

```swift
@objc
class ⽺ {}

```

```swift
extension Property {

 @available(*, unavailable, renamed: "isOptional")
public var optional: Bool { fatalError() }
}
```

```swift
@GKInspectable var maxSpeed: Float
```

```swift
@discardableResult
 func a() -> Int
```

```swift
@objc
 @discardableResult
 func a() -> Int
```

```swift
func increase(f: @autoclosure () -> Int) -> Int
```

```swift
func foo(completionHandler: @escaping () -> Void)
```

```swift
private struct DefaultError: Error {}
```

```swift
@testable import foo

private let bar = 1
```

```swift
import XCTest
@testable import DeleteMe

@available (iOS 11.0, *)
class DeleteMeTests: XCTestCase {
}
```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
@objc
 ↓var x: String
```

```swift
@objc

 ↓var x: String
```

```swift
@objc
 private ↓var x: String
```

```swift
@nonobjc
 ↓var x: String
```

```swift
@IBOutlet
 private ↓var label: UILabel
```

```swift
@IBOutlet

 private ↓var label: UILabel
```

```swift
@NSCopying
 ↓var name: NSString
```

```swift
@NSManaged
 ↓var name: String?
```

```swift
@IBInspectable
 ↓var cornerRadius: CGFloat
```

```swift
@available(iOS 9.0, *) ↓let stackView: UIStackView
```

```swift
@NSManaged
 ↓func addSomeObject(book: SomeObject)
```

```swift
@IBAction
 ↓func buttonPressed(button: UIButton)
```

```swift
@IBAction
 @objc
 ↓func buttonPressed(button: UIButton)
```

```swift
@available(iOS 9.0, *) ↓func animate(view: UIStackView)
```

```swift
@nonobjc final ↓class X
```

```swift
@available(iOS 9.0, *) ↓class UIStackView
```

```swift
@available(iOS 9.0, *)
 @objc ↓class UIStackView
```

```swift
@available(iOS 9.0, *) @objc
 ↓class UIStackView
```

```swift
@available(iOS 9.0, *)

 ↓class UIStackView
```

```swift
@UIApplicationMain ↓class AppDelegate: NSObject, UIApplicationDelegate
```

```swift
@IBDesignable ↓class MyCustomView: UIView
```

```swift
@testable
↓import SourceKittenFramework
```

```swift
@testable


↓import SourceKittenFramework
```

```swift
@objc(foo_x) ↓var x: String
```

```swift
@available(iOS 9.0, *) @objc(abc_stackView)
 ↓let stackView: UIStackView
```

```swift
@objc(abc_addSomeObject:) @NSManaged
 ↓func addSomeObject(book: SomeObject)
```

```swift
@objc(abc_addSomeObject:)
 @NSManaged
 ↓func addSomeObject(book: SomeObject)
```

```swift
@available(iOS 9.0, *)
 @objc(ABCThing) ↓class Thing
```

```swift
@GKInspectable
 ↓var maxSpeed: Float
```

```swift
@discardableResult ↓func a() -> Int
```

```swift
@objc
 @discardableResult ↓func a() -> Int
```

```swift
@objc

 @discardableResult
 ↓func a() -> Int
```

</details>



## Block Based KVO

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`block_based_kvo` | Enabled | No | idiomatic | No | 3.0.0 

Prefer the new block based KVO API with keypaths when using Swift 3.2 or later.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
let observer = foo.observe(\.value, options: [.new]) { (foo, change) in
   print(change.newValue)
}
```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
class Foo: NSObject {
  override ↓func observeValue(forKeyPath keyPath: String?, of object: Any?,
                              change: [NSKeyValueChangeKey : Any]?,
                              context: UnsafeMutableRawPointer?) {}
}
```

```swift
class Foo: NSObject {
  override ↓func observeValue(forKeyPath keyPath: String?, of object: Any?,
                              change: Dictionary<NSKeyValueChangeKey, Any>?,
                              context: UnsafeMutableRawPointer?) {}
}
```

</details>



## Class Delegate Protocol

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`class_delegate_protocol` | Enabled | No | lint | No | 3.0.0 

Delegate protocols should be class-only so they can be weakly referenced.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
protocol FooDelegate: class {}

```

```swift
protocol FooDelegate: class, BarDelegate {}

```

```swift
protocol Foo {}

```

```swift
class FooDelegate {}

```

```swift
@objc protocol FooDelegate {}

```

```swift
@objc(MyFooDelegate)
 protocol FooDelegate {}

```

```swift
protocol FooDelegate: BarDelegate {}

```

```swift
protocol FooDelegate: AnyObject {}

```

```swift
protocol FooDelegate: NSObjectProtocol {}

```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
↓protocol FooDelegate {}

```

```swift
↓protocol FooDelegate: Bar {}

```

</details>



## Closing Brace Spacing

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`closing_brace` | Enabled | Yes | style | No | 3.0.0 

Closing brace with closing parenthesis should not have any whitespaces in the middle.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
[].map({ })
```

```swift
[].map(
  { }
)
```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
[].map({ ↓} )
```

```swift
[].map({ ↓}	)
```

</details>



## Closure Body Length

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`closure_body_length` | Disabled | No | metrics | No | 4.2.0 

Closure bodies should not span too many lines.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
foo.bar { $0 }
```

```swift
foo.bar { toto in
}
```

```swift
foo.bar { toto in
	let a = 0
	// toto
	// toto
	// toto
	// toto
	// toto
	// toto
	// toto
	// toto
	// toto
	// toto
	
	
	
	
	
	
	
	
	
	
}
```

```swift
foo.bar { toto in
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
}
```

```swift
foo.bar { toto in
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	// toto
	// toto
	// toto
	// toto
	// toto
	// toto
	// toto
	// toto
	// toto
	// toto
	
	
	
	
	
	
	
	
	
	
}
```

```swift
foo.bar({ toto in
})
```

```swift
foo.bar({ toto in
	let a = 0
})
```

```swift
foo.bar({ toto in
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
})
```

```swift
foo.bar(label: { toto in
})
```

```swift
foo.bar(label: { toto in
	let a = 0
})
```

```swift
foo.bar(label: { toto in
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
})
```

```swift
foo.bar(label: { toto in
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
}, anotherLabel: { toto in
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
})
```

```swift
foo.bar(label: { toto in
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
}) { toto in
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
}
```

```swift
let foo: Bar = { toto in
	let bar = Bar()
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	return bar
}()
```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
foo.bar ↓{ toto in
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
}
```

```swift
foo.bar ↓{ toto in
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	// toto
	// toto
	// toto
	// toto
	// toto
	// toto
	// toto
	// toto
	// toto
	// toto
	
	
	
	
	
	
	
	
	
	
}
```

```swift
foo.bar(↓{ toto in
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
})
```

```swift
foo.bar(label: ↓{ toto in
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
})
```

```swift
foo.bar(label: ↓{ toto in
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
}, anotherLabel: ↓{ toto in
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
})
```

```swift
foo.bar(label: ↓{ toto in
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
}) ↓{ toto in
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
}
```

```swift
let foo: Bar = ↓{ toto in
	let bar = Bar()
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	let a = 0
	return bar
}()
```

</details>



## Closure End Indentation

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`closure_end_indentation` | Disabled | Yes | style | No | 3.0.0 

Closure end should have the same indentation as the line that started it.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
SignalProducer(values: [1, 2, 3])
   .startWithNext { number in
       print(number)
   }

```

```swift
[1, 2].map { $0 + 1 }

```

```swift
return match(pattern: pattern, with: [.comment]).flatMap { range in
   return Command(string: contents, range: range)
}.flatMap { command in
   return command.expand()
}

```

```swift
foo(foo: bar,
    options: baz) { _ in }

```

```swift
someReallyLongProperty.chainingWithAnotherProperty
   .foo { _ in }
```

```swift
foo(abc, 123)
{ _ in }

```

```swift
function(
    closure: { x in
        print(x)
    },
    anotherClosure: { y in
        print(y)
    })
```

```swift
function(parameter: param,
         closure: { x in
    print(x)
})
```

```swift
function(parameter: param, closure: { x in
        print(x)
    },
    anotherClosure: { y in
        print(y)
    })
```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
SignalProducer(values: [1, 2, 3])
   .startWithNext { number in
       print(number)
↓}

```

```swift
return match(pattern: pattern, with: [.comment]).flatMap { range in
   return Command(string: contents, range: range)
   ↓}.flatMap { command in
   return command.expand()
↓}

```

```swift
function(
    closure: { x in
        print(x)
↓},
    anotherClosure: { y in
        print(y)
↓})
```

</details>



## Closure Parameter Position

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`closure_parameter_position` | Enabled | No | style | No | 3.0.0 

Closure parameters should be on the same line as opening brace.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
[1, 2].map { $0 + 1 }

```

```swift
[1, 2].map({ $0 + 1 })

```

```swift
[1, 2].map { number in
 number + 1 
}

```

```swift
[1, 2].map { number -> Int in
 number + 1 
}

```

```swift
[1, 2].map { (number: Int) -> Int in
 number + 1 
}

```

```swift
[1, 2].map { [weak self] number in
 number + 1 
}

```

```swift
[1, 2].something(closure: { number in
 number + 1 
})

```

```swift
let isEmpty = [1, 2].isEmpty()

```

```swift
rlmConfiguration.migrationBlock.map { rlmMigration in
return { migration, schemaVersion in
rlmMigration(migration.rlmMigration, schemaVersion)
}
}
```

```swift
let mediaView: UIView = { [weak self] index in
   return UIView()
}(index)

```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
[1, 2].map {
 ↓number in
 number + 1 
}

```

```swift
[1, 2].map {
 ↓number -> Int in
 number + 1 
}

```

```swift
[1, 2].map {
 (↓number: Int) -> Int in
 number + 1 
}

```

```swift
[1, 2].map {
 [weak self] ↓number in
 number + 1 
}

```

```swift
[1, 2].map { [weak self]
 ↓number in
 number + 1 
}

```

```swift
[1, 2].map({
 ↓number in
 number + 1 
})

```

```swift
[1, 2].something(closure: {
 ↓number in
 number + 1 
})

```

```swift
[1, 2].reduce(0) {
 ↓sum, ↓number in
 number + sum 
}

```

</details>



## Closure Spacing

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`closure_spacing` | Disabled | Yes | style | No | 3.0.0 

Closure expressions should have a single space inside each brace.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
[].map ({ $0.description })
```

```swift
[].filter { $0.contains(location) }
```

```swift
extension UITableViewCell: ReusableView { }
```

```swift
extension UITableViewCell: ReusableView {}
```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
[].filter(↓{$0.contains(location)})
```

```swift
[].map(↓{$0})
```

```swift
(↓{each in return result.contains(where: ↓{e in return e}) }).count
```

```swift
filter ↓{ sorted ↓{ $0 < $1}}
```

</details>



## Collection Element Alignment

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`collection_alignment` | Disabled | No | style | No | 3.0.0 

All elements in a collection literal should be vertically aligned

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
doThings(arg: [
    "foo": 1,
    "bar": 2,
    "fizz": 2,
    "buzz": 2
])
```

```swift
let abc = [
    "alpha": "a",
    "beta": "b",
    "gamma": "g",
    "delta": "d",
    "epsilon": "e"
]
```

```swift
let meals = [
                "breakfast": "oatmeal",
                "lunch": "sandwich",
                "dinner": "burger"
]
```

```swift
let coordinates = [
    CLLocationCoordinate2D(latitude: 0, longitude: 33),
    CLLocationCoordinate2D(latitude: 0, longitude: 66),
    CLLocationCoordinate2D(latitude: 0, longitude: 99)
]
```

```swift
var evenNumbers: Set<Int> = [
    2,
    4,
    6
]
```

```swift
let abc = [1, 2, 3, 4]
```

```swift
let abc = [
    1, 2, 3, 4
]
```

```swift
let abc = [
    "foo": "bar", "fizz": "buzz"
]
```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
doThings(arg: [
    "foo": 1,
    "bar": 2,
   ↓"fizz": 2,
   ↓"buzz": 2
])
```

```swift
let abc = [
    "alpha": "a",
     ↓"beta": "b",
    "gamma": "g",
    "delta": "d",
  ↓"epsilon": "e"
]
```

```swift
let meals = [
                "breakfast": "oatmeal",
                "lunch": "sandwich",
    ↓"dinner": "burger"
]
```

```swift
let coordinates = [
    CLLocationCoordinate2D(latitude: 0, longitude: 33),
        ↓CLLocationCoordinate2D(latitude: 0, longitude: 66),
    CLLocationCoordinate2D(latitude: 0, longitude: 99)
]
```

```swift
var evenNumbers: Set<Int> = [
    2,
  ↓4,
    6
]
```

</details>



## Colon

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`colon` | Enabled | Yes | style | No | 3.0.0 

Colons should be next to the identifier when specifying a type and next to the key in dictionary literals.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
let abc: Void

```

```swift
let abc: [Void: Void]

```

```swift
let abc: (Void, Void)

```

```swift
let abc: ([Void], String, Int)

```

```swift
let abc: [([Void], String, Int)]

```

```swift
let abc: String="def"

```

```swift
let abc: Int=0

```

```swift
let abc: Enum=Enum.Value

```

```swift
func abc(def: Void) {}

```

```swift
func abc(def: Void, ghi: Void) {}

```

```swift
let abc: String = "abc:"
```

```swift
let abc = [Void: Void]()

```

```swift
let abc = [1: [3: 2], 3: 4]

```

```swift
let abc = ["string": "string"]

```

```swift
let abc = ["string:string": "string"]

```

```swift
let abc: [String: Int]

```

```swift
func foo(bar: [String: Int]) {}

```

```swift
func foo() -> [String: Int] { return [:] }

```

```swift
let abc: Any

```

```swift
let abc: [Any: Int]

```

```swift
let abc: [String: Any]

```

```swift
class Foo: Bar {}

```

```swift
class Foo<T>: Bar {}

```

```swift
class Foo<T: Equatable>: Bar {}

```

```swift
class Foo<T, U>: Bar {}

```

```swift
class Foo<T: Equatable> {}

```

```swift
switch foo {
case .bar:
    _ = something()
}

```

```swift
object.method(x: 5, y: "string")

```

```swift
object.method(x: 5, y:
              "string")
```

```swift
object.method(5, y: "string")

```

```swift
func abc() { def(ghi: jkl) }
```

```swift
func abc(def: Void) { ghi(jkl: mno) }
```

```swift
class ABC { let def = ghi(jkl: mno) } }
```

```swift
func foo() { let dict = [1: 1] }
```

```swift
let aaa = Self.bbb ? Self.ccc : Self.ddd else {
return nil
}

```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
let ↓abc:Void

```

```swift
let ↓abc:  Void

```

```swift
let ↓abc :Void

```

```swift
let ↓abc : Void

```

```swift
let ↓abc : [Void: Void]

```

```swift
let ↓abc : (Void, String, Int)

```

```swift
let ↓abc : ([Void], String, Int)

```

```swift
let ↓abc : [([Void], String, Int)]

```

```swift
let ↓abc:  (Void, String, Int)

```

```swift
let ↓abc:  ([Void], String, Int)

```

```swift
let ↓abc:  [([Void], String, Int)]

```

```swift
let ↓abc :String="def"

```

```swift
let ↓abc :Int=0

```

```swift
let ↓abc :Int = 0

```

```swift
let ↓abc:Int=0

```

```swift
let ↓abc:Int = 0

```

```swift
let ↓abc:Enum=Enum.Value

```

```swift
func abc(↓def:Void) {}

```

```swift
func abc(↓def:  Void) {}

```

```swift
func abc(↓def :Void) {}

```

```swift
func abc(↓def : Void) {}

```

```swift
func abc(def: Void, ↓ghi :Void) {}

```

```swift
let abc = [Void↓:Void]()

```

```swift
let abc = [Void↓ : Void]()

```

```swift
let abc = [Void↓:  Void]()

```

```swift
let abc = [Void↓ :  Void]()

```

```swift
let abc = [1: [3↓ : 2], 3: 4]

```

```swift
let abc = [1: [3↓ : 2], 3↓:  4]

```

```swift
let abc: [↓String : Int]

```

```swift
let abc: [↓String:Int]

```

```swift
func foo(bar: [↓String : Int]) {}

```

```swift
func foo(bar: [↓String:Int]) {}

```

```swift
func foo() -> [↓String : Int] { return [:] }

```

```swift
func foo() -> [↓String:Int] { return [:] }

```

```swift
let ↓abc : Any

```

```swift
let abc: [↓Any : Int]

```

```swift
let abc: [↓String : Any]

```

```swift
class ↓Foo : Bar {}

```

```swift
class ↓Foo:Bar {}

```

```swift
class ↓Foo<T> : Bar {}

```

```swift
class ↓Foo<T>:Bar {}

```

```swift
class ↓Foo<T, U>:Bar {}

```

```swift
class ↓Foo<T: Equatable>:Bar {}

```

```swift
class Foo<↓T:Equatable> {}

```

```swift
class Foo<↓T : Equatable> {}

```

```swift
object.method(x: 5, y↓ : "string")

```

```swift
object.method(x↓:5, y: "string")

```

```swift
object.method(x↓:  5, y: "string")

```

```swift
func abc() { def(ghi↓:jkl) }
```

```swift
func abc(def: Void) { ghi(jkl↓:mno) }
```

```swift
class ABC { let def = ghi(jkl↓:mno) } }
```

```swift
func foo() { let dict = [1↓ : 1] }
```

</details>



## Comma Spacing

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`comma` | Enabled | Yes | style | No | 3.0.0 

There should be no space before and one after any comma.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
func abc(a: String, b: String) { }
```

```swift
abc(a: "string", b: "string"
```

```swift
enum a { case a, b, c }
```

```swift
func abc(
  a: String,  // comment
  bcd: String // comment
) {
}

```

```swift
func abc(
  a: String,
  bcd: String
) {
}

```

```swift
#imageLiteral(resourceName: "foo,bar,baz")
```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
func abc(a: String↓ ,b: String) { }
```

```swift
func abc(a: String↓ ,b: String↓ ,c: String↓ ,d: String) { }
```

```swift
abc(a: "string"↓,b: "string"
```

```swift
enum a { case a↓ ,b }
```

```swift
let result = plus(
    first: 3↓ , // #683
    second: 4
)

```

</details>



## Compiler Protocol Init

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`compiler_protocol_init` | Enabled | No | lint | No | 3.0.0 

The initializers declared in compiler protocols such as `ExpressibleByArrayLiteral` shouldn't be called directly.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
let set: Set<Int> = [1, 2]

```

```swift
let set = Set(array)

```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
let set = ↓Set(arrayLiteral: 1, 2)

```

```swift
let set = ↓Set.init(arrayLiteral: 1, 2)

```

</details>



## Conditional Returns on Newline

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`conditional_returns_on_newline` | Disabled | No | style | No | 3.0.0 

Conditional statements should always return on the next line

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
guard true else {
 return true
}
```

```swift
guard true,
 let x = true else {
 return true
}
```

```swift
if true else {
 return true
}
```

```swift
if true,
 let x = true else {
 return true
}
```

```swift
if textField.returnKeyType == .Next {
```

```swift
if true { // return }
```

```swift
/*if true { */ return }
```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
↓guard true else { return }
```

```swift
↓if true { return }
```

```swift
↓if true { break } else { return }
```

```swift
↓if true { break } else {       return }
```

```swift
↓if true { return "YES" } else { return "NO" }
```

</details>



## Contains over first not nil

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`contains_over_first_not_nil` | Disabled | No | performance | No | 3.0.0 

Prefer `contains` over `first(where:) != nil` and `firstIndex(where:) != nil`.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
let first = myList.first(where: { $0 % 2 == 0 })

```

```swift
let first = myList.first { $0 % 2 == 0 }

```

```swift
let firstIndex = myList.firstIndex(where: { $0 % 2 == 0 })

```

```swift
let firstIndex = myList.firstIndex { $0 % 2 == 0 }

```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
↓myList.first { $0 % 2 == 0 } != nil

```

```swift
↓myList.first(where: { $0 % 2 == 0 }) != nil

```

```swift
↓myList.map { $0 + 1 }.first(where: { $0 % 2 == 0 }) != nil

```

```swift
↓myList.first(where: someFunction) != nil

```

```swift
↓myList.map { $0 + 1 }.first { $0 % 2 == 0 } != nil

```

```swift
(↓myList.first { $0 % 2 == 0 }) != nil

```

```swift
↓myList.firstIndex { $0 % 2 == 0 } != nil

```

```swift
↓myList.firstIndex(where: { $0 % 2 == 0 }) != nil

```

```swift
↓myList.map { $0 + 1 }.firstIndex(where: { $0 % 2 == 0 }) != nil

```

```swift
↓myList.firstIndex(where: someFunction) != nil

```

```swift
↓myList.map { $0 + 1 }.firstIndex { $0 % 2 == 0 } != nil

```

```swift
(↓myList.firstIndex { $0 % 2 == 0 }) != nil

```

</details>



## Control Statement

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`control_statement` | Enabled | No | style | No | 3.0.0 

`if`, `for`, `guard`, `switch`, `while`, and `catch` statements shouldn't unnecessarily wrap their conditionals or arguments in parentheses.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
if condition {

```

```swift
if (a, b) == (0, 1) {

```

```swift
if (a || b) && (c || d) {

```

```swift
if (min...max).contains(value) {

```

```swift
if renderGif(data) {

```

```swift
renderGif(data)

```

```swift
for item in collection {

```

```swift
for (key, value) in dictionary {

```

```swift
for (index, value) in enumerate(array) {

```

```swift
for var index = 0; index < 42; index++ {

```

```swift
guard condition else {

```

```swift
while condition {

```

```swift
} while condition {

```

```swift
do { ; } while condition {

```

```swift
switch foo {

```

```swift
do {
} catch let error as NSError {
}
```

```swift
foo().catch(all: true) {}
```

```swift
if max(a, b) < c {

```

```swift
switch (lhs, rhs) {

```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
↓if (condition) {

```

```swift
↓if(condition) {

```

```swift
↓if (condition == endIndex) {

```

```swift
↓if ((a || b) && (c || d)) {

```

```swift
↓if ((min...max).contains(value)) {

```

```swift
↓for (item in collection) {

```

```swift
↓for (var index = 0; index < 42; index++) {

```

```swift
↓for(item in collection) {

```

```swift
↓for(var index = 0; index < 42; index++) {

```

```swift
↓guard (condition) else {

```

```swift
↓while (condition) {

```

```swift
↓while(condition) {

```

```swift
} ↓while (condition) {

```

```swift
} ↓while(condition) {

```

```swift
do { ; } ↓while(condition) {

```

```swift
do { ; } ↓while (condition) {

```

```swift
↓switch (foo) {

```

```swift
do {
} ↓catch(let error as NSError) {
}
```

```swift
↓if (max(a, b) < c) {

```

</details>



## Convenience Type

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`convenience_type` | Disabled | No | idiomatic | No | 4.1.0 

Types used for hosting only static members should be implemented as a caseless enum to avoid instantiation.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
enum Math { // enum
  public static let pi = 3.14
}
```

```swift
// class with inheritance
class MathViewController: UIViewController {
  public static let pi = 3.14
}
```

```swift
@objc class Math: NSObject { // class visible to Obj-C
  public static let pi = 3.14
}
```

```swift
struct Math { // type with non-static declarations
  public static let pi = 3.14
  public let randomNumber = 2
}
```

```swift
class DummyClass {}
```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
↓struct Math {
  public static let pi = 3.14
}
```

```swift
↓class Math {
  public static let pi = 3.14
}
```

```swift
↓struct Math {
  public static let pi = 3.14
  @available(*, unavailable) init() {}
}
```

</details>



## Custom Rules

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`custom_rules` | Enabled | No | style | No | 3.0.0 

Create custom rules by providing a regex string. Optionally specify what syntax kinds to match against, the severity level, and what message to display.



## Cyclomatic Complexity

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`cyclomatic_complexity` | Enabled | No | metrics | No | 3.0.0 

Complexity of function bodies should be limited.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
func f1() {
if true {
for _ in 1..5 { } }
if false { }
}
```

```swift
func f(code: Int) -> Int {switch code {
 case 0: fallthrough
case 0: return 1
case 0: return 1
case 0: return 1
case 0: return 1
case 0: return 1
case 0: return 1
case 0: return 1
case 0: return 1
default: return 1}}
```

```swift
func f1() {if true {}; if true {}; if true {}; if true {}; if true {}; if true {}
func f2() {
if true {}; if true {}; if true {}; if true {}; if true {}
}}
```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
↓func f1() {
  if true {
    if true {
      if false {}
    }
  }
  if false {}
  let i = 0

  switch i {
  case 1: break
  case 2: break
  case 3: break
  case 4: break
 default: break
  }
  for _ in 1...5 {
    guard true else {
      return
    }
  }
}

```

</details>



## Deployment Target

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`deployment_target` | Enabled | No | lint | No | 4.1.0 

Availability checks or attributes shouldn't be using older versions that are satisfied by the deployment target.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
@available(iOS 12.0, *)
class A {}
```

```swift
@available(watchOS 4.0, *)
class A {}
```

```swift
@available(swift 3.0.2)
class A {}
```

```swift
class A {}
```

```swift
if #available(iOS 10.0, *) {}
```

```swift
if #available(iOS 10, *) {}
```

```swift
guard #available(iOS 12.0, *) else { return }
```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
↓@available(iOS 6.0, *)
class A {}
```

```swift
↓@available(iOS 7.0, *)
class A {}
```

```swift
↓@available(iOS 6, *)
class A {}
```

```swift
↓@available(iOS 6.0, macOS 10.12, *)
 class A {}
```

```swift
↓@available(macOS 10.12, iOS 6.0, *)
 class A {}
```

```swift
↓@available(macOS 10.7, *)
class A {}
```

```swift
↓@available(OSX 10.7, *)
class A {}
```

```swift
↓@available(watchOS 0.9, *)
class A {}
```

```swift
↓@available(tvOS 8, *)
class A {}
```

```swift
if ↓#available(iOS 6.0, *) {}
```

```swift
if ↓#available(iOS 6, *) {}
```

```swift
guard ↓#available(iOS 6.0, *) else { return }
```

</details>



## Discarded Notification Center Observer

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`discarded_notification_center_observer` | Enabled | No | lint | No | 3.0.0 

When registering for a notification using a block, the opaque observer that is returned should be stored so it can be removed later.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
let foo = nc.addObserver(forName: .NSSystemTimeZoneDidChange, object: nil, queue: nil) { }

```

```swift
let foo = nc.addObserver(forName: .NSSystemTimeZoneDidChange, object: nil, queue: nil, using: { })

```

```swift
func foo() -> Any {
   return nc.addObserver(forName: .NSSystemTimeZoneDidChange, object: nil, queue: nil, using: { })
}

```

```swift
var obs: [Any?] = []
obs.append(nc.addObserver(forName: .NSSystemTimeZoneDidChange, object: nil, queue: nil, using: { }))

```

```swift
var obs: [String: Any?] = []
obs["foo"] = nc.addObserver(forName: .NSSystemTimeZoneDidChange, object: nil, queue: nil, using: { })

```

```swift
var obs: [Any?] = []
obs.append(nc.addObserver(forName: .NSSystemTimeZoneDidChange, object: nil, queue: nil, using: { }))

```

```swift
func foo(_ notif: Any) {
   obs.append(notif)
}
foo(nc.addObserver(forName: .NSSystemTimeZoneDidChange, object: nil, queue: nil, using: { }))

```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
↓nc.addObserver(forName: .NSSystemTimeZoneDidChange, object: nil, queue: nil) { }

```

```swift
↓nc.addObserver(forName: .NSSystemTimeZoneDidChange, object: nil, queue: nil, using: { })

```

```swift
@discardableResult func foo() -> Any {
   return ↓nc.addObserver(forName: .NSSystemTimeZoneDidChange, object: nil, queue: nil, using: { })
}

```

</details>



## Discouraged Direct Initialization

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`discouraged_direct_init` | Enabled | No | lint | No | 3.0.0 

Discouraged direct initialization of types that can be harmful.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
let foo = UIDevice.current
```

```swift
let foo = Bundle.main
```

```swift
let foo = Bundle(path: "bar")
```

```swift
let foo = Bundle(identifier: "bar")
```

```swift
let foo = Bundle.init(path: "bar")
```

```swift
let foo = Bundle.init(identifier: "bar")
```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
↓UIDevice()
```

```swift
↓Bundle()
```

```swift
let foo = ↓UIDevice()
```

```swift
let foo = ↓Bundle()
```

```swift
let foo = bar(bundle: ↓Bundle(), device: ↓UIDevice())
```

```swift
↓UIDevice.init()
```

```swift
↓Bundle.init()
```

```swift
let foo = ↓UIDevice.init()
```

```swift
let foo = ↓Bundle.init()
```

```swift
let foo = bar(bundle: ↓Bundle.init(), device: ↓UIDevice.init())
```

</details>



## Discouraged Object Literal

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`discouraged_object_literal` | Disabled | No | idiomatic | No | 3.0.0 

Prefer initializers over object literals.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
let image = UIImage(named: aVariable)
```

```swift
let image = UIImage(named: "interpolated \(variable)")
```

```swift
let color = UIColor(red: value, green: value, blue: value, alpha: 1)
```

```swift
let image = NSImage(named: aVariable)
```

```swift
let image = NSImage(named: "interpolated \(variable)")
```

```swift
let color = NSColor(red: value, green: value, blue: value, alpha: 1)
```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
let image = ↓#imageLiteral(resourceName: "image.jpg")
```

```swift
let color = ↓#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)
```

</details>



## Discouraged Optional Boolean

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`discouraged_optional_boolean` | Disabled | No | idiomatic | No | 3.0.0 

Prefer non-optional booleans over optional booleans.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
var foo: Bool
```

```swift
var foo: [String: Bool]
```

```swift
var foo: [Bool]
```

```swift
let foo: Bool = true
```

```swift
let foo: Bool = false
```

```swift
let foo: [String: Bool] = [:]
```

```swift
let foo: [Bool] = []
```

```swift
var foo: Bool { return true }
```

```swift
let foo: Bool { return false }()
```

```swift
func foo() -> Bool {}
```

```swift
func foo() -> [String: Bool] {}
```

```swift
func foo() -> ([Bool]) -> String {}
```

```swift
func foo(input: Bool = true) {}
```

```swift
func foo(input: [String: Bool] = [:]) {}
```

```swift
func foo(input: [Bool] = []) {}
```

```swift
class Foo {
	func foo() -> Bool {}
}
```

```swift
class Foo {
	func foo() -> [String: Bool] {}
}
```

```swift
class Foo {
	func foo() -> ([Bool]) -> String {}
}
```

```swift
struct Foo {
	func foo() -> Bool {}
}
```

```swift
struct Foo {
	func foo() -> [String: Bool] {}
}
```

```swift
struct Foo {
	func foo() -> ([Bool]) -> String {}
}
```

```swift
enum Foo {
	func foo() -> Bool {}
}
```

```swift
enum Foo {
	func foo() -> [String: Bool] {}
}
```

```swift
enum Foo {
	func foo() -> ([Bool]) -> String {}
}
```

```swift
class Foo {
	func foo(input: Bool = true) {}
}
```

```swift
class Foo {
	func foo(input: [String: Bool] = [:]) {}
}
```

```swift
class Foo {
	func foo(input: [Bool] = []) {}
}
```

```swift
struct Foo {
	func foo(input: Bool = true) {}
}
```

```swift
struct Foo {
	func foo(input: [String: Bool] = [:]) {}
}
```

```swift
struct Foo {
	func foo(input: [Bool] = []) {}
}
```

```swift
enum Foo {
	func foo(input: Bool = true) {}
}
```

```swift
enum Foo {
	func foo(input: [String: Bool] = [:]) {}
}
```

```swift
enum Foo {
	func foo(input: [Bool] = []) {}
}
```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
var foo: ↓Bool?
```

```swift
var foo: [String: ↓Bool?]
```

```swift
var foo: [↓Bool?]
```

```swift
let foo: ↓Bool? = nil
```

```swift
let foo: [String: ↓Bool?] = [:]
```

```swift
let foo: [↓Bool?] = []
```

```swift
let foo = ↓Optional.some(false)
```

```swift
let foo = ↓Optional.some(true)
```

```swift
var foo: ↓Bool? { return nil }
```

```swift
let foo: ↓Bool? { return nil }()
```

```swift
func foo() -> ↓Bool? {}
```

```swift
func foo() -> [String: ↓Bool?] {}
```

```swift
func foo() -> [↓Bool?] {}
```

```swift
static func foo() -> ↓Bool? {}
```

```swift
static func foo() -> [String: ↓Bool?] {}
```

```swift
static func foo() -> [↓Bool?] {}
```

```swift
func foo() -> (↓Bool?) -> String {}
```

```swift
func foo() -> ([Int]) -> ↓Bool? {}
```

```swift
func foo(input: ↓Bool?) {}
```

```swift
func foo(input: [String: ↓Bool?]) {}
```

```swift
func foo(input: [↓Bool?]) {}
```

```swift
static func foo(input: ↓Bool?) {}
```

```swift
static func foo(input: [String: ↓Bool?]) {}
```

```swift
static func foo(input: [↓Bool?]) {}
```

```swift
class Foo {
	var foo: ↓Bool?
}
```

```swift
class Foo {
	var foo: [String: ↓Bool?]
}
```

```swift
class Foo {
	let foo: ↓Bool? = nil
}
```

```swift
class Foo {
	let foo: [String: ↓Bool?] = [:]
}
```

```swift
class Foo {
	let foo: [↓Bool?] = []
}
```

```swift
struct Foo {
	var foo: ↓Bool?
}
```

```swift
struct Foo {
	var foo: [String: ↓Bool?]
}
```

```swift
struct Foo {
	let foo: ↓Bool? = nil
}
```

```swift
struct Foo {
	let foo: [String: ↓Bool?] = [:]
}
```

```swift
struct Foo {
	let foo: [↓Bool?] = []
}
```

```swift
class Foo {
	var foo: ↓Bool? { return nil }
}
```

```swift
class Foo {
	let foo: ↓Bool? { return nil }()
}
```

```swift
struct Foo {
	var foo: ↓Bool? { return nil }
}
```

```swift
struct Foo {
	let foo: ↓Bool? { return nil }()
}
```

```swift
enum Foo {
	var foo: ↓Bool? { return nil }
}
```

```swift
enum Foo {
	let foo: ↓Bool? { return nil }()
}
```

```swift
class Foo {
	func foo() -> ↓Bool? {}
}
```

```swift
class Foo {
	func foo() -> [String: ↓Bool?] {}
}
```

```swift
class Foo {
	func foo() -> [↓Bool?] {}
}
```

```swift
class Foo {
	static func foo() -> ↓Bool? {}
}
```

```swift
class Foo {
	static func foo() -> [String: ↓Bool?] {}
}
```

```swift
class Foo {
	static func foo() -> [↓Bool?] {}
}
```

```swift
class Foo {
	func foo() -> (↓Bool?) -> String {}
}
```

```swift
class Foo {
	func foo() -> ([Int]) -> ↓Bool? {}
}
```

```swift
struct Foo {
	func foo() -> ↓Bool? {}
}
```

```swift
struct Foo {
	func foo() -> [String: ↓Bool?] {}
}
```

```swift
struct Foo {
	func foo() -> [↓Bool?] {}
}
```

```swift
struct Foo {
	static func foo() -> ↓Bool? {}
}
```

```swift
struct Foo {
	static func foo() -> [String: ↓Bool?] {}
}
```

```swift
struct Foo {
	static func foo() -> [↓Bool?] {}
}
```

```swift
struct Foo {
	func foo() -> (↓Bool?) -> String {}
}
```

```swift
struct Foo {
	func foo() -> ([Int]) -> ↓Bool? {}
}
```

```swift
enum Foo {
	func foo() -> ↓Bool? {}
}
```

```swift
enum Foo {
	func foo() -> [String: ↓Bool?] {}
}
```

```swift
enum Foo {
	func foo() -> [↓Bool?] {}
}
```

```swift
enum Foo {
	static func foo() -> ↓Bool? {}
}
```

```swift
enum Foo {
	static func foo() -> [String: ↓Bool?] {}
}
```

```swift
enum Foo {
	static func foo() -> [↓Bool?] {}
}
```

```swift
enum Foo {
	func foo() -> (↓Bool?) -> String {}
}
```

```swift
enum Foo {
	func foo() -> ([Int]) -> ↓Bool? {}
}
```

```swift
class Foo {
	func foo(input: ↓Bool?) {}
}
```

```swift
class Foo {
	func foo(input: [String: ↓Bool?]) {}
}
```

```swift
class Foo {
	func foo(input: [↓Bool?]) {}
}
```

```swift
class Foo {
	static func foo(input: ↓Bool?) {}
}
```

```swift
class Foo {
	static func foo(input: [String: ↓Bool?]) {}
}
```

```swift
class Foo {
	static func foo(input: [↓Bool?]) {}
}
```

```swift
struct Foo {
	func foo(input: ↓Bool?) {}
}
```

```swift
struct Foo {
	func foo(input: [String: ↓Bool?]) {}
}
```

```swift
struct Foo {
	func foo(input: [↓Bool?]) {}
}
```

```swift
struct Foo {
	static func foo(input: ↓Bool?) {}
}
```

```swift
struct Foo {
	static func foo(input: [String: ↓Bool?]) {}
}
```

```swift
struct Foo {
	static func foo(input: [↓Bool?]) {}
}
```

```swift
enum Foo {
	func foo(input: ↓Bool?) {}
}
```

```swift
enum Foo {
	func foo(input: [String: ↓Bool?]) {}
}
```

```swift
enum Foo {
	func foo(input: [↓Bool?]) {}
}
```

```swift
enum Foo {
	static func foo(input: ↓Bool?) {}
}
```

```swift
enum Foo {
	static func foo(input: [String: ↓Bool?]) {}
}
```

```swift
enum Foo {
	static func foo(input: [↓Bool?]) {}
}
```

</details>



## Discouraged Optional Collection

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`discouraged_optional_collection` | Disabled | No | idiomatic | No | 3.0.0 

Prefer empty collection over optional collection.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
var foo: [Int]
```

```swift
var foo: [String: Int]
```

```swift
var foo: Set<String>
```

```swift
var foo: [String: [String: Int]]
```

```swift
let foo: [Int] = []
```

```swift
let foo: [String: Int] = [:]
```

```swift
let foo: Set<String> = []
```

```swift
let foo: [String: [String: Int]] = [:]
```

```swift
var foo: [Int] { return [] }
```

```swift
func foo() -> [Int] {}
```

```swift
func foo() -> [String: String] {}
```

```swift
func foo() -> Set<Int> {}
```

```swift
func foo() -> ([Int]) -> String {}
```

```swift
func foo(input: [String] = []) {}
```

```swift
func foo(input: [String: String] = [:]) {}
```

```swift
func foo(input: Set<String> = []) {}
```

```swift
class Foo {
	func foo() -> [Int] {}
}
```

```swift
class Foo {
	func foo() -> [String: String] {}
}
```

```swift
class Foo {
	func foo() -> Set<Int> {}
}
```

```swift
class Foo {
	func foo() -> ([Int]) -> String {}
}
```

```swift
struct Foo {
	func foo() -> [Int] {}
}
```

```swift
struct Foo {
	func foo() -> [String: String] {}
}
```

```swift
struct Foo {
	func foo() -> Set<Int> {}
}
```

```swift
struct Foo {
	func foo() -> ([Int]) -> String {}
}
```

```swift
enum Foo {
	func foo() -> [Int] {}
}
```

```swift
enum Foo {
	func foo() -> [String: String] {}
}
```

```swift
enum Foo {
	func foo() -> Set<Int> {}
}
```

```swift
enum Foo {
	func foo() -> ([Int]) -> String {}
}
```

```swift
class Foo {
	func foo(input: [String] = []) {}
}
```

```swift
class Foo {
	func foo(input: [String: String] = [:]) {}
}
```

```swift
class Foo {
	func foo(input: Set<String> = []) {}
}
```

```swift
struct Foo {
	func foo(input: [String] = []) {}
}
```

```swift
struct Foo {
	func foo(input: [String: String] = [:]) {}
}
```

```swift
struct Foo {
	func foo(input: Set<String> = []) {}
}
```

```swift
enum Foo {
	func foo(input: [String] = []) {}
}
```

```swift
enum Foo {
	func foo(input: [String: String] = [:]) {}
}
```

```swift
enum Foo {
	func foo(input: Set<String> = []) {}
}
```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
↓var foo: [Int]?
```

```swift
↓var foo: [String: Int]?
```

```swift
↓var foo: Set<String>?
```

```swift
↓let foo: [Int]? = nil
```

```swift
↓let foo: [String: Int]? = nil
```

```swift
↓let foo: Set<String>? = nil
```

```swift
↓var foo: [Int]? { return nil }
```

```swift
↓let foo: [Int]? { return nil }()
```

```swift
func ↓foo() -> [T]? {}
```

```swift
func ↓foo() -> [String: String]? {}
```

```swift
func ↓foo() -> [String: [String: String]]? {}
```

```swift
func ↓foo() -> [String: [String: String]?] {}
```

```swift
func ↓foo() -> Set<Int>? {}
```

```swift
static func ↓foo() -> [T]? {}
```

```swift
static func ↓foo() -> [String: String]? {}
```

```swift
static func ↓foo() -> [String: [String: String]]? {}
```

```swift
static func ↓foo() -> [String: [String: String]?] {}
```

```swift
static func ↓foo() -> Set<Int>? {}
```

```swift
func ↓foo() -> ([Int]?) -> String {}
```

```swift
func ↓foo() -> ([Int]) -> [String]? {}
```

```swift
func foo(↓input: [String: String]?) {}
```

```swift
func foo(↓input: [String: [String: String]]?) {}
```

```swift
func foo(↓input: [String: [String: String]?]) {}
```

```swift
func foo(↓↓input: [String: [String: String]?]?) {}
```

```swift
func foo<K, V>(_ dict1: [K: V], ↓_ dict2: [K: V]?) -> [K: V]
```

```swift
func foo<K, V>(dict1: [K: V], ↓dict2: [K: V]?) -> [K: V]
```

```swift
static func foo(↓input: [String: String]?) {}
```

```swift
static func foo(↓input: [String: [String: String]]?) {}
```

```swift
static func foo(↓input: [String: [String: String]?]) {}
```

```swift
static func foo(↓↓input: [String: [String: String]?]?) {}
```

```swift
static func foo<K, V>(_ dict1: [K: V], ↓_ dict2: [K: V]?) -> [K: V]
```

```swift
static func foo<K, V>(dict1: [K: V], ↓dict2: [K: V]?) -> [K: V]
```

```swift
class Foo {
	↓var foo: [Int]?
}
```

```swift
class Foo {
	↓var foo: [String: Int]?
}
```

```swift
class Foo {
	↓var foo: Set<String>?
}
```

```swift
class Foo {
	↓let foo: [Int]? = nil
}
```

```swift
class Foo {
	↓let foo: [String: Int]? = nil
}
```

```swift
class Foo {
	↓let foo: Set<String>? = nil
}
```

```swift
struct Foo {
	↓var foo: [Int]?
}
```

```swift
struct Foo {
	↓var foo: [String: Int]?
}
```

```swift
struct Foo {
	↓var foo: Set<String>?
}
```

```swift
struct Foo {
	↓let foo: [Int]? = nil
}
```

```swift
struct Foo {
	↓let foo: [String: Int]? = nil
}
```

```swift
struct Foo {
	↓let foo: Set<String>? = nil
}
```

```swift
class Foo {
	↓var foo: [Int]? { return nil }
}
```

```swift
class Foo {
	↓let foo: [Int]? { return nil }()
}
```

```swift
class Foo {
	↓var foo: Set<String>? { return nil }
}
```

```swift
class Foo {
	↓let foo: Set<String>? { return nil }()
}
```

```swift
struct Foo {
	↓var foo: [Int]? { return nil }
}
```

```swift
struct Foo {
	↓let foo: [Int]? { return nil }()
}
```

```swift
struct Foo {
	↓var foo: Set<String>? { return nil }
}
```

```swift
struct Foo {
	↓let foo: Set<String>? { return nil }()
}
```

```swift
enum Foo {
	↓var foo: [Int]? { return nil }
}
```

```swift
enum Foo {
	↓let foo: [Int]? { return nil }()
}
```

```swift
enum Foo {
	↓var foo: Set<String>? { return nil }
}
```

```swift
enum Foo {
	↓let foo: Set<String>? { return nil }()
}
```

```swift
class Foo {
	func ↓foo() -> [T]? {}
}
```

```swift
class Foo {
	func ↓foo() -> [String: String]? {}
}
```

```swift
class Foo {
	func ↓foo() -> [String: [String: String]]? {}
}
```

```swift
class Foo {
	func ↓foo() -> [String: [String: String]?] {}
}
```

```swift
class Foo {
	func ↓foo() -> Set<Int>? {}
}
```

```swift
class Foo {
	static func ↓foo() -> [T]? {}
}
```

```swift
class Foo {
	static func ↓foo() -> [String: String]? {}
}
```

```swift
class Foo {
	static func ↓foo() -> [String: [String: String]]? {}
}
```

```swift
class Foo {
	static func ↓foo() -> [String: [String: String]?] {}
}
```

```swift
class Foo {
	static func ↓foo() -> Set<Int>? {}
}
```

```swift
class Foo {
	func ↓foo() -> ([Int]?) -> String {}
}
```

```swift
class Foo {
	func ↓foo() -> ([Int]) -> [String]? {}
}
```

```swift
struct Foo {
	func ↓foo() -> [T]? {}
}
```

```swift
struct Foo {
	func ↓foo() -> [String: String]? {}
}
```

```swift
struct Foo {
	func ↓foo() -> [String: [String: String]]? {}
}
```

```swift
struct Foo {
	func ↓foo() -> [String: [String: String]?] {}
}
```

```swift
struct Foo {
	func ↓foo() -> Set<Int>? {}
}
```

```swift
struct Foo {
	static func ↓foo() -> [T]? {}
}
```

```swift
struct Foo {
	static func ↓foo() -> [String: String]? {}
}
```

```swift
struct Foo {
	static func ↓foo() -> [String: [String: String]]? {}
}
```

```swift
struct Foo {
	static func ↓foo() -> [String: [String: String]?] {}
}
```

```swift
struct Foo {
	static func ↓foo() -> Set<Int>? {}
}
```

```swift
struct Foo {
	func ↓foo() -> ([Int]?) -> String {}
}
```

```swift
struct Foo {
	func ↓foo() -> ([Int]) -> [String]? {}
}
```

```swift
enum Foo {
	func ↓foo() -> [T]? {}
}
```

```swift
enum Foo {
	func ↓foo() -> [String: String]? {}
}
```

```swift
enum Foo {
	func ↓foo() -> [String: [String: String]]? {}
}
```

```swift
enum Foo {
	func ↓foo() -> [String: [String: String]?] {}
}
```

```swift
enum Foo {
	func ↓foo() -> Set<Int>? {}
}
```

```swift
enum Foo {
	static func ↓foo() -> [T]? {}
}
```

```swift
enum Foo {
	static func ↓foo() -> [String: String]? {}
}
```

```swift
enum Foo {
	static func ↓foo() -> [String: [String: String]]? {}
}
```

```swift
enum Foo {
	static func ↓foo() -> [String: [String: String]?] {}
}
```

```swift
enum Foo {
	static func ↓foo() -> Set<Int>? {}
}
```

```swift
enum Foo {
	func ↓foo() -> ([Int]?) -> String {}
}
```

```swift
enum Foo {
	func ↓foo() -> ([Int]) -> [String]? {}
}
```

```swift
class Foo {
	func foo(↓input: [String: String]?) {}
}
```

```swift
class Foo {
	func foo(↓input: [String: [String: String]]?) {}
}
```

```swift
class Foo {
	func foo(↓input: [String: [String: String]?]) {}
}
```

```swift
class Foo {
	func foo(↓↓input: [String: [String: String]?]?) {}
}
```

```swift
class Foo {
	func foo<K, V>(_ dict1: [K: V], ↓_ dict2: [K: V]?) -> [K: V]
}
```

```swift
class Foo {
	func foo<K, V>(dict1: [K: V], ↓dict2: [K: V]?) -> [K: V]
}
```

```swift
class Foo {
	static func foo(↓input: [String: String]?) {}
}
```

```swift
class Foo {
	static func foo(↓input: [String: [String: String]]?) {}
}
```

```swift
class Foo {
	static func foo(↓input: [String: [String: String]?]) {}
}
```

```swift
class Foo {
	static func foo(↓↓input: [String: [String: String]?]?) {}
}
```

```swift
class Foo {
	static func foo<K, V>(_ dict1: [K: V], ↓_ dict2: [K: V]?) -> [K: V]
}
```

```swift
class Foo {
	static func foo<K, V>(dict1: [K: V], ↓dict2: [K: V]?) -> [K: V]
}
```

```swift
struct Foo {
	func foo(↓input: [String: String]?) {}
}
```

```swift
struct Foo {
	func foo(↓input: [String: [String: String]]?) {}
}
```

```swift
struct Foo {
	func foo(↓input: [String: [String: String]?]) {}
}
```

```swift
struct Foo {
	func foo(↓↓input: [String: [String: String]?]?) {}
}
```

```swift
struct Foo {
	func foo<K, V>(_ dict1: [K: V], ↓_ dict2: [K: V]?) -> [K: V]
}
```

```swift
struct Foo {
	func foo<K, V>(dict1: [K: V], ↓dict2: [K: V]?) -> [K: V]
}
```

```swift
struct Foo {
	static func foo(↓input: [String: String]?) {}
}
```

```swift
struct Foo {
	static func foo(↓input: [String: [String: String]]?) {}
}
```

```swift
struct Foo {
	static func foo(↓input: [String: [String: String]?]) {}
}
```

```swift
struct Foo {
	static func foo(↓↓input: [String: [String: String]?]?) {}
}
```

```swift
struct Foo {
	static func foo<K, V>(_ dict1: [K: V], ↓_ dict2: [K: V]?) -> [K: V]
}
```

```swift
struct Foo {
	static func foo<K, V>(dict1: [K: V], ↓dict2: [K: V]?) -> [K: V]
}
```

```swift
enum Foo {
	func foo(↓input: [String: String]?) {}
}
```

```swift
enum Foo {
	func foo(↓input: [String: [String: String]]?) {}
}
```

```swift
enum Foo {
	func foo(↓input: [String: [String: String]?]) {}
}
```

```swift
enum Foo {
	func foo(↓↓input: [String: [String: String]?]?) {}
}
```

```swift
enum Foo {
	func foo<K, V>(_ dict1: [K: V], ↓_ dict2: [K: V]?) -> [K: V]
}
```

```swift
enum Foo {
	func foo<K, V>(dict1: [K: V], ↓dict2: [K: V]?) -> [K: V]
}
```

```swift
enum Foo {
	static func foo(↓input: [String: String]?) {}
}
```

```swift
enum Foo {
	static func foo(↓input: [String: [String: String]]?) {}
}
```

```swift
enum Foo {
	static func foo(↓input: [String: [String: String]?]) {}
}
```

```swift
enum Foo {
	static func foo(↓↓input: [String: [String: String]?]?) {}
}
```

```swift
enum Foo {
	static func foo<K, V>(_ dict1: [K: V], ↓_ dict2: [K: V]?) -> [K: V]
}
```

```swift
enum Foo {
	static func foo<K, V>(dict1: [K: V], ↓dict2: [K: V]?) -> [K: V]
}
```

</details>



## Duplicate Enum Cases

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`duplicate_enum_cases` | Enabled | No | lint | No | 3.0.0 

Enum can't contain multiple cases with the same name.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
enum PictureImport {
    case addImage(image: UIImage)
    case addData(data: Data)
}
```

```swift
enum A {
    case add(image: UIImage)
}
enum B {
    case add(image: UIImage)
}
```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
enum PictureImport {
    case ↓add(image: UIImage)
    case addURL(url: URL)
    case ↓add(data: Data)
}
```

</details>



## Duplicate Imports

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`duplicate_imports` | Enabled | No | idiomatic | No | 3.0.0 

Imports should be unique.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
import A
import B
import C
```

```swift
import A.B
import A.C
```

```swift
#if DEBUG
    @testable import KsApi
#else
    import KsApi
#endif
```

```swift
import A // module
import B // module
```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
import Foundation
import Dispatch
↓import Foundation
```

```swift
import Foundation
↓import Foundation.NSString
```

```swift
↓import Foundation.NSString
import Foundation
```

```swift
↓import A.B.C
import A.B
```

```swift
import A.B
↓import A.B.C
```

```swift
import A
#if DEBUG
    @testable import KsApi
#else
    import KsApi
#endif
↓import A
```

```swift
import A
↓import typealias A.Foo
```

```swift
import A
↓import struct A.Foo
```

```swift
import A
↓import class A.Foo
```

```swift
import A
↓import enum A.Foo
```

```swift
import A
↓import protocol A.Foo
```

```swift
import A
↓import let A.Foo
```

```swift
import A
↓import var A.Foo
```

```swift
import A
↓import func A.Foo
```

```swift
import A
↓import typealias A.B.Foo
```

```swift
import A
↓import struct A.B.Foo
```

```swift
import A
↓import class A.B.Foo
```

```swift
import A
↓import enum A.B.Foo
```

```swift
import A
↓import protocol A.B.Foo
```

```swift
import A
↓import let A.B.Foo
```

```swift
import A
↓import var A.B.Foo
```

```swift
import A
↓import func A.B.Foo
```

```swift
import A.B
↓import typealias A.B.Foo
```

```swift
import A.B
↓import struct A.B.Foo
```

```swift
import A.B
↓import class A.B.Foo
```

```swift
import A.B
↓import enum A.B.Foo
```

```swift
import A.B
↓import protocol A.B.Foo
```

```swift
import A.B
↓import let A.B.Foo
```

```swift
import A.B
↓import var A.B.Foo
```

```swift
import A.B
↓import func A.B.Foo
```

</details>



## Dynamic Inline

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`dynamic_inline` | Enabled | No | lint | No | 3.0.0 

Avoid using 'dynamic' and '@inline(__always)' together.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
class C {
dynamic func f() {}}
```

```swift
class C {
@inline(__always) func f() {}}
```

```swift
class C {
@inline(never) dynamic func f() {}}
```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
class C {
@inline(__always) dynamic ↓func f() {}
}
```

```swift
class C {
@inline(__always) public dynamic ↓func f() {}
}
```

```swift
class C {
@inline(__always) dynamic internal ↓func f() {}
}
```

```swift
class C {
@inline(__always)
dynamic ↓func f() {}
}
```

```swift
class C {
@inline(__always)
dynamic
↓func f() {}
}
```

</details>



## Empty Count

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`empty_count` | Disabled | No | performance | No | 3.0.0 

Prefer checking `isEmpty` over comparing `count` to zero.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
var count = 0

```

```swift
[Int]().isEmpty

```

```swift
[Int]().count > 1

```

```swift
[Int]().count == 1

```

```swift
[Int]().count == 0xff

```

```swift
[Int]().count == 0b01

```

```swift
[Int]().count == 0o07

```

```swift
discount == 0

```

```swift
order.discount == 0

```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
[Int]().↓count == 0

```

```swift
[Int]().↓count > 0

```

```swift
[Int]().↓count != 0

```

```swift
[Int]().↓count == 0x0

```

```swift
[Int]().↓count == 0x00_00

```

```swift
[Int]().↓count == 0b00

```

```swift
[Int]().↓count == 0o00

```

```swift
↓count == 0

```

</details>



## Empty Enum Arguments

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`empty_enum_arguments` | Enabled | Yes | style | No | 3.0.0 

Arguments can be omitted when matching enums with associated types if they are not used.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
switch foo {
    case .bar: break
}
```

```swift
switch foo {
    case .bar(let x): break
}
```

```swift
switch foo {
    case let .bar(x): break
}
```

```swift
switch (foo, bar) {
    case (_, _): break
}
```

```swift
switch foo {
    case "bar".uppercased(): break
}
```

```swift
switch (foo, bar) {
    case (_, _) where !something: break
}
```

```swift
switch foo {
    case (let f as () -> String)?: break
}
```

```swift
switch foo {
    default: break
}
```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
switch foo {
    case .bar↓(_): break
}
```

```swift
switch foo {
    case .bar↓(): break
}
```

```swift
switch foo {
    case .bar↓(_), .bar2↓(_): break
}
```

```swift
switch foo {
    case .bar↓() where method() > 2: break
}
```

```swift
func example(foo: Foo) {
    switch foo {
    case case .bar↓(_):
        break
    }
}
```

</details>



## Empty Parameters

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`empty_parameters` | Enabled | Yes | style | No | 3.0.0 

Prefer `() -> ` over `Void -> `.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
let abc: () -> Void = {}

```

```swift
func foo(completion: () -> Void)

```

```swift
func foo(completion: () thows -> Void)

```

```swift
let foo: (ConfigurationTests) -> Void throws -> Void)

```

```swift
let foo: (ConfigurationTests) ->   Void throws -> Void)

```

```swift
let foo: (ConfigurationTests) ->Void throws -> Void)

```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
let abc: ↓(Void) -> Void = {}

```

```swift
func foo(completion: ↓(Void) -> Void)

```

```swift
func foo(completion: ↓(Void) throws -> Void)

```

```swift
let foo: ↓(Void) -> () throws -> Void)

```

</details>



## Empty Parentheses with Trailing Closure

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`empty_parentheses_with_trailing_closure` | Enabled | Yes | style | No | 3.0.0 

When using trailing closures, empty parentheses should be avoided after the method call.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
[1, 2].map { $0 + 1 }

```

```swift
[1, 2].map({ $0 + 1 })

```

```swift
[1, 2].reduce(0) { $0 + $1 }
```

```swift
[1, 2].map { number in
 number + 1 
}

```

```swift
let isEmpty = [1, 2].isEmpty()

```

```swift
UIView.animateWithDuration(0.3, animations: {
   self.disableInteractionRightView.alpha = 0
}, completion: { _ in
   ()
})
```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
[1, 2].map↓() { $0 + 1 }

```

```swift
[1, 2].map↓( ) { $0 + 1 }

```

```swift
[1, 2].map↓() { number in
 number + 1 
}

```

```swift
[1, 2].map↓(  ) { number in
 number + 1 
}

```

```swift
func foo() -> [Int] {
    return [1, 2].map↓() { $0 + 1 }
}

```

</details>



## Empty String

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`empty_string` | Disabled | No | performance | No | 3.0.0 

Prefer checking `isEmpty` over comparing `string` to an empty string literal.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
myString.isEmpty
```

```swift
!myString.isEmpy
```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
myString↓ == ""
```

```swift
myString↓ != ""
```

</details>



## Empty XCTest Method

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`empty_xctest_method` | Disabled | No | lint | No | 3.0.0 

Empty XCTest method should be avoided.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
class TotoTests: XCTestCase {
    var foobar: Foobar?

    override func setUp() {
        super.setUp()
        foobar = Foobar()
    }

    override func tearDown() {
        foobar = nil
        super.tearDown()
    }

    func testFoo() {
        XCTAssertTrue(foobar?.foo)
    }

    func testBar() {
        // comment...

        XCTAssertFalse(foobar?.bar)

        // comment...
    }
}
```

```swift
class Foobar {
    func setUp() {}

    func tearDown() {}

    func testFoo() {}
}
```

```swift
class TotoTests: XCTestCase {
    func setUp(with object: Foobar) {}

    func tearDown(object: Foobar) {}

    func testFoo(_ foo: Foobar) {}

    func testBar(bar: (String) -> Int) {}
}
```

```swift
class TotoTests: XCTestCase {
    func testFoo() { XCTAssertTrue(foobar?.foo) }

    func testBar() { XCTAssertFalse(foobar?.bar) }
}
```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
class TotoTests: XCTestCase {
    override ↓func setUp() {
    }

    override ↓func tearDown() {

    }

    ↓func testFoo() {


    }

    ↓func testBar() {



    }

    func helperFunction() {
    }
}
```

```swift
class TotoTests: XCTestCase {
    override ↓func setUp() {}

    override ↓func tearDown() {}

    ↓func testFoo() {}

    func helperFunction() {}
}
```

```swift
class TotoTests: XCTestCase {
    override ↓func setUp() {
        // comment...
    }

    override ↓func tearDown() {
        // comment...
        // comment...
    }

    ↓func testFoo() {
        // comment...

        // comment...

        // comment...
    }

    ↓func testBar() {
        /*
         * comment...
         *
         * comment...
         *
         * comment...
         */
    }

    func helperFunction() {
    }
}
```

```swift
class FooTests: XCTestCase {
    override ↓func setUp() {}
}

class BarTests: XCTestCase {
    ↓func testFoo() {}
}
```

</details>



## Explicit ACL

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`explicit_acl` | Disabled | No | idiomatic | No | 3.0.0 

All declarations should specify Access Control Level keywords explicitly.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
internal enum A {}

```

```swift
public final class B {}

```

```swift
private struct C {}

```

```swift
internal enum A {
 internal enum B {}
}
```

```swift
internal final class Foo {}
```

```swift
internal
class Foo {
  private let bar = 5
}
```

```swift
internal func a() { let a =  }

```

```swift
private func a() { func innerFunction() { } }
```

```swift
private enum Foo { enum Bar { } }
```

```swift
private struct C { let d = 5 }
```

```swift
internal protocol A {
  func b()
}
```

```swift
internal protocol A {
  var b: Int
}
```

```swift
internal class A { deinit {} }
```

```swift
extension A: Equatable {}
```

```swift
extension A {}
```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
enum A {}

```

```swift
final class B {}

```

```swift
internal struct C { let d = 5 }

```

```swift
public struct C { let d = 5 }

```

```swift
func a() {}

```

```swift
internal let a = 0
func b() {}

```

</details>



## Explicit Enum Raw Value

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`explicit_enum_raw_value` | Disabled | No | idiomatic | No | 3.0.0 

Enums should be explicitly assigned their raw values.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
enum Numbers {
  case int(Int)
  case short(Int16)
}
```

```swift
enum Numbers: Int {
  case one = 1
  case two = 2
}
```

```swift
enum Numbers: Double {
  case one = 1.1
  case two = 2.2
}
```

```swift
enum Numbers: String {
  case one = "one"
  case two = "two"
}
```

```swift
protocol Algebra {}
enum Numbers: Algebra {
  case one
}
```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
enum Numbers: Int {
  case one = 10, ↓two, three = 30
}
```

```swift
enum Numbers: NSInteger {
  case ↓one
}
```

```swift
enum Numbers: String {
  case ↓one
  case ↓two
}
```

```swift
enum Numbers: String {
   case ↓one, two = "two"
}
```

```swift
enum Numbers: Decimal {
  case ↓one, ↓two
}
```

</details>



## Explicit Init

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`explicit_init` | Disabled | Yes | idiomatic | No | 3.0.0 

Explicitly calling .init() should be avoided.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
import Foundation; class C: NSObject { override init() { super.init() }}
```

```swift
struct S { let n: Int }; extension S { init() { self.init(n: 1) } }
```

```swift
[1].flatMap(String.init)
```

```swift
[String.self].map { $0.init(1) }
```

```swift
[String.self].map { type in type.init(1) }
```

```swift
Observable.zip(obs1, obs2, resultSelector: MyType.init).asMaybe()
```

```swift
Observable.zip(
  obs1,
  obs2,
  resultSelector: MyType.init
).asMaybe()
```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
[1].flatMap{String↓.init($0)}
```

```swift
[String.self].map { Type in Type↓.init(1) }
```

```swift
func foo() -> [String] {
  return [1].flatMap { String↓.init($0) }
}
```

```swift
Observable.zip(
  obs1,
  obs2,
  resultSelector: { MyType.init($0, $1) }
).asMaybe()
```

</details>



## Explicit Self

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`explicit_self` | Disabled | Yes | style | Yes | 3.0.0 

Instance variables and functions should be explicitly accessed with 'self.'.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
struct A {
    func f1() {}
    func f2() {
        self.f1()
    }
}
```

```swift
struct A {
    let p1: Int
    func f1() {
        _ = self.p1
    }
}
```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
struct A {
    func f1() {}
    func f2() {
        ↓f1()
    }
}
```

```swift
struct A {
    let p1: Int
    func f1() {
        _ = ↓p1
    }
}
```

</details>



## Explicit Top Level ACL

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`explicit_top_level_acl` | Disabled | No | idiomatic | No | 3.0.0 

Top-level declarations should specify Access Control Level keywords explicitly.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
internal enum A {}

```

```swift
public final class B {}

```

```swift
private struct C {}

```

```swift
internal enum A {
 enum B {}
}
```

```swift
internal final class Foo {}
```

```swift
internal
class Foo {}
```

```swift
internal func a() {}

```

```swift
extension A: Equatable {}
```

```swift
extension A {}
```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
enum A {}

```

```swift
final class B {}

```

```swift
struct C {}

```

```swift
func a() {}

```

```swift
internal let a = 0
func b() {}

```

</details>



## Explicit Type Interface

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`explicit_type_interface` | Disabled | No | idiomatic | No | 3.0.0 

Properties should have a type interface

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
class Foo {
  var myVar: Int? = 0
}
```

```swift
class Foo {
  let myVar: Int? = 0
}
```

```swift
class Foo {
  static var myVar: Int? = 0
}
```

```swift
class Foo {
  class var myVar: Int? = 0
}
```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
class Foo {
  ↓var myVar = 0
}
```

```swift
class Foo {
  ↓let mylet = 0
}
```

```swift
class Foo {
  ↓static var myStaticVar = 0
}
```

```swift
class Foo {
  ↓class var myClassVar = 0
}
```

```swift
class Foo {
  ↓let myVar = Int(0)
}
```

```swift
class Foo {
  ↓let myVar = Set<Int>(0)
}
```

</details>



## Extension Access Modifier

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`extension_access_modifier` | Disabled | No | idiomatic | No | 3.0.0 

Prefer to use extension access modifiers

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
extension Foo: SomeProtocol {
  public var bar: Int { return 1 }
}
```

```swift
extension Foo {
  private var bar: Int { return 1 }
  public var baz: Int { return 1 }
}
```

```swift
extension Foo {
  private var bar: Int { return 1 }
  public func baz() {}
}
```

```swift
extension Foo {
  var bar: Int { return 1 }
  var baz: Int { return 1 }
}
```

```swift
public extension Foo {
  var bar: Int { return 1 }
  var baz: Int { return 1 }
}
```

```swift
extension Foo {
  private bar: Int { return 1 }
  private baz: Int { return 1 }
}
```

```swift
extension Foo {
  open bar: Int { return 1 }
  open baz: Int { return 1 }
}
```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
↓extension Foo {
   public var bar: Int { return 1 }
   public var baz: Int { return 1 }
}
```

```swift
↓extension Foo {
   public var bar: Int { return 1 }
   public func baz() {}
}
```

```swift
public extension Foo {
   public ↓func bar() {}
   public ↓func baz() {}
}
```

</details>



## Fallthrough

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`fallthrough` | Disabled | No | idiomatic | No | 3.0.0 

Fallthrough should be avoided.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
switch foo {
case .bar, .bar2, .bar3:
  something()
}
```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
switch foo {
case .bar:
  ↓fallthrough
case .bar2:
  something()
}
```

</details>



## Fatal Error Message

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`fatal_error_message` | Disabled | No | idiomatic | No | 3.0.0 

A fatalError call should have a message.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
func foo() {
  fatalError("Foo")
}
```

```swift
func foo() {
  fatalError(x)
}
```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
func foo() {
  ↓fatalError("")
}
```

```swift
func foo() {
  ↓fatalError()
}
```

</details>



## File Header

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`file_header` | Disabled | No | style | No | 3.0.0 

Header comments should be consistent with project patterns. The SWIFTLINT_CURRENT_FILENAME placeholder can optionally be used in the required and forbidden patterns. It will be replaced by the real file name.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
let foo = "Copyright"
```

```swift
let foo = 2 // Copyright
```

```swift
let foo = 2
 // Copyright
```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
// ↓Copyright

```

```swift
//
// ↓Copyright
```

```swift
//
//  FileHeaderRule.swift
//  SwiftLint
//
//  Created by Marcelo Fabri on 27/11/16.
//  ↓Copyright © 2016 Realm. All rights reserved.
//
```

</details>



## File Line Length

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`file_length` | Enabled | No | metrics | No | 3.0.0 

Files should not span too many lines.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")

```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")

```

```swift
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
print("swiftlint")
//

```

</details>



## File Name

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`file_name` | Disabled | No | idiomatic | No | 3.0.0 

File name should match a type or extension declared in the file (if any).



## File Types Order

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`file_types_order` | Disabled | No | style | No | 3.0.0 

Specifies how the types within a file should be ordered.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
// Supporting Types
protocol TestViewControllerDelegate {
    func didPressTrackedButton()
}

// Main Type
class TestViewController: UIViewController {
    // Type Aliases
    typealias CompletionHandler = ((TestEnum) -> Void)

    // Subtypes
    class TestClass {
        // 10 lines
    }

    struct TestStruct {
        // 3 lines
    }

    enum TestEnum {
        // 5 lines
    }

    // Stored Type Properties
    static let cellIdentifier: String = "AmazingCell"

    // Stored Instance Properties
    var shouldLayoutView1: Bool!
    weak var delegate: TestViewControllerDelegate?
    private var hasLayoutedView1: Bool = false
    private var hasLayoutedView2: Bool = false

    // Computed Instance Properties
    private var hasAnyLayoutedView: Bool {
         return hasLayoutedView1 || hasLayoutedView2
    }

    // IBOutlets
    @IBOutlet private var view1: UIView!
    @IBOutlet private var view2: UIView!

    // Initializers
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // Type Methods
    static func makeViewController() -> TestViewController {
        // some code
    }

    // Life-Cycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()

        view1.setNeedsLayout()
        view1.layoutIfNeeded()
        hasLayoutedView1 = true
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        view2.setNeedsLayout()
        view2.layoutIfNeeded()
        hasLayoutedView2 = true
    }

    // IBActions
    @IBAction func goNextButtonPressed() {
        goToNextVc()
        delegate?.didPressTrackedButton()
    }

    @objc
    func goToRandomVcButtonPressed() {
        goToRandomVc()
    }

    // MARK: Other Methods
    func goToNextVc() { /* TODO */ }

    func goToInfoVc() { /* TODO */ }

    func goToRandomVc() {
        let viewCtrl = getRandomVc()
        present(viewCtrl, animated: true)
    }

    private func getRandomVc() -> UIViewController { return UIViewController() }

    // Subscripts
    subscript(_ someIndexThatIsNotEvenUsed: Int) -> String {
        get {
            return "This is just a test"
        }

        set {
            log.warning("Just a test", newValue)
        }
    }
}

// Extensions
extension TestViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return UITableViewCell()
    }
}
```

```swift
// Only extensions
extension Foo {}
extension Bar {
}
```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
↓class TestViewController: UIViewController {}

// Supporting Types
protocol TestViewControllerDelegate {
    func didPressTrackedButton()
}
```

```swift
// Extensions
↓extension TestViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return UITableViewCell()
    }
}

class TestViewController: UIViewController {}
```

```swift
// Supporting Types
protocol TestViewControllerDelegate {
    func didPressTrackedButton()
}

↓class TestViewController: UIViewController {}

// Supporting Types
protocol TestViewControllerDelegate {
    func didPressTrackedButton()
}
```

```swift
// Supporting Types
protocol TestViewControllerDelegate {
    func didPressTrackedButton()
}

// Extensions
↓extension TestViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return UITableViewCell()
    }
}

class TestViewController: UIViewController {}

// Extensions
extension TestViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return UITableViewCell()
    }
}
```

</details>



## First Where

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`first_where` | Disabled | No | performance | No | 3.0.0 

Prefer using `.first(where:)` over `.filter { }.first` in collections.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
kinds.filter(excludingKinds.contains).isEmpty && kinds.first == .identifier

```

```swift
myList.first(where: { $0 % 2 == 0 })

```

```swift
match(pattern: pattern).filter { $0.first == .identifier }

```

```swift
(myList.filter { $0 == 1 }.suffix(2)).first

```

```swift
collection.filter("stringCol = '3'").first
```

```swift
realm?.objects(User.self).filter(NSPredicate(format: "email ==[c] %@", email)).first
```

```swift
if let pause = timeTracker.pauses.filter("beginDate < %@", beginDate).first { print(pause) }
```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
↓myList.filter { $0 % 2 == 0 }.first

```

```swift
↓myList.filter({ $0 % 2 == 0 }).first

```

```swift
↓myList.map { $0 + 1 }.filter({ $0 % 2 == 0 }).first

```

```swift
↓myList.map { $0 + 1 }.filter({ $0 % 2 == 0 }).first?.something()

```

```swift
↓myList.filter(someFunction).first

```

```swift
↓myList.filter({ $0 % 2 == 0 })
.first

```

```swift
(↓myList.filter { $0 == 1 }).first

```

</details>



## For Where

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`for_where` | Enabled | No | idiomatic | No | 3.0.0 

`where` clauses are preferred over a single `if` inside a `for`.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
for user in users where user.id == 1 { }
```

```swift
for user in users {
  if let id = user.id { }
}
```

```swift
for user in users {
  if var id = user.id { }
}
```

```swift
for user in users {
  if user.id == 1 { } else { }
}
```

```swift
for user in users {
  if user.id == 1 {
  } else if user.id == 2 { }
}
```

```swift
for user in users {
  if user.id == 1 { }
  print(user)
}
```

```swift
for user in users {
  let id = user.id
  if id == 1 { }
}
```

```swift
for user in users {
  if user.id == 1 { }
  return true
}
```

```swift
for user in users {
  if user.id == 1 && user.age > 18 { }
}
```

```swift
for (index, value) in array.enumerated() {
  if case .valueB(_) = value {
    return index
  }
}
```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
for user in users {
  ↓if user.id == 1 { return true }
}
```

</details>



## Force Cast

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`force_cast` | Enabled | No | idiomatic | No | 3.0.0 

Force casts should be avoided.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
NSNumber() as? Int

```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
NSNumber() ↓as! Int

```

</details>



## Force Try

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`force_try` | Enabled | No | idiomatic | No | 3.0.0 

Force tries should be avoided.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
func a() throws {}
do {
  try a()
} catch {}
```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
func a() throws {}
↓try! a()
```

</details>



## Force Unwrapping

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`force_unwrapping` | Disabled | No | idiomatic | No | 3.0.0 

Force unwrapping should be avoided.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
if let url = NSURL(string: query)
```

```swift
navigationController?.pushViewController(viewController, animated: true)
```

```swift
let s as! Test
```

```swift
try! canThrowErrors()
```

```swift
let object: Any!
```

```swift
@IBOutlet var constraints: [NSLayoutConstraint]!
```

```swift
setEditing(!editing, animated: true)
```

```swift
navigationController.setNavigationBarHidden(!navigationController.navigationBarHidden, animated: true)
```

```swift
if addedToPlaylist && (!self.selectedFilters.isEmpty || self.searchBar?.text?.isEmpty == false) {}
```

```swift
print("\(xVar)!")
```

```swift
var test = (!bar)
```

```swift
var a: [Int]!
```

```swift
private var myProperty: (Void -> Void)!
```

```swift
func foo(_ options: [AnyHashable: Any]!) {
```

```swift
func foo() -> [Int]!
```

```swift
func foo() -> [AnyHashable: Any]!
```

```swift
func foo() -> [Int]! { return [] }
```

```swift
return self
```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
let url = NSURL(string: query)↓!
```

```swift
navigationController↓!.pushViewController(viewController, animated: true)
```

```swift
let unwrapped = optional↓!
```

```swift
return cell↓!
```

```swift
let url = NSURL(string: "http://www.google.com")↓!
```

```swift
let dict = ["Boooo": "👻"]func bla() -> String { return dict["Boooo"]↓! }
```

```swift
let dict = ["Boooo": "👻"]func bla() -> String { return dict["Boooo"]↓!.contains("B") }
```

```swift
let a = dict["abc"]↓!.contains("B")
```

```swift
dict["abc"]↓!.bar("B")
```

```swift
if dict["a"]↓!!!! {
```

```swift
var foo: [Bool]! = dict["abc"]↓!
```

```swift
context("abc") {
  var foo: [Bool]! = dict["abc"]↓!
}
```

```swift
open var computed: String { return foo.bar↓! }
```

```swift
return self↓!
```

</details>



## Function Body Length

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`function_body_length` | Enabled | No | metrics | No | 3.0.0 

Functions bodies should not span too many lines.



## Function Default Parameter at End

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`function_default_parameter_at_end` | Disabled | No | idiomatic | No | 3.0.0 

Prefer to locate parameters with defaults toward the end of the parameter list.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
func foo(baz: String, bar: Int = 0) {}
```

```swift
func foo(x: String, y: Int = 0, z: CGFloat = 0) {}
```

```swift
func foo(bar: String, baz: Int = 0, z: () -> Void) {}
```

```swift
func foo(bar: String, z: () -> Void, baz: Int = 0) {}
```

```swift
func foo(bar: Int = 0) {}
```

```swift
func foo() {}
```

```swift
class A: B {
  override func foo(bar: Int = 0, baz: String) {}
```

```swift
func foo(bar: Int = 0, completion: @escaping CompletionHandler) {}
```

```swift
func foo(a: Int, b: CGFloat = 0) {
  let block = { (error: Error?) in }
}
```

```swift
func foo(a: String, b: String? = nil,
         c: String? = nil, d: @escaping AlertActionHandler = { _ in }) {}
```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
↓func foo(bar: Int = 0, baz: String) {}
```

</details>



## Function Parameter Count

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`function_parameter_count` | Enabled | No | metrics | No | 3.0.0 

Number of function parameters should be low.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
init(a: Int, b: Int, c: Int, d: Int, e: Int, f: Int) {}
```

```swift
init (a: Int, b: Int, c: Int, d: Int, e: Int, f: Int) {}
```

```swift
`init`(a: Int, b: Int, c: Int, d: Int, e: Int, f: Int) {}
```

```swift
init?(a: Int, b: Int, c: Int, d: Int, e: Int, f: Int) {}
```

```swift
init?<T>(a: T, b: Int, c: Int, d: Int, e: Int, f: Int) {}
```

```swift
init?<T: String>(a: T, b: Int, c: Int, d: Int, e: Int, f: Int) {}
```

```swift
func f2(p1: Int, p2: Int) { }
```

```swift
func f(a: Int, b: Int, c: Int, d: Int, x: Int = 42) {}
```

```swift
func f(a: [Int], b: Int, c: Int, d: Int, f: Int) -> [Int] {
let s = a.flatMap { $0 as? [String: Int] } ?? []}}
```

```swift
override func f(a: Int, b: Int, c: Int, d: Int, e: Int, f: Int) {}
```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
↓func f(a: Int, b: Int, c: Int, d: Int, e: Int, f: Int) {}
```

```swift
↓func initialValue(a: Int, b: Int, c: Int, d: Int, e: Int, f: Int) {}
```

```swift
↓func f(a: Int, b: Int, c: Int, d: Int, e: Int, f: Int = 2, g: Int) {}
```

```swift
struct Foo {
init(a: Int, b: Int, c: Int, d: Int, e: Int, f: Int) {}
↓func bar(a: Int, b: Int, c: Int, d: Int, e: Int, f: Int) {}}
```

</details>



## Generic Type Name

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`generic_type_name` | Enabled | No | idiomatic | No | 3.0.0 

Generic type name should only contain alphanumeric characters, start with an uppercase character and span between 1 and 20 characters in length.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
func foo<T>() {}

```

```swift
func foo<T>() -> T {}

```

```swift
func foo<T, U>(param: U) -> T {}

```

```swift
func foo<T: Hashable, U: Rule>(param: U) -> T {}

```

```swift
struct Foo<T> {}

```

```swift
class Foo<T> {}

```

```swift
enum Foo<T> {}

```

```swift
func run(_ options: NoOptions<CommandantError<()>>) {}

```

```swift
func foo(_ options: Set<type>) {}

```

```swift
func < <T: Comparable>(lhs: T?, rhs: T?) -> Bool

```

```swift
func configureWith(data: Either<MessageThread, (project: Project, backing: Backing)>)

```

```swift
typealias StringDictionary<T> = Dictionary<String, T>

```

```swift
typealias BackwardTriple<T1, T2, T3> = (T3, T2, T1)

```

```swift
typealias DictionaryOfStrings<T : Hashable> = Dictionary<T, String>

```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
func foo<↓T_Foo>() {}

```

```swift
func foo<T, ↓U_Foo>(param: U_Foo) -> T {}

```

```swift
func foo<↓TTTTTTTTTTTTTTTTTTTTT>() {}

```

```swift
func foo<↓type>() {}

```

```swift
typealias StringDictionary<↓T_Foo> = Dictionary<String, T_Foo>

```

```swift
typealias BackwardTriple<T1, ↓T2_Bar, T3> = (T3, T2_Bar, T1)

```

```swift
typealias DictionaryOfStrings<↓T_Foo: Hashable> = Dictionary<T_Foo, String>

```

```swift
class Foo<↓T_Foo> {}

```

```swift
class Foo<T, ↓U_Foo> {}

```

```swift
class Foo<↓T_Foo, ↓U_Foo> {}

```

```swift
class Foo<↓TTTTTTTTTTTTTTTTTTTTT> {}

```

```swift
class Foo<↓type> {}

```

```swift
struct Foo<↓T_Foo> {}

```

```swift
struct Foo<T, ↓U_Foo> {}

```

```swift
struct Foo<↓T_Foo, ↓U_Foo> {}

```

```swift
struct Foo<↓TTTTTTTTTTTTTTTTTTTTT> {}

```

```swift
struct Foo<↓type> {}

```

```swift
enum Foo<↓T_Foo> {}

```

```swift
enum Foo<T, ↓U_Foo> {}

```

```swift
enum Foo<↓T_Foo, ↓U_Foo> {}

```

```swift
enum Foo<↓TTTTTTTTTTTTTTTTTTTTT> {}

```

```swift
enum Foo<↓type> {}

```

</details>



## Identical Operands

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`identical_operands` | Disabled | No | lint | No | 3.0.0 

Comparing two identical operands is likely a mistake.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
1 == 2
```

```swift
foo == bar
```

```swift
prefixedFoo == foo
```

```swift
foo.aProperty == foo.anotherProperty
```

```swift
self.aProperty == self.anotherProperty
```

```swift
"1 == 1"
```

```swift
self.aProperty == aProperty
```

```swift
lhs.aProperty == rhs.aProperty
```

```swift
lhs.identifier == rhs.identifier
```

```swift
i == index
```

```swift
$0 == 0
```

```swift
keyValues?.count ?? 0 == 0
```

```swift
string == string.lowercased()
```

```swift
let num: Int? = 0
_ = num != nil && num == num?.byteSwapped
```

```swift
1 != 2
```

```swift
foo != bar
```

```swift
prefixedFoo != foo
```

```swift
foo.aProperty != foo.anotherProperty
```

```swift
self.aProperty != self.anotherProperty
```

```swift
"1 != 1"
```

```swift
self.aProperty != aProperty
```

```swift
lhs.aProperty != rhs.aProperty
```

```swift
lhs.identifier != rhs.identifier
```

```swift
i != index
```

```swift
$0 != 0
```

```swift
keyValues?.count ?? 0 != 0
```

```swift
string != string.lowercased()
```

```swift
let num: Int? = 0
_ = num != nil && num != num?.byteSwapped
```

```swift
1 === 2
```

```swift
foo === bar
```

```swift
prefixedFoo === foo
```

```swift
foo.aProperty === foo.anotherProperty
```

```swift
self.aProperty === self.anotherProperty
```

```swift
"1 === 1"
```

```swift
self.aProperty === aProperty
```

```swift
lhs.aProperty === rhs.aProperty
```

```swift
lhs.identifier === rhs.identifier
```

```swift
i === index
```

```swift
$0 === 0
```

```swift
keyValues?.count ?? 0 === 0
```

```swift
string === string.lowercased()
```

```swift
let num: Int? = 0
_ = num != nil && num === num?.byteSwapped
```

```swift
1 !== 2
```

```swift
foo !== bar
```

```swift
prefixedFoo !== foo
```

```swift
foo.aProperty !== foo.anotherProperty
```

```swift
self.aProperty !== self.anotherProperty
```

```swift
"1 !== 1"
```

```swift
self.aProperty !== aProperty
```

```swift
lhs.aProperty !== rhs.aProperty
```

```swift
lhs.identifier !== rhs.identifier
```

```swift
i !== index
```

```swift
$0 !== 0
```

```swift
keyValues?.count ?? 0 !== 0
```

```swift
string !== string.lowercased()
```

```swift
let num: Int? = 0
_ = num != nil && num !== num?.byteSwapped
```

```swift
1 > 2
```

```swift
foo > bar
```

```swift
prefixedFoo > foo
```

```swift
foo.aProperty > foo.anotherProperty
```

```swift
self.aProperty > self.anotherProperty
```

```swift
"1 > 1"
```

```swift
self.aProperty > aProperty
```

```swift
lhs.aProperty > rhs.aProperty
```

```swift
lhs.identifier > rhs.identifier
```

```swift
i > index
```

```swift
$0 > 0
```

```swift
keyValues?.count ?? 0 > 0
```

```swift
string > string.lowercased()
```

```swift
let num: Int? = 0
_ = num != nil && num > num?.byteSwapped
```

```swift
1 >= 2
```

```swift
foo >= bar
```

```swift
prefixedFoo >= foo
```

```swift
foo.aProperty >= foo.anotherProperty
```

```swift
self.aProperty >= self.anotherProperty
```

```swift
"1 >= 1"
```

```swift
self.aProperty >= aProperty
```

```swift
lhs.aProperty >= rhs.aProperty
```

```swift
lhs.identifier >= rhs.identifier
```

```swift
i >= index
```

```swift
$0 >= 0
```

```swift
keyValues?.count ?? 0 >= 0
```

```swift
string >= string.lowercased()
```

```swift
let num: Int? = 0
_ = num != nil && num >= num?.byteSwapped
```

```swift
1 < 2
```

```swift
foo < bar
```

```swift
prefixedFoo < foo
```

```swift
foo.aProperty < foo.anotherProperty
```

```swift
self.aProperty < self.anotherProperty
```

```swift
"1 < 1"
```

```swift
self.aProperty < aProperty
```

```swift
lhs.aProperty < rhs.aProperty
```

```swift
lhs.identifier < rhs.identifier
```

```swift
i < index
```

```swift
$0 < 0
```

```swift
keyValues?.count ?? 0 < 0
```

```swift
string < string.lowercased()
```

```swift
let num: Int? = 0
_ = num != nil && num < num?.byteSwapped
```

```swift
1 <= 2
```

```swift
foo <= bar
```

```swift
prefixedFoo <= foo
```

```swift
foo.aProperty <= foo.anotherProperty
```

```swift
self.aProperty <= self.anotherProperty
```

```swift
"1 <= 1"
```

```swift
self.aProperty <= aProperty
```

```swift
lhs.aProperty <= rhs.aProperty
```

```swift
lhs.identifier <= rhs.identifier
```

```swift
i <= index
```

```swift
$0 <= 0
```

```swift
keyValues?.count ?? 0 <= 0
```

```swift
string <= string.lowercased()
```

```swift
let num: Int? = 0
_ = num != nil && num <= num?.byteSwapped
```

```swift
func evaluate(_ mode: CommandMode) -> Result<AutoCorrectOptions, CommandantError<CommandantError<()>>>
```

```swift
let array = Array<Array<Int>>()
```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
↓1 == 1
```

```swift
↓foo == foo
```

```swift
↓foo.aProperty == foo.aProperty
```

```swift
↓self.aProperty == self.aProperty
```

```swift
↓$0 == $0
```

```swift
↓1 != 1
```

```swift
↓foo != foo
```

```swift
↓foo.aProperty != foo.aProperty
```

```swift
↓self.aProperty != self.aProperty
```

```swift
↓$0 != $0
```

```swift
↓1 === 1
```

```swift
↓foo === foo
```

```swift
↓foo.aProperty === foo.aProperty
```

```swift
↓self.aProperty === self.aProperty
```

```swift
↓$0 === $0
```

```swift
↓1 !== 1
```

```swift
↓foo !== foo
```

```swift
↓foo.aProperty !== foo.aProperty
```

```swift
↓self.aProperty !== self.aProperty
```

```swift
↓$0 !== $0
```

```swift
↓1 > 1
```

```swift
↓foo > foo
```

```swift
↓foo.aProperty > foo.aProperty
```

```swift
↓self.aProperty > self.aProperty
```

```swift
↓$0 > $0
```

```swift
↓1 >= 1
```

```swift
↓foo >= foo
```

```swift
↓foo.aProperty >= foo.aProperty
```

```swift
↓self.aProperty >= self.aProperty
```

```swift
↓$0 >= $0
```

```swift
↓1 < 1
```

```swift
↓foo < foo
```

```swift
↓foo.aProperty < foo.aProperty
```

```swift
↓self.aProperty < self.aProperty
```

```swift
↓$0 < $0
```

```swift
↓1 <= 1
```

```swift
↓foo <= foo
```

```swift
↓foo.aProperty <= foo.aProperty
```

```swift
↓self.aProperty <= self.aProperty
```

```swift
↓$0 <= $0
```

</details>



## Identifier Name

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`identifier_name` | Enabled | No | style | No | 3.0.0 

Identifier names should only contain alphanumeric characters and start with a lowercase character or should only contain capital letters. In an exception to the above, variable names may start with a capital letter when they are declared static and immutable. Variable names should not be too long or too short.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
let myLet = 0
```

```swift
var myVar = 0
```

```swift
private let _myLet = 0
```

```swift
class Abc { static let MyLet = 0 }
```

```swift
let URL: NSURL? = nil
```

```swift
let XMLString: String? = nil
```

```swift
override var i = 0
```

```swift
enum Foo { case myEnum }
```

```swift
func isOperator(name: String) -> Bool
```

```swift
func typeForKind(_ kind: SwiftDeclarationKind) -> String
```

```swift
func == (lhs: SyntaxToken, rhs: SyntaxToken) -> Bool
```

```swift
override func IsOperator(name: String) -> Bool
```

```swift
enum Foo { case `private` }
```

```swift
enum Foo { case value(String) }
```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
↓let MyLet = 0
```

```swift
↓let _myLet = 0
```

```swift
private ↓let myLet_ = 0
```

```swift
↓let myExtremelyVeryVeryVeryVeryVeryVeryLongLet = 0
```

```swift
↓var myExtremelyVeryVeryVeryVeryVeryVeryLongVar = 0
```

```swift
private ↓let _myExtremelyVeryVeryVeryVeryVeryVeryLongLet = 0
```

```swift
↓let i = 0
```

```swift
↓var id = 0
```

```swift
private ↓let _i = 0
```

```swift
↓func IsOperator(name: String) -> Bool
```

```swift
enum Foo { case ↓MyEnum }
```

</details>



## Implicit Getter

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`implicit_getter` | Enabled | No | style | No | 3.0.0 

Computed read-only properties and subscripts should avoid using the get keyword.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
class Foo {
    var foo: Int {
        get { return 3 }
        set { _abc = newValue }
    }
}
```

```swift
class Foo {
    var foo: Int {
        return 20
    }
}
```

```swift
class Foo {
    static var foo: Int {
        return 20
    }
}
```

```swift
class Foo {
    static var foo: Int {
        get { return 3 }
        set { _abc = newValue }
    }
}
```

```swift
class Foo {
    var foo: Int
}
```

```swift
class Foo {
    var foo: Int {
        return getValueFromDisk()
    }
}
```

```swift
class Foo {
    var foo: String {
        return "get"
    }
}
```

```swift
protocol Foo {
    var foo: Int { get }

```

```swift
protocol Foo {
    var foo: Int { get set }

```

```swift
class Foo {
    var foo: Int {
        struct Bar {
            var bar: Int {
                get { return 1 }
                set { _ = newValue }
            }
        }

        return Bar().bar
    }
}
```

```swift
var _objCTaggedPointerBits: UInt {
    @inline(__always) get { return 0 }
}
```

```swift
var next: Int? {
    mutating get {
        defer { self.count += 1 }
        return self.count
    }
}
```

```swift
class Foo {
    subscript(i: Int) -> Int {
        return 20
    }
}
```

```swift
class Foo {
    subscript(i: Int) -> Int {
        get { return 3 }
        set { _abc = newValue }
    }
}
```

```swift
protocol Foo {
    subscript(i: Int) -> Int { get }
}
```

```swift
protocol Foo {
    subscript(i: Int) -> Int { get set }
}
```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
class Foo {
    var foo: Int {
        ↓get {
            return 20
        }
    }
}
```

```swift
class Foo {
    var foo: Int {
        ↓get{ return 20 }
    }
}
```

```swift
class Foo {
    static var foo: Int {
        ↓get {
            return 20
        }
    }
}
```

```swift
var foo: Int {
    ↓get { return 20 }
}
```

```swift
class Foo {
    @objc func bar() {}
    var foo: Int {
        ↓get {
            return 20
        }
    }
}
```

```swift
class Foo {
    subscript(i: Int) -> Int {
        ↓get {
            return 20
        }
    }
}
```

</details>



## Implicit Return

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`implicit_return` | Disabled | Yes | style | No | 3.0.0 

Prefer implicit returns in closures.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
foo.map { $0 + 1 }
```

```swift
foo.map({ $0 + 1 })
```

```swift
foo.map { value in value + 1 }
```

```swift
func foo() -> Int {
  return 0
}
```

```swift
if foo {
  return 0
}
```

```swift
var foo: Bool { return true }
```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
foo.map { value in
  ↓return value + 1
}
```

```swift
foo.map {
  ↓return $0 + 1
}
```

```swift
foo.map({ ↓return $0 + 1})
```

```swift
[1, 2].first(where: {
    ↓return true
})
```

</details>



## Implicitly Unwrapped Optional

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`implicitly_unwrapped_optional` | Disabled | No | idiomatic | No | 3.0.0 

Implicitly unwrapped optionals should be avoided when possible.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
@IBOutlet private var label: UILabel!
```

```swift
@IBOutlet var label: UILabel!
```

```swift
@IBOutlet var label: [UILabel!]
```

```swift
if !boolean {}
```

```swift
let int: Int? = 42
```

```swift
let int: Int? = nil
```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
let label: UILabel!
```

```swift
let IBOutlet: UILabel!
```

```swift
let labels: [UILabel!]
```

```swift
var ints: [Int!] = [42, nil, 42]
```

```swift
let label: IBOutlet!
```

```swift
let int: Int! = 42
```

```swift
let int: Int! = nil
```

```swift
var int: Int! = 42
```

```swift
let int: ImplicitlyUnwrappedOptional<Int>
```

```swift
let collection: AnyCollection<Int!>
```

```swift
func foo(int: Int!) {}
```

</details>



## Inert Defer

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`inert_defer` | Enabled | No | lint | No | 3.0.0 

If defer is at the end of its parent scope, it will be executed right where it is anyway.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
func example3() {
    defer { /* deferred code */ }

    print("other code")
}
```

```swift
func example4() {
    if condition {
        defer { /* deferred code */ }
        print("other code")
    }
}
```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
func example0() {
    ↓defer { /* deferred code */ }
}
```

```swift
func example1() {
    ↓defer { /* deferred code */ }
    // comment
}
```

```swift
func example2() {
    if condition {
        ↓defer { /* deferred code */ }
        // comment
    }
}
```

</details>



## Is Disjoint

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`is_disjoint` | Enabled | No | idiomatic | No | 3.0.0 

Prefer using `Set.isDisjoint(with:)` over `Set.intersection(_:).isEmpty`.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
_ = Set(syntaxKinds).isDisjoint(with: commentAndStringKindsSet)
```

```swift
let isObjc = !objcAttributes.isDisjoint(with: dictionary.enclosedSwiftAttributes)
```

```swift
_ = Set(syntaxKinds).intersection(commentAndStringKindsSet)
```

```swift
_ = !objcAttributes.intersection(dictionary.enclosedSwiftAttributes)
```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
_ = Set(syntaxKinds).↓intersection(commentAndStringKindsSet).isEmpty
```

```swift
let isObjc = !objcAttributes.↓intersection(dictionary.enclosedSwiftAttributes).isEmpty
```

</details>



## Joined Default Parameter

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`joined_default_parameter` | Disabled | Yes | idiomatic | No | 3.0.0 

Discouraged explicit usage of the default separator.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
let foo = bar.joined()
```

```swift
let foo = bar.joined(separator: ",")
```

```swift
let foo = bar.joined(separator: toto)
```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
let foo = bar.joined(↓separator: "")
```

```swift
let foo = bar.filter(toto)
             .joined(↓separator: ""),
```

```swift
func foo() -> String {
  return ["1", "2"].joined(↓separator: "")
}
```

</details>



## Large Tuple

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`large_tuple` | Enabled | No | metrics | No | 3.0.0 

Tuples shouldn't have too many members. Create a custom type instead.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
let foo: (Int, Int)

```

```swift
let foo: (start: Int, end: Int)

```

```swift
let foo: (Int, (Int, String))

```

```swift
func foo() -> (Int, Int)

```

```swift
func foo() -> (Int, Int) {}

```

```swift
func foo(bar: String) -> (Int, Int)

```

```swift
func foo(bar: String) -> (Int, Int) {}

```

```swift
func foo() throws -> (Int, Int)

```

```swift
func foo() throws -> (Int, Int) {}

```

```swift
let foo: (Int, Int, Int) -> Void

```

```swift
let foo: (Int, Int, Int) throws -> Void

```

```swift
func foo(bar: (Int, String, Float) -> Void)

```

```swift
func foo(bar: (Int, String, Float) throws -> Void)

```

```swift
var completionHandler: ((_ data: Data?, _ resp: URLResponse?, _ e: NSError?) -> Void)!

```

```swift
func getDictionaryAndInt() -> (Dictionary<Int, String>, Int)?

```

```swift
func getGenericTypeAndInt() -> (Type<Int, String, Float>, Int)?

```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
↓let foo: (Int, Int, Int)

```

```swift
↓let foo: (start: Int, end: Int, value: String)

```

```swift
↓let foo: (Int, (Int, Int, Int))

```

```swift
func foo(↓bar: (Int, Int, Int))

```

```swift
func foo() -> ↓(Int, Int, Int)

```

```swift
func foo() -> ↓(Int, Int, Int) {}

```

```swift
func foo(bar: String) -> ↓(Int, Int, Int)

```

```swift
func foo(bar: String) -> ↓(Int, Int, Int) {}

```

```swift
func foo() throws -> ↓(Int, Int, Int)

```

```swift
func foo() throws -> ↓(Int, Int, Int) {}

```

```swift
func foo() throws -> ↓(Int, ↓(String, String, String), Int) {}

```

```swift
func getDictionaryAndInt() -> (Dictionary<Int, ↓(String, String, String)>, Int)?

```

</details>



## Last Where

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`last_where` | Disabled | No | performance | No | 4.2.0 

Prefer using `.last(where:)` over `.filter { }.last` in collections.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
kinds.filter(excludingKinds.contains).isEmpty && kinds.last == .identifier

```

```swift
myList.last(where: { $0 % 2 == 0 })

```

```swift
match(pattern: pattern).filter { $0.last == .identifier }

```

```swift
(myList.filter { $0 == 1 }.suffix(2)).last

```

```swift
collection.filter("stringCol = '3'").last
```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
↓myList.filter { $0 % 2 == 0 }.last

```

```swift
↓myList.filter({ $0 % 2 == 0 }).last

```

```swift
↓myList.map { $0 + 1 }.filter({ $0 % 2 == 0 }).last

```

```swift
↓myList.map { $0 + 1 }.filter({ $0 % 2 == 0 }).last?.something()

```

```swift
↓myList.filter(someFunction).last

```

```swift
↓myList.filter({ $0 % 2 == 0 })
.last

```

```swift
(↓myList.filter { $0 == 1 }).last

```

</details>



## Leading Whitespace

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`leading_whitespace` | Enabled | Yes | style | No | 3.0.0 

Files should not contain leading whitespace.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
//

```

</details>
<details>
<summary>Triggering Examples</summary>

```swift


```

```swift
 //

```

</details>



## Legacy CGGeometry Functions

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`legacy_cggeometry_functions` | Enabled | Yes | idiomatic | No | 3.0.0 

Struct extension properties and methods are preferred over legacy functions

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
rect.width
```

```swift
rect.height
```

```swift
rect.minX
```

```swift
rect.midX
```

```swift
rect.maxX
```

```swift
rect.minY
```

```swift
rect.midY
```

```swift
rect.maxY
```

```swift
rect.isNull
```

```swift
rect.isEmpty
```

```swift
rect.isInfinite
```

```swift
rect.standardized
```

```swift
rect.integral
```

```swift
rect.insetBy(dx: 5.0, dy: -7.0)
```

```swift
rect.offsetBy(dx: 5.0, dy: -7.0)
```

```swift
rect1.union(rect2)
```

```swift
rect1.intersect(rect2)
```

```swift
rect1.contains(rect2)
```

```swift
rect.contains(point)
```

```swift
rect1.intersects(rect2)
```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
↓CGRectGetWidth(rect)
```

```swift
↓CGRectGetHeight(rect)
```

```swift
↓CGRectGetMinX(rect)
```

```swift
↓CGRectGetMidX(rect)
```

```swift
↓CGRectGetMaxX(rect)
```

```swift
↓CGRectGetMinY(rect)
```

```swift
↓CGRectGetMidY(rect)
```

```swift
↓CGRectGetMaxY(rect)
```

```swift
↓CGRectIsNull(rect)
```

```swift
↓CGRectIsEmpty(rect)
```

```swift
↓CGRectIsInfinite(rect)
```

```swift
↓CGRectStandardize(rect)
```

```swift
↓CGRectIntegral(rect)
```

```swift
↓CGRectInset(rect, 10, 5)
```

```swift
↓CGRectOffset(rect, -2, 8.3)
```

```swift
↓CGRectUnion(rect1, rect2)
```

```swift
↓CGRectIntersection(rect1, rect2)
```

```swift
↓CGRectContainsRect(rect1, rect2)
```

```swift
↓CGRectContainsPoint(rect, point)
```

```swift
↓CGRectIntersectsRect(rect1, rect2)
```

</details>



## Legacy Constant

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`legacy_constant` | Enabled | Yes | idiomatic | No | 3.0.0 

Struct-scoped constants are preferred over legacy global constants.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
CGRect.infinite
```

```swift
CGPoint.zero
```

```swift
CGRect.zero
```

```swift
CGSize.zero
```

```swift
NSPoint.zero
```

```swift
NSRect.zero
```

```swift
NSSize.zero
```

```swift
CGRect.null
```

```swift
CGFloat.pi
```

```swift
Float.pi
```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
↓CGRectInfinite
```

```swift
↓CGPointZero
```

```swift
↓CGRectZero
```

```swift
↓CGSizeZero
```

```swift
↓NSZeroPoint
```

```swift
↓NSZeroRect
```

```swift
↓NSZeroSize
```

```swift
↓CGRectNull
```

```swift
↓CGFloat(M_PI)
```

```swift
↓Float(M_PI)
```

</details>



## Legacy Constructor

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`legacy_constructor` | Enabled | Yes | idiomatic | No | 3.0.0 

Swift constructors are preferred over legacy convenience functions.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
CGPoint(x: 10, y: 10)
```

```swift
CGPoint(x: xValue, y: yValue)
```

```swift
CGSize(width: 10, height: 10)
```

```swift
CGSize(width: aWidth, height: aHeight)
```

```swift
CGRect(x: 0, y: 0, width: 10, height: 10)
```

```swift
CGRect(x: xVal, y: yVal, width: aWidth, height: aHeight)
```

```swift
CGVector(dx: 10, dy: 10)
```

```swift
CGVector(dx: deltaX, dy: deltaY)
```

```swift
NSPoint(x: 10, y: 10)
```

```swift
NSPoint(x: xValue, y: yValue)
```

```swift
NSSize(width: 10, height: 10)
```

```swift
NSSize(width: aWidth, height: aHeight)
```

```swift
NSRect(x: 0, y: 0, width: 10, height: 10)
```

```swift
NSRect(x: xVal, y: yVal, width: aWidth, height: aHeight)
```

```swift
NSRange(location: 10, length: 1)
```

```swift
NSRange(location: loc, length: len)
```

```swift
UIEdgeInsets(top: 0, left: 0, bottom: 10, right: 10)
```

```swift
UIEdgeInsets(top: aTop, left: aLeft, bottom: aBottom, right: aRight)
```

```swift
NSEdgeInsets(top: 0, left: 0, bottom: 10, right: 10)
```

```swift
NSEdgeInsets(top: aTop, left: aLeft, bottom: aBottom, right: aRight)
```

```swift
UIOffset(horizontal: 0, vertical: 10)
```

```swift
UIOffset(horizontal: horizontal, vertical: vertical)
```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
↓CGPointMake(10, 10)
```

```swift
↓CGPointMake(xVal, yVal)
```

```swift
↓CGPointMake(calculateX(), 10)

```

```swift
↓CGSizeMake(10, 10)
```

```swift
↓CGSizeMake(aWidth, aHeight)
```

```swift
↓CGRectMake(0, 0, 10, 10)
```

```swift
↓CGRectMake(xVal, yVal, width, height)
```

```swift
↓CGVectorMake(10, 10)
```

```swift
↓CGVectorMake(deltaX, deltaY)
```

```swift
↓NSMakePoint(10, 10)
```

```swift
↓NSMakePoint(xVal, yVal)
```

```swift
↓NSMakeSize(10, 10)
```

```swift
↓NSMakeSize(aWidth, aHeight)
```

```swift
↓NSMakeRect(0, 0, 10, 10)
```

```swift
↓NSMakeRect(xVal, yVal, width, height)
```

```swift
↓NSMakeRange(10, 1)
```

```swift
↓NSMakeRange(loc, len)
```

```swift
↓UIEdgeInsetsMake(0, 0, 10, 10)
```

```swift
↓UIEdgeInsetsMake(top, left, bottom, right)
```

```swift
↓NSEdgeInsetsMake(0, 0, 10, 10)
```

```swift
↓NSEdgeInsetsMake(top, left, bottom, right)
```

```swift
↓CGVectorMake(10, 10)
↓NSMakeRange(10, 1)
```

```swift
↓UIOffsetMake(0, 10)
```

```swift
↓UIOffsetMake(horizontal, vertical)
```

</details>



## Legacy Hashing

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`legacy_hashing` | Enabled | No | idiomatic | No | 4.2.0 

Prefer using the `hash(into:)` function instead of overriding `hashValue`

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
struct Foo: Hashable {
  let bar: Int = 10

  func hash(into hasher: inout Hasher) {
    hasher.combine(bar)
  }
}
```

```swift
class Foo: Hashable {
  let bar: Int = 10

  func hash(into hasher: inout Hasher) {
    hasher.combine(bar)
  }
}
```

```swift
var hashValue: Int { return 1 }
class Foo: Hashable { 
 }
```

```swift
class Foo: Hashable {
  let bar: String = "Foo"

  public var hashValue: String {
    return bar
  }
}
```

```swift
class Foo: Hashable {
  let bar: String = "Foo"

  public var hashValue: String {
    get { return bar }
    set { bar = newValue }
  }
}
```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
struct Foo: Hashable {
    let bar: Int = 10

    public ↓var hashValue: Int {
        return bar
    }
}
```

```swift
class Foo: Hashable {
    let bar: Int = 10

    public ↓var hashValue: Int {
        return bar
    }
}
```

</details>



## Legacy Multiple

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`legacy_multiple` | Disabled | No | idiomatic | No | 5.0.0 

Prefer using the `isMultiple(of:)` function instead of using the remainder operator (`%`).

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
cell.contentView.backgroundColor = indexPath.row.isMultiple(of: 2) ? .gray : .white
```

```swift
guard count.isMultiple(of: 2) else { throw DecodingError.dataCorrupted(...) }
```

```swift
sanityCheck(bytes > 0 && bytes.isMultiple(of: 4), "capacity must be multiple of 4 bytes")
```

```swift
guard let i = reversedNumbers.firstIndex(where: { $0.isMultiple(of: 2) }) else { return }
```

```swift
let constant = 56
let isMultiple = value.isMultiple(of: constant)
```

```swift
let constant = 56
let secret = value % constant == 5
```

```swift
let secretValue = (value % 3) + 2
```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
cell.contentView.backgroundColor = indexPath.row ↓% 2 == 0 ? .gray : .white
```

```swift
cell.contentView.backgroundColor = indexPath.row ↓% 2 != 0 ? .gray : .white
```

```swift
guard count ↓% 2 == 0 else { throw DecodingError.dataCorrupted(...) }
```

```swift
sanityCheck(bytes > 0 && bytes ↓% 4 == 0, "capacity must be multiple of 4 bytes")
```

```swift
guard let i = reversedNumbers.firstIndex(where: { $0 ↓% 2 == 0 }) else { return }
```

```swift
let constant = 56
let isMultiple = value ↓% constant == 0
```

</details>



## Legacy NSGeometry Functions

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`legacy_nsgeometry_functions` | Enabled | Yes | idiomatic | No | 3.0.0 

Struct extension properties and methods are preferred over legacy functions

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
rect.width
```

```swift
rect.height
```

```swift
rect.minX
```

```swift
rect.midX
```

```swift
rect.maxX
```

```swift
rect.minY
```

```swift
rect.midY
```

```swift
rect.maxY
```

```swift
rect.isEmpty
```

```swift
rect.integral
```

```swift
rect.insetBy(dx: 5.0, dy: -7.0)
```

```swift
rect.offsetBy(dx: 5.0, dy: -7.0)
```

```swift
rect1.union(rect2)
```

```swift
rect1.intersect(rect2)
```

```swift
rect1.contains(rect2)
```

```swift
rect.contains(point)
```

```swift
rect1.intersects(rect2)
```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
↓NSWidth(rect)
```

```swift
↓NSHeight(rect)
```

```swift
↓NSMinX(rect)
```

```swift
↓NSMidX(rect)
```

```swift
↓NSMaxX(rect)
```

```swift
↓NSMinY(rect)
```

```swift
↓NSMidY(rect)
```

```swift
↓NSMaxY(rect)
```

```swift
↓NSEqualRects(rect1, rect2)
```

```swift
↓NSEqualSizes(size1, size2)
```

```swift
↓NSEqualPoints(point1, point2)
```

```swift
↓NSEdgeInsetsEqual(insets2, insets2)
```

```swift
↓NSIsEmptyRect(rect)
```

```swift
↓NSIntegralRect(rect)
```

```swift
↓NSInsetRect(rect, 10, 5)
```

```swift
↓NSOffsetRect(rect, -2, 8.3)
```

```swift
↓NSUnionRect(rect1, rect2)
```

```swift
↓NSIntersectionRect(rect1, rect2)
```

```swift
↓NSContainsRect(rect1, rect2)
```

```swift
↓NSPointInRect(rect, point)
```

```swift
↓NSIntersectsRect(rect1, rect2)
```

</details>



## Legacy Random

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`legacy_random` | Disabled | No | idiomatic | No | 4.2.0 

Prefer using `type.random(in:)` over legacy functions.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
Int.random(in: 0..<10)

```

```swift
Double.random(in: 8.6...111.34)

```

```swift
Float.random(in: 0 ..< 1)

```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
↓arc4random(10)

```

```swift
↓arc4random_uniform(83)

```

```swift
↓drand48(52)

```

</details>



## Variable Declaration Whitespace

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`let_var_whitespace` | Disabled | No | style | No | 3.0.0 

Let and var should be separated from other statements by a blank line.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
let a = 0
var x = 1

x = 2

```

```swift
a = 5

var x = 1

```

```swift
struct X {
	var a = 0
}

```

```swift
let a = 1 +
	2
let b = 5

```

```swift
var x: Int {
	return 0
}

```

```swift
var x: Int {
	let a = 0

	return a
}

```

```swift
#if os(macOS)
let a = 0
#endif

```

```swift
#warning("TODO: remove it")
let a = 0

```

```swift
#error("TODO: remove it")
let a = 0

```

```swift
@available(swift 4)
let a = 0

```

```swift
class C {
	@objc
	var s: String = ""
}
```

```swift
class C {
	@objc
	func a() {}
}
```

```swift
class C {
	var x = 0
	lazy
	var y = 0
}

```

```swift
@available(OSX, introduced: 10.6)
@available(*, deprecated)
var x = 0

```

```swift
// swiftlint:disable superfluous_disable_command
// swiftlint:disable force_cast

let x = bar as! Bar
```

```swift
var x: Int {
	let a = 0
	return a
}

```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
var x = 1
↓x = 2

```

```swift

a = 5
↓var x = 1

```

```swift
struct X {
	let a
	↓func x() {}
}

```

```swift
var x = 0
↓@objc func f() {}

```

```swift
var x = 0
↓@objc
	func f() {}

```

```swift
@objc func f() {
}
↓var x = 0

```

</details>



## Line Length

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`line_length` | Enabled | No | metrics | No | 3.0.0 

Lines should not span too many characters.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

```

```swift
#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)

```

```swift
#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")

```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

```

```swift
#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)

```

```swift
#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")#imageLiteral(resourceName: "image.jpg")

```

</details>



## Literal Expression End Indentation

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`literal_expression_end_indentation` | Disabled | Yes | style | No | 3.0.0 

Array and dictionary literal end should have the same indentation as the line that started it.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
[1, 2, 3]
```

```swift
[1,
 2
]
```

```swift
[
   1,
   2
]
```

```swift
[
   1,
   2]

```

```swift
   let x = [
       1,
       2
   ]
```

```swift
[key: 2, key2: 3]
```

```swift
[key: 1,
 key2: 2
]
```

```swift
[
   key: 0,
   key2: 20
]
```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
let x = [
   1,
   2
   ↓]
```

```swift
   let x = [
       1,
       2
↓]
```

```swift
let x = [
   key: value
   ↓]
```

</details>



## Lower ACL than parent

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`lower_acl_than_parent` | Disabled | No | lint | No | 3.0.0 

Ensure definitions have a lower access control level than their enclosing parent

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
public struct Foo { public func bar() {} }
```

```swift
internal struct Foo { func bar() {} }
```

```swift
struct Foo { func bar() {} }
```

```swift
open class Foo { public func bar() {} }
```

```swift
open class Foo { open func bar() {} }
```

```swift
fileprivate struct Foo { private func bar() {} }
```

```swift
private struct Foo { private func bar(id: String) }
```

```swift
extension Foo { public func bar() {} }
```

```swift
private struct Foo { fileprivate func bar() {} }
```

```swift
private func foo(id: String) {}
```

```swift
private class Foo { func bar() {} }
```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
struct Foo { public ↓func bar() {} }
```

```swift
enum Foo { public ↓func bar() {} }
```

```swift
public class Foo { open ↓func bar() }
```

```swift
class Foo { public private(set) ↓var bar: String? }
```

```swift
private class Foo { internal ↓func bar() {} }
```

</details>



## Mark

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`mark` | Enabled | Yes | lint | No | 3.0.0 

MARK comment should be in valid format. e.g. '// MARK: ...' or '// MARK: - ...'

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
// MARK: good

```

```swift
// MARK: - good

```

```swift
// MARK: -

```

```swift
// BOOKMARK
```

```swift
//BOOKMARK
```

```swift
// BOOKMARKS
```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
↓//MARK: bad
```

```swift
↓// MARK:bad
```

```swift
↓//MARK:bad
```

```swift
↓//  MARK: bad
```

```swift
↓// MARK:  bad
```

```swift
↓// MARK: -bad
```

```swift
↓// MARK:- bad
```

```swift
↓// MARK:-bad
```

```swift
↓//MARK: - bad
```

```swift
↓//MARK:- bad
```

```swift
↓//MARK: -bad
```

```swift
↓//MARK:-bad
```

```swift
↓//Mark: bad
```

```swift
↓// Mark: bad
```

```swift
↓// MARK bad
```

```swift
↓//MARK bad
```

```swift
↓// MARK - bad
```

```swift
↓//MARK : bad
```

```swift
↓// MARKL:
```

```swift
↓// MARKR 
```

```swift
↓// MARKK -
```

```swift
↓//MARK:- Top-Level bad mark
↓//MARK:- Another bad mark
struct MarkTest {}
↓// MARK:- Bad mark
extension MarkTest {}

```

</details>



## Missing Docs

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`missing_docs` | Disabled | No | lint | No | 4.1.0 

Declarations should be documented.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
/// docs
public class A {
/// docs
public func b() {}
}
/// docs
public class B: A { override public func b() {} }

```

```swift
import Foundation
/// docs
public class B: NSObject {
// no docs
override public var description: String { fatalError() } }

```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
public func a() {}

```

```swift
// regular comment
public func a() {}

```

```swift
/* regular comment */
public func a() {}

```

```swift
/// docs
public protocol A {
// no docs
var b: Int { get } }
/// docs
public struct C: A {

public let b: Int
}
```

</details>



## Modifier Order

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`modifier_order` | Disabled | Yes | style | No | 4.1.0 

Modifier order should be consistent.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
public class Foo { 
   public convenience required init() {} 
}
```

```swift
public class Foo { 
   public static let bar = 42 
}
```

```swift
public class Foo { 
   public static var bar: Int { 
       return 42   }}
```

```swift
public class Foo { 
   public class var bar: Int { 
       return 42 
   } 
}
```

```swift
public class Bar { 
   public class var foo: String { 
       return "foo" 
   } 
} 
public class Foo: Bar { 
   override public final class var foo: String { 
       return "bar" 
   } 
}
```

```swift
open class Bar { 
   public var foo: Int? { 
       return 42 
   } 
} 
open class Foo: Bar { 
   override public var foo: Int? { 
       return 43 
   } 
}
```

```swift
open class Bar { 
   open class func foo() -> Int { 
       return 42 
   } 
} 
class Foo: Bar { 
   override open class func foo() -> Int { 
       return 43 
   } 
}
```

```swift
protocol Foo: class {} 
class Bar { 
    public private(set) weak var foo: Foo? 
} 

```

```swift
@objc 
public final class Foo: NSObject {} 

```

```swift
@objcMembers 
public final class Foo: NSObject {} 

```

```swift
@objc 
override public private(set) weak var foo: Bar? 

```

```swift
@objc 
public final class Foo: NSObject {} 

```

```swift
@objc 
open final class Foo: NSObject { 
   open weak var weakBar: NSString? = nil 
}
```

```swift
public final class Foo {}
```

```swift
class Bar { 
   func bar() {} 
}
```

```swift
internal class Foo: Bar { 
   override internal func bar() {} 
}
```

```swift
public struct Foo { 
   internal weak var weakBar: NSObject? = nil 
}
```

```swift
class Foo { 
   internal lazy var bar: String = "foo" 
}
```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
class Foo { 
   convenience required public init() {} 
}
```

```swift
public class Foo { 
   static public let bar = 42 
}
```

```swift
public class Foo { 
   static public var bar: Int { 
       return 42 
   } 
} 

```

```swift
public class Foo { 
   class public var bar: Int { 
       return 42 
   } 
}
```

```swift
public class RootFoo { 
   class public var foo: String { 
       return "foo" 
   } 
} 
public class Foo: RootFoo { 
   override final class public var foo: String { 
       return "bar" 
   } 
}
```

```swift
open class Bar { 
   public var foo: Int? { 
       return 42 
   } 
} 
open class Foo: Bar { 
    public override var foo: Int? { 
       return 43 
   } 
}
```

```swift
protocol Foo: class {} 
class Bar { 
    private(set) public weak var foo: Foo? 
} 

```

```swift
open class Bar { 
   open class func foo() -> Int { 
       return 42 
   } 
} 
class Foo: Bar { 
   class open override func foo() -> Int { 
       return 43 
   } 
}
```

```swift
open class Bar { 
   open class func foo() -> Int { 
       return 42 
   } 
} 
class Foo: Bar { 
   open override class func foo() -> Int { 
       return 43 
   } 
}
```

```swift
@objc 
final public class Foo: NSObject {}
```

```swift
@objcMembers 
final public class Foo: NSObject {}
```

```swift
@objc 
final open class Foo: NSObject { 
   weak open var weakBar: NSString? = nil 
}
```

```swift
final public class Foo {} 

```

```swift
internal class Foo: Bar { 
   internal override func bar() {} 
}
```

```swift
public struct Foo { 
   weak internal var weakBar: NSObjetc? = nil 
}
```

```swift
class Foo { 
   lazy internal var bar: String = "foo" 
}
```

</details>



## Multiline Arguments

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`multiline_arguments` | Disabled | No | style | No | 3.0.0 

Arguments should be either on the same line, or one per line.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
foo()
```

```swift
foo(
    
)
```

```swift
foo { }
```

```swift
foo {
    
}
```

```swift
foo(0)
```

```swift
foo(0, 1)
```

```swift
foo(0, 1) { }
```

```swift
foo(0, param1: 1)
```

```swift
foo(0, param1: 1) { }
```

```swift
foo(param1: 1)
```

```swift
foo(param1: 1) { }
```

```swift
foo(param1: 1, param2: true) { }
```

```swift
foo(param1: 1, param2: true, param3: [3]) { }
```

```swift
foo(param1: 1, param2: true, param3: [3]) {
    bar()
}
```

```swift
foo(param1: 1,
    param2: true,
    param3: [3])
```

```swift
foo(
    param1: 1, param2: true, param3: [3]
)
```

```swift
foo(
    param1: 1,
    param2: true,
    param3: [3]
)
```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
foo(0,
    param1: 1, ↓param2: true, ↓param3: [3])
```

```swift
foo(0, ↓param1: 1,
    param2: true, ↓param3: [3])
```

```swift
foo(0, ↓param1: 1, ↓param2: true,
    param3: [3])
```

```swift
foo(
    0, ↓param1: 1,
    param2: true, ↓param3: [3]
)
```

</details>



## Multiline Arguments Brackets

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`multiline_arguments_brackets` | Disabled | No | style | No | 3.0.0 

Multiline arguments should have their surrounding brackets in a new line.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
foo(param1: "Param1", param2: "Param2", param3: "Param3")
```

```swift
foo(
    param1: "Param1", param2: "Param2", param3: "Param3"
)
```

```swift
func foo(
    param1: "Param1",
    param2: "Param2",
    param3: "Param3"
)
```

```swift
foo { param1, param2 in
    print("hello world")
}
```

```swift
foo(
    bar(
        x: 5,
        y: 7
    )
)
```

```swift
AlertViewModel.AlertAction(title: "some title", style: .default) {
    AlertManager.shared.presentNextDebugAlert()
}
```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
foo(↓param1: "Param1", param2: "Param2",
         param3: "Param3"
)
```

```swift
foo(
    param1: "Param1",
    param2: "Param2",
    param3: "Param3"↓)
```

```swift
foo(↓bar(
    x: 5,
    y: 7
)
)
```

```swift
foo(
    bar(
        x: 5,
        y: 7
)↓)
```

</details>



## Multiline Function Chains

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`multiline_function_chains` | Disabled | No | style | No | 3.0.0 

Chained function calls should be either on the same line, or one per line.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
let evenSquaresSum = [20, 17, 35, 4].filter { $0 % 2 == 0 }.map { $0 * $0 }.reduce(0, +)
```

```swift
let evenSquaresSum = [20, 17, 35, 4]
    .filter { $0 % 2 == 0 }.map { $0 * $0 }.reduce(0, +)",
```

```swift
let chain = a
    .b(1, 2, 3)
    .c { blah in
        print(blah)
    }
    .d()
```

```swift
let chain = a.b(1, 2, 3)
    .c { blah in
        print(blah)
    }
    .d()
```

```swift
let chain = a.b(1, 2, 3)
    .c { blah in print(blah) }
    .d()
```

```swift
let chain = a.b(1, 2, 3)
    .c(.init(
        a: 1,
        b, 2,
        c, 3))
    .d()
```

```swift
self.viewModel.outputs.postContextualNotification
  .observeForUI()
  .observeValues {
    NotificationCenter.default.post(
      Notification(
        name: .ksr_showNotificationsDialog,
        userInfo: [UserInfoKeys.context: PushNotificationDialog.Context.pledge,
                   UserInfoKeys.viewController: self]
     )
    )
  }
```

```swift
let remainingIDs = Array(Set(self.currentIDs).subtracting(Set(response.ids)))
```

```swift
self.happeningNewsletterOn = self.updateCurrentUser
    .map { $0.newsletters.happening }.skipNil().skipRepeats()
```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
let evenSquaresSum = [20, 17, 35, 4]
    .filter { $0 % 2 == 0 }↓.map { $0 * $0 }
    .reduce(0, +)
```

```swift
let evenSquaresSum = a.b(1, 2, 3)
    .c { blah in
        print(blah)
    }↓.d()
```

```swift
let evenSquaresSum = a.b(1, 2, 3)
    .c(2, 3, 4)↓.d()
```

```swift
let evenSquaresSum = a.b(1, 2, 3)↓.c { blah in
        print(blah)
    }
    .d()
```

```swift
a.b {
//  ““
}↓.e()
```

</details>



## Multiline Literal Brackets

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`multiline_literal_brackets` | Disabled | No | style | No | 3.0.0 

Multiline literals should have their surrounding brackets in a new line.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
let trio = ["harry", "ronald", "hermione"]
let houseCup = ["gryffinder": 460, "hufflepuff": 370, "ravenclaw": 410, "slytherin": 450]
```

```swift
let trio = [
    "harry",
    "ronald",
    "hermione"
]
let houseCup = [
    "gryffinder": 460,
    "hufflepuff": 370,
    "ravenclaw": 410,
    "slytherin": 450
]
```

```swift
let trio = [
    "harry", "ronald", "hermione"
]
let houseCup = [
    "gryffinder": 460, "hufflepuff": 370,
    "ravenclaw": 410, "slytherin": 450
]
```

```swift
    _ = [
        1,
        2,
        3,
        4,
        5, 6,
        7, 8, 9
    ]
```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
let trio = [↓"harry",
            "ronald",
            "hermione"
]
```

```swift
let houseCup = [↓"gryffinder": 460, "hufflepuff": 370,
                "ravenclaw": 410, "slytherin": 450
]
```

```swift
let trio = [
    "harry",
    "ronald",
    "hermione"↓]
```

```swift
let houseCup = [
    "gryffinder": 460, "hufflepuff": 370,
    "ravenclaw": 410, "slytherin": 450↓]
```

```swift
class Hogwarts {
    let houseCup = [
        "gryffinder": 460, "hufflepuff": 370,
        "ravenclaw": 410, "slytherin": 450↓]
}
```

```swift
    _ = [
        1,
        2,
        3,
        4,
        5, 6,
        7, 8, 9↓]
```

```swift
    _ = [↓1, 2, 3,
         4, 5, 6,
         7, 8, 9
    ]
```

</details>



## Multiline Parameters

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`multiline_parameters` | Disabled | No | style | No | 3.0.0 

Functions and methods parameters should be either on the same line, or one per line.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
func foo() { }
```

```swift
func foo(param1: Int) { }
```

```swift
func foo(param1: Int, param2: Bool) { }
```

```swift
func foo(param1: Int, param2: Bool, param3: [String]) { }
```

```swift
func foo(param1: Int,
         param2: Bool,
         param3: [String]) { }
```

```swift
func foo(_ param1: Int, param2: Int, param3: Int) -> (Int) -> Int {
   return { x in x + param1 + param2 + param3 }
}
```

```swift
static func foo() { }
```

```swift
static func foo(param1: Int) { }
```

```swift
static func foo(param1: Int, param2: Bool) { }
```

```swift
static func foo(param1: Int, param2: Bool, param3: [String]) { }
```

```swift
static func foo(param1: Int,
                param2: Bool,
                param3: [String]) { }
```

```swift
protocol Foo {
	func foo() { }
}
```

```swift
protocol Foo {
	func foo(param1: Int) { }
}
```

```swift
protocol Foo {
	func foo(param1: Int, param2: Bool) { }
}
```

```swift
protocol Foo {
	func foo(param1: Int, param2: Bool, param3: [String]) { }
}
```

```swift
protocol Foo {
   func foo(param1: Int,
            param2: Bool,
            param3: [String]) { }
}
```

```swift
protocol Foo {
	static func foo(param1: Int, param2: Bool, param3: [String]) { }
}
```

```swift
protocol Foo {
   static func foo(param1: Int,
                   param2: Bool,
                   param3: [String]) { }
}
```

```swift
protocol Foo {
	class func foo(param1: Int, param2: Bool, param3: [String]) { }
}
```

```swift
protocol Foo {
   class func foo(param1: Int,
                  param2: Bool,
                  param3: [String]) { }
}
```

```swift
enum Foo {
	func foo() { }
}
```

```swift
enum Foo {
	func foo(param1: Int) { }
}
```

```swift
enum Foo {
	func foo(param1: Int, param2: Bool) { }
}
```

```swift
enum Foo {
	func foo(param1: Int, param2: Bool, param3: [String]) { }
}
```

```swift
enum Foo {
   func foo(param1: Int,
            param2: Bool,
            param3: [String]) { }
}
```

```swift
enum Foo {
	static func foo(param1: Int, param2: Bool, param3: [String]) { }
}
```

```swift
enum Foo {
   static func foo(param1: Int,
                   param2: Bool,
                   param3: [String]) { }
}
```

```swift
struct Foo {
	func foo() { }
}
```

```swift
struct Foo {
	func foo(param1: Int) { }
}
```

```swift
struct Foo {
	func foo(param1: Int, param2: Bool) { }
}
```

```swift
struct Foo {
	func foo(param1: Int, param2: Bool, param3: [String]) { }
}
```

```swift
struct Foo {
   func foo(param1: Int,
            param2: Bool,
            param3: [String]) { }
}
```

```swift
struct Foo {
	static func foo(param1: Int, param2: Bool, param3: [String]) { }
}
```

```swift
struct Foo {
   static func foo(param1: Int,
                   param2: Bool,
                   param3: [String]) { }
}
```

```swift
class Foo {
	func foo() { }
}
```

```swift
class Foo {
	func foo(param1: Int) { }
}
```

```swift
class Foo {
	func foo(param1: Int, param2: Bool) { }
}
```

```swift
class Foo {
	func foo(param1: Int, param2: Bool, param3: [String]) { }
	}
```

```swift
class Foo {
   func foo(param1: Int,
            param2: Bool,
            param3: [String]) { }
}
```

```swift
class Foo {
	class func foo(param1: Int, param2: Bool, param3: [String]) { }
}
```

```swift
class Foo {
   class func foo(param1: Int,
                  param2: Bool,
                  param3: [String]) { }
}
```

```swift
class Foo {
   class func foo(param1: Int,
                  param2: Bool,
                  param3: @escaping (Int, Int) -> Void = { _, _ in }) { }
}
```

```swift
class Foo {
   class func foo(param1: Int,
                  param2: Bool,
                  param3: @escaping (Int) -> Void = { _ in }) { }
}
```

```swift
class Foo {
   class func foo(param1: Int,
                  param2: Bool,
                  param3: @escaping ((Int) -> Void)? = nil) { }
}
```

```swift
class Foo {
   class func foo(param1: Int,
                  param2: Bool,
                  param3: @escaping ((Int) -> Void)? = { _ in }) { }
}
```

```swift
class Foo {
   class func foo(param1: Int,
                  param2: @escaping ((Int) -> Void)? = { _ in },
                  param3: Bool) { }
}
```

```swift
class Foo {
   class func foo(param1: Int,
                  param2: @escaping ((Int) -> Void)? = { _ in },
                  param3: @escaping (Int, Int) -> Void = { _, _ in }) { }
}
```

```swift
class Foo {
   class func foo(param1: Int,
                  param2: Bool,
                  param3: @escaping (Int) -> Void = { (x: Int) in }) { }
}
```

```swift
class Foo {
   class func foo(param1: Int,
                  param2: Bool,
                  param3: @escaping (Int, (Int) -> Void) -> Void = { (x: Int, f: (Int) -> Void) in }) { }
}
```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
func ↓foo(_ param1: Int,
          param2: Int, param3: Int) -> (Int) -> Int {
   return { x in x + param1 + param2 + param3 }
}
```

```swift
protocol Foo {
   func ↓foo(param1: Int,
             param2: Bool, param3: [String]) { }
}
```

```swift
protocol Foo {
   func ↓foo(param1: Int, param2: Bool,
             param3: [String]) { }
}
```

```swift
protocol Foo {
   static func ↓foo(param1: Int,
                    param2: Bool, param3: [String]) { }
}
```

```swift
protocol Foo {
   static func ↓foo(param1: Int, param2: Bool,
                    param3: [String]) { }
}
```

```swift
protocol Foo {
   class func ↓foo(param1: Int,
                   param2: Bool, param3: [String]) { }
}
```

```swift
protocol Foo {
   class func ↓foo(param1: Int, param2: Bool,
                   param3: [String]) { }
}
```

```swift
enum Foo {
   func ↓foo(param1: Int,
             param2: Bool, param3: [String]) { }
}
```

```swift
enum Foo {
   func ↓foo(param1: Int, param2: Bool,
             param3: [String]) { }
}
```

```swift
enum Foo {
   static func ↓foo(param1: Int,
                    param2: Bool, param3: [String]) { }
}
```

```swift
enum Foo {
   static func ↓foo(param1: Int, param2: Bool,
                    param3: [String]) { }
}
```

```swift
struct Foo {
   func ↓foo(param1: Int,
             param2: Bool, param3: [String]) { }
}
```

```swift
struct Foo {
   func ↓foo(param1: Int, param2: Bool,
             param3: [String]) { }
}
```

```swift
struct Foo {
   static func ↓foo(param1: Int,
                    param2: Bool, param3: [String]) { }
}
```

```swift
struct Foo {
   static func ↓foo(param1: Int, param2: Bool,
                    param3: [String]) { }
}
```

```swift
class Foo {
   func ↓foo(param1: Int,
             param2: Bool, param3: [String]) { }
}
```

```swift
class Foo {
   func ↓foo(param1: Int, param2: Bool,
             param3: [String]) { }
}
```

```swift
class Foo {
   class func ↓foo(param1: Int,
                   param2: Bool, param3: [String]) { }
}
```

```swift
class Foo {
   class func ↓foo(param1: Int, param2: Bool,
                   param3: [String]) { }
}
```

```swift
class Foo {
   class func ↓foo(param1: Int,
                  param2: Bool, param3: @escaping (Int, Int) -> Void = { _, _ in }) { }
}
```

```swift
class Foo {
   class func ↓foo(param1: Int,
                  param2: Bool, param3: @escaping (Int) -> Void = { (x: Int) in }) { }
}
```

</details>



## Multiline Parameters Brackets

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`multiline_parameters_brackets` | Disabled | No | style | No | 3.0.0 

Multiline parameters should have their surrounding brackets in a new line.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
func foo(param1: String, param2: String, param3: String)
```

```swift
func foo(
    param1: String, param2: String, param3: String
)
```

```swift
func foo(
    param1: String,
    param2: String,
    param3: String
)
```

```swift
class SomeType {
    func foo(param1: String, param2: String, param3: String)
}
```

```swift
class SomeType {
    func foo(
        param1: String, param2: String, param3: String
    )
}
```

```swift
class SomeType {
    func foo(
        param1: String,
        param2: String,
        param3: String
    )
}
```

```swift
func foo<T>(param1: T, param2: String, param3: String) -> T { /* some code */ }
```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
func foo(↓param1: String, param2: String,
         param3: String
)
```

```swift
func foo(
    param1: String,
    param2: String,
    param3: String↓)
```

```swift
class SomeType {
    func foo(↓param1: String, param2: String,
             param3: String
    )
}
```

```swift
class SomeType {
    func foo(
        param1: String,
        param2: String,
        param3: String↓)
}
```

```swift
func foo<T>(↓param1: T, param2: String,
         param3: String
) -> T
```

</details>



## Multiple Closures with Trailing Closure

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`multiple_closures_with_trailing_closure` | Enabled | No | style | No | 3.0.0 

Trailing closure syntax should not be used when passing more than one closure argument.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
foo.map { $0 + 1 }

```

```swift
foo.reduce(0) { $0 + $1 }

```

```swift
if let foo = bar.map({ $0 + 1 }) {

}

```

```swift
foo.something(param1: { $0 }, param2: { $0 + 1 })

```

```swift
UIView.animate(withDuration: 1.0) {
    someView.alpha = 0.0
}
```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
foo.something(param1: { $0 }) ↓{ $0 + 1 }
```

```swift
UIView.animate(withDuration: 1.0, animations: {
    someView.alpha = 0.0
}) ↓{ _ in
    someView.removeFromSuperview()
}
```

</details>



## Nesting

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`nesting` | Enabled | No | metrics | No | 3.0.0 

Types should be nested at most 1 level deep, and statements should be nested at most 5 levels deep.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
class Class0 { class Class1 {} }

```

```swift
func func0() {
func func1() {
func func2() {
func func3() {
func func4() { func func5() {
}
}
}
}
}
}

```

```swift
struct Class0 { struct Class1 {} }

```

```swift
func func0() {
func func1() {
func func2() {
func func3() {
func func4() { func func5() {
}
}
}
}
}
}

```

```swift
enum Class0 { enum Class1 {} }

```

```swift
func func0() {
func func1() {
func func2() {
func func3() {
func func4() { func func5() {
}
}
}
}
}
}

```

```swift
enum Enum0 { enum Enum1 { case Case } }
```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
class A { class B { ↓class C {} } }

```

```swift
struct A { struct B { ↓struct C {} } }

```

```swift
enum A { enum B { ↓enum C {} } }

```

```swift
func func0() {
func func1() {
func func2() {
func func3() {
func func4() { func func5() {
↓func func6() {
}
}
}
}
}
}
}

```

</details>



## Nimble Operator

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`nimble_operator` | Disabled | Yes | idiomatic | No | 3.0.0 

Prefer Nimble operator overloads over free matcher functions.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
expect(seagull.squawk) != "Hi!"

```

```swift
expect("Hi!") == "Hi!"

```

```swift
expect(10) > 2

```

```swift
expect(10) >= 10

```

```swift
expect(10) < 11

```

```swift
expect(10) <= 10

```

```swift
expect(x) === x
```

```swift
expect(10) == 10
```

```swift
expect(success) == true
```

```swift
expect(object.asyncFunction()).toEventually(equal(1))

```

```swift
expect(actual).to(haveCount(expected))

```

```swift
foo.method {
    expect(value).to(equal(expectedValue), description: "Failed")
    return Bar(value: ())
}
```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
↓expect(seagull.squawk).toNot(equal("Hi"))

```

```swift
↓expect(12).toNot(equal(10))

```

```swift
↓expect(10).to(equal(10))

```

```swift
↓expect(10, line: 1).to(equal(10))

```

```swift
↓expect(10).to(beGreaterThan(8))

```

```swift
↓expect(10).to(beGreaterThanOrEqualTo(10))

```

```swift
↓expect(10).to(beLessThan(11))

```

```swift
↓expect(10).to(beLessThanOrEqualTo(10))

```

```swift
↓expect(x).to(beIdenticalTo(x))

```

```swift
↓expect(success).to(beTrue())

```

```swift
↓expect(success).to(beFalse())

```

```swift
expect(10) > 2
 ↓expect(10).to(beGreaterThan(2))

```

</details>



## No Extension Access Modifier

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`no_extension_access_modifier` | Disabled | No | idiomatic | No | 3.0.0 

Prefer not to use extension access modifiers

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
extension String {}
```

```swift


 extension String {}
```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
↓private extension String {}
```

```swift
↓public 
 extension String {}
```

```swift
↓open extension String {}
```

```swift
↓internal extension String {}
```

```swift
↓fileprivate extension String {}
```

</details>



## No Fallthrough Only

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`no_fallthrough_only` | Enabled | No | idiomatic | No | 3.0.0 

Fallthroughs can only be used if the `case` contains at least one other statement.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
switch myvar {
case 1:
    var a = 1
    fallthrough
case 2:
    var a = 2
}
```

```swift
switch myvar {
case "a":
    var one = 1
    var two = 2
    fallthrough
case "b": /* comment */
    var three = 3
}
```

```swift
switch myvar {
case 1:
    let one = 1
case 2:
    // comment
    var two = 2
}
```

```swift
switch myvar {
case MyFunc(x: [1, 2, YourFunc(a: 23)], y: 2):
    var three = 3
    fallthrough
default:
    var three = 4
}
```

```swift
switch myvar {
case .alpha:
    var one = 1
case .beta:
    var three = 3
    fallthrough
default:
    var four = 4
}
```

```swift
let aPoint = (1, -1)
switch aPoint {
case let (x, y) where x == y:
    let A = "A"
case let (x, y) where x == -y:
    let B = "B"
    fallthrough
default:
    let C = "C"
}
```

```swift
switch myvar {
case MyFun(with: { $1 }):
    let one = 1
    fallthrough
case "abc":
    let two = 2
}
```

```swift
switch enumInstance {
case .caseA:
    print("it's a")
case .caseB:
    fallthrough
@unknown default:
    print("it's not a")
}
```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
switch myvar {
case 1:
    ↓fallthrough
case 2:
    var a = 1
}
```

```swift
switch myvar {
case 1:
    var a = 2
case 2:
    ↓fallthrough
case 3:
    var a = 3
}
```

```swift
switch myvar {
case 1: // comment
    ↓fallthrough
}
```

```swift
switch myvar {
case 1: /* multi
    line
    comment */
    ↓fallthrough
case 2:
    var a = 2
}
```

```swift
switch myvar {
case MyFunc(x: [1, 2, YourFunc(a: 23)], y: 2):
    ↓fallthrough
default:
    var three = 4
}
```

```swift
switch myvar {
case .alpha:
    var one = 1
case .beta:
    ↓fallthrough
case .gamma:
    var three = 3
default:
    var four = 4
}
```

```swift
let aPoint = (1, -1)
switch aPoint {
case let (x, y) where x == y:
    let A = "A"
case let (x, y) where x == -y:
    ↓fallthrough
default:
    let B = "B"
}
```

```swift
switch myvar {
case MyFun(with: { $1 }):
    ↓fallthrough
case "abc":
    let two = 2
}
```

</details>



## No Grouping Extension

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`no_grouping_extension` | Disabled | No | idiomatic | No | 3.0.0 

Extensions shouldn't be used to group code within the same source file.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
protocol Food {}
extension Food {}

```

```swift
class Apples {}
extension Oranges {}

```

```swift
class Box<T> {}
extension Box where T: Vegetable {}

```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
enum Fruit {}
↓extension Fruit {}

```

```swift
↓extension Tea: Error {}
struct Tea {}

```

```swift
class Ham { class Spam {}}
↓extension Ham.Spam {}

```

```swift
extension External { struct Gotcha {}}
↓extension External.Gotcha {}

```

</details>



## Notification Center Detachment

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`notification_center_detachment` | Enabled | No | lint | No | 3.0.0 

An object should only remove itself as an observer in `deinit`.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
class Foo { 
   deinit {
       NotificationCenter.default.removeObserver(self)
   }
}

```

```swift
class Foo { 
   func bar() {
       NotificationCenter.default.removeObserver(otherObject)
   }
}

```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
class Foo { 
   func bar() {
       ↓NotificationCenter.default.removeObserver(self)
   }
}

```

</details>



## NSLocalizedString Key

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`nslocalizedstring_key` | Disabled | No | lint | No | 3.0.0 

Static strings should be used as key in NSLocalizedString in order to genstrings work.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
NSLocalizedString("key", comment: nil)
```

```swift
NSLocalizedString("key" + "2", comment: nil)
```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
NSLocalizedString(↓method(), comment: nil)
```

```swift
NSLocalizedString(↓"key_\(param)", comment: nil)
```

</details>



## NSLocalizedString Require Bundle

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`nslocalizedstring_require_bundle` | Disabled | No | lint | No | 3.0.0 

Calls to NSLocalizedString should specify the bundle which contains the strings file.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
NSLocalizedString("someKey", bundle: .main, comment: "test")
```

```swift
NSLocalizedString("someKey", tableName: "a",
                  bundle: Bundle(for: A.self),
                  comment: "test")
```

```swift
NSLocalizedString("someKey", tableName: "xyz",
                  bundle: someBundle, value: "test"
                  comment: "test")
```

```swift
arbitraryFunctionCall("something")
```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
↓NSLocalizedString("someKey", comment: "test")
```

```swift
↓NSLocalizedString("someKey", tableName: "a", comment: "test")
```

```swift
↓NSLocalizedString("someKey", tableName: "xyz",
                  value: "test", comment: "test")
```

</details>



## NSObject Prefer isEqual

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`nsobject_prefer_isequal` | Enabled | No | lint | No | 3.0.0 

NSObject subclasses should implement isEqual instead of ==.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
class AClass: NSObject {
}
```

```swift
@objc class AClass: SomeNSObjectSubclass {
}
```

```swift
class AClass: Equatable {
    static func ==(lhs: AClass, rhs: AClass) -> Bool {
        return true
    }
```

```swift
class AClass: NSObject {
    override func isEqual(_ object: Any?) -> Bool {
        return true
    }
}
```

```swift
@objc class AClass: SomeNSObjectSubclass {
    override func isEqual(_ object: Any?) -> Bool {
        return false
    }
}
```

```swift
class AClass: NSObject {
    func ==(lhs: AClass, rhs: AClass) -> Bool {
        return true
    }
}
```

```swift
class AClass: NSObject {
    static func ==(lhs: AClass, rhs: BClass) -> Bool {
        return true
    }
}
```

```swift
struct AStruct: Equatable {
    static func ==(lhs: AStruct, rhs: AStruct) -> Bool {
        return false
    }
}
```

```swift
enum AnEnum: Equatable {
    static func ==(lhs: AnEnum, rhs: AnEnum) -> Bool {
        return true
    }
}
```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
class AClass: NSObject {
    ↓static func ==(lhs: AClass, rhs: AClass) -> Bool {
        return false
    }
}
```

```swift
@objc class AClass: SomeOtherNSObjectSubclass {
    ↓static func ==(lhs: AClass, rhs: AClass) -> Bool {
        return true
    }
}
```

```swift
class AClass: NSObject, Equatable {
    ↓static func ==(lhs: AClass, rhs: AClass) -> Bool {
        return false
    }
}
```

```swift
class AClass: NSObject {
    override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? AClass else {
            return false
        }
        return true
    }

    ↓static func ==(lhs: AClass, rhs: AClass) -> Bool {
        return false
    }
}
```

</details>



## Number Separator

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`number_separator` | Disabled | Yes | style | No | 3.0.0 

Underscores should be used as thousand separator in large decimal numbers.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
let foo = -100
```

```swift
let foo = -1_000
```

```swift
let foo = -1_000_000
```

```swift
let foo = -1.000_1
```

```swift
let foo = -1_000_000.000_000_1
```

```swift
let binary = -0b10000
```

```swift
let binary = -0b1000_0001
```

```swift
let hex = -0xA
```

```swift
let hex = -0xAA_BB
```

```swift
let octal = -0o21
```

```swift
let octal = -0o21_1
```

```swift
let exp = -1_000_000.000_000e2
```

```swift
let foo: Double = -(200)
```

```swift
let foo: Double = -(200 / 447.214)
```

```swift
let foo = +100
```

```swift
let foo = +1_000
```

```swift
let foo = +1_000_000
```

```swift
let foo = +1.000_1
```

```swift
let foo = +1_000_000.000_000_1
```

```swift
let binary = +0b10000
```

```swift
let binary = +0b1000_0001
```

```swift
let hex = +0xA
```

```swift
let hex = +0xAA_BB
```

```swift
let octal = +0o21
```

```swift
let octal = +0o21_1
```

```swift
let exp = +1_000_000.000_000e2
```

```swift
let foo: Double = +(200)
```

```swift
let foo: Double = +(200 / 447.214)
```

```swift
let foo = 100
```

```swift
let foo = 1_000
```

```swift
let foo = 1_000_000
```

```swift
let foo = 1.000_1
```

```swift
let foo = 1_000_000.000_000_1
```

```swift
let binary = 0b10000
```

```swift
let binary = 0b1000_0001
```

```swift
let hex = 0xA
```

```swift
let hex = 0xAA_BB
```

```swift
let octal = 0o21
```

```swift
let octal = 0o21_1
```

```swift
let exp = 1_000_000.000_000e2
```

```swift
let foo: Double = (200)
```

```swift
let foo: Double = (200 / 447.214)
```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
let foo = ↓-10_0
```

```swift
let foo = ↓-1000
```

```swift
let foo = ↓-1000e2
```

```swift
let foo = ↓-1000E2
```

```swift
let foo = ↓-1__000
```

```swift
let foo = ↓-1.0001
```

```swift
let foo = ↓-1_000_000.000000_1
```

```swift
let foo = ↓-1000000.000000_1
```

```swift
let foo = +↓10_0
```

```swift
let foo = +↓1000
```

```swift
let foo = +↓1000e2
```

```swift
let foo = +↓1000E2
```

```swift
let foo = +↓1__000
```

```swift
let foo = +↓1.0001
```

```swift
let foo = +↓1_000_000.000000_1
```

```swift
let foo = +↓1000000.000000_1
```

```swift
let foo = ↓10_0
```

```swift
let foo = ↓1000
```

```swift
let foo = ↓1000e2
```

```swift
let foo = ↓1000E2
```

```swift
let foo = ↓1__000
```

```swift
let foo = ↓1.0001
```

```swift
let foo = ↓1_000_000.000000_1
```

```swift
let foo = ↓1000000.000000_1
```

```swift
let foo: Double = ↓-(100000)
```

```swift
let foo: Double = ↓-(10.000000_1)
```

```swift
let foo: Double = ↓-(123456 / ↓447.214214)
```

```swift
let foo: Double = +(↓100000)
```

```swift
let foo: Double = +(↓10.000000_1)
```

```swift
let foo: Double = +(↓123456 / ↓447.214214)
```

```swift
let foo: Double = (↓100000)
```

```swift
let foo: Double = (↓10.000000_1)
```

```swift
let foo: Double = (↓123456 / ↓447.214214)
```

</details>



## Object Literal

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`object_literal` | Disabled | No | idiomatic | No | 3.0.0 

Prefer object literals over image and color inits.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
let image = #imageLiteral(resourceName: "image.jpg")
```

```swift
let color = #colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)
```

```swift
let image = UIImage(named: aVariable)
```

```swift
let image = UIImage(named: "interpolated \(variable)")
```

```swift
let color = UIColor(red: value, green: value, blue: value, alpha: 1)
```

```swift
let image = NSImage(named: aVariable)
```

```swift
let image = NSImage(named: "interpolated \(variable)")
```

```swift
let color = NSColor(red: value, green: value, blue: value, alpha: 1)
```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
let image = ↓UIImage(named: "foo")
```

```swift
let color = ↓UIColor(red: 0.3, green: 0.3, blue: 0.3, alpha: 1)
```

```swift
let color = ↓UIColor(red: 100 / 255.0, green: 50 / 255.0, blue: 0, alpha: 1)
```

```swift
let color = ↓UIColor(white: 0.5, alpha: 1)
```

```swift
let image = ↓NSImage(named: "foo")
```

```swift
let color = ↓NSColor(red: 0.3, green: 0.3, blue: 0.3, alpha: 1)
```

```swift
let color = ↓NSColor(red: 100 / 255.0, green: 50 / 255.0, blue: 0, alpha: 1)
```

```swift
let color = ↓NSColor(white: 0.5, alpha: 1)
```

```swift
let image = ↓UIImage.init(named: "foo")
```

```swift
let color = ↓UIColor.init(red: 0.3, green: 0.3, blue: 0.3, alpha: 1)
```

```swift
let color = ↓UIColor.init(red: 100 / 255.0, green: 50 / 255.0, blue: 0, alpha: 1)
```

```swift
let color = ↓UIColor.init(white: 0.5, alpha: 1)
```

```swift
let image = ↓NSImage.init(named: "foo")
```

```swift
let color = ↓NSColor.init(red: 0.3, green: 0.3, blue: 0.3, alpha: 1)
```

```swift
let color = ↓NSColor.init(red: 100 / 255.0, green: 50 / 255.0, blue: 0, alpha: 1)
```

```swift
let color = ↓NSColor.init(white: 0.5, alpha: 1)
```

</details>



## Opening Brace Spacing

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`opening_brace` | Enabled | Yes | style | No | 3.0.0 

Opening braces should be preceded by a single space and on the same line as the declaration.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
func abc() {
}
```

```swift
[].map() { $0 }
```

```swift
[].map({ })
```

```swift
if let a = b { }
```

```swift
while a == b { }
```

```swift
guard let a = b else { }
```

```swift
if
	let a = b,
	let c = d
	where a == c
{ }
```

```swift
while
	let a = b,
	let c = d
	where a == c
{ }
```

```swift
guard
	let a = b,
	let c = d
	where a == c else
{ }
```

```swift
struct Rule {}

```

```swift
struct Parent {
	struct Child {
		let foo: Int
	}
}

```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
func abc()↓{
}
```

```swift
func abc()
	↓{ }
```

```swift
[].map()↓{ $0 }
```

```swift
[].map( ↓{ } )
```

```swift
if let a = b↓{ }
```

```swift
while a == b↓{ }
```

```swift
guard let a = b else↓{ }
```

```swift
if
	let a = b,
	let c = d
	where a == c↓{ }
```

```swift
while
	let a = b,
	let c = d
	where a == c↓{ }
```

```swift
guard
	let a = b,
	let c = d
	where a == c else↓{ }
```

```swift
struct Rule↓{}

```

```swift
struct Rule
↓{
}

```

```swift
struct Rule

	↓{
}

```

```swift
struct Parent {
	struct Child
	↓{
		let foo: Int
	}
}

```

</details>



## Operator Usage Whitespace

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`operator_usage_whitespace` | Disabled | Yes | style | No | 3.0.0 

Operators should be surrounded by a single whitespace when they are being used.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
let foo = 1 + 2

```

```swift
let foo = 1 > 2

```

```swift
let foo = !false

```

```swift
let foo: Int?

```

```swift
let foo: Array<String>

```

```swift
let model = CustomView<Container<Button>, NSAttributedString>()

```

```swift
let foo: [String]

```

```swift
let foo = 1 + 
  2

```

```swift
let range = 1...3

```

```swift
let range = 1 ... 3

```

```swift
let range = 1..<3

```

```swift
#if swift(>=3.0)
    foo()
#endif

```

```swift
array.removeAtIndex(-200)

```

```swift
let name = "image-1"

```

```swift
button.setImage(#imageLiteral(resourceName: "image-1"), for: .normal)

```

```swift
let doubleValue = -9e-11

```

```swift
let foo = GenericType<(UIViewController) -> Void>()

```

```swift
let foo = Foo<Bar<T>, Baz>()

```

```swift
let foo = SignalProducer<Signal<Value, Error>, Error>([ self.signal, next ]).flatten(.concat)

```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
let foo = 1↓+2

```

```swift
let foo = 1↓   + 2

```

```swift
let foo = 1↓   +    2

```

```swift
let foo = 1↓ +    2

```

```swift
let foo↓=1↓+2

```

```swift
let foo↓=1 + 2

```

```swift
let foo↓=bar

```

```swift
let range = 1↓ ..<  3

```

```swift
let foo = bar↓   ?? 0

```

```swift
let foo = bar↓??0

```

```swift
let foo = bar↓ !=  0

```

```swift
let foo = bar↓ !==  bar2

```

```swift
let v8 = Int8(1)↓  << 6

```

```swift
let v8 = 1↓ <<  (6)

```

```swift
let v8 = 1↓ <<  (6)
 let foo = 1 > 2

```

</details>



## Operator Function Whitespace

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`operator_whitespace` | Enabled | No | style | No | 3.0.0 

Operators should be surrounded by a single whitespace when defining them.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
func <| (lhs: Int, rhs: Int) -> Int {}

```

```swift
func <|< <A>(lhs: A, rhs: A) -> A {}

```

```swift
func abc(lhs: Int, rhs: Int) -> Int {}

```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
↓func <|(lhs: Int, rhs: Int) -> Int {}

```

```swift
↓func <|<<A>(lhs: A, rhs: A) -> A {}

```

```swift
↓func <|  (lhs: Int, rhs: Int) -> Int {}

```

```swift
↓func <|<  <A>(lhs: A, rhs: A) -> A {}

```

```swift
↓func  <| (lhs: Int, rhs: Int) -> Int {}

```

```swift
↓func  <|< <A>(lhs: A, rhs: A) -> A {}

```

</details>



## Overridden methods call super

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`overridden_super_call` | Disabled | No | lint | No | 3.0.0 

Some overridden methods should always call super

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
class VC: UIViewController {
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
	}
}

```

```swift
class VC: UIViewController {
	override func viewWillAppear(_ animated: Bool) {
		self.method1()
		super.viewWillAppear(animated)
		self.method2()
	}
}

```

```swift
class VC: UIViewController {
	override func loadView() {
	}
}

```

```swift
class Some {
	func viewWillAppear(_ animated: Bool) {
	}
}

```

```swift
class VC: UIViewController {
	override func viewDidLoad() {
		defer {
			super.viewDidLoad()
		}
	}
}

```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
class VC: UIViewController {
	override func viewWillAppear(_ animated: Bool) {↓
		//Not calling to super
		self.method()
	}
}

```

```swift
class VC: UIViewController {
	override func viewWillAppear(_ animated: Bool) {↓
		super.viewWillAppear(animated)
		//Other code
		super.viewWillAppear(animated)
	}
}

```

```swift
class VC: UIViewController {
	override func didReceiveMemoryWarning() {↓
	}
}

```

</details>



## Override in Extension

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`override_in_extension` | Disabled | No | lint | No | 3.0.0 

Extensions shouldn't override declarations.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
extension Person {
  var age: Int { return 42 }
}

```

```swift
extension Person {
  func celebrateBirthday() {}
}

```

```swift
class Employee: Person {
  override func celebrateBirthday() {}
}

```

```swift
class Foo: NSObject {}
extension Foo {
    override var description: String { return "" }
}

```

```swift
struct Foo {
    class Bar: NSObject {}
}
extension Foo.Bar {
    override var description: String { return "" }
}

```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
extension Person {
  override ↓var age: Int { return 42 }
}

```

```swift
extension Person {
  override ↓func celebrateBirthday() {}
}

```

</details>



## Pattern Matching Keywords

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`pattern_matching_keywords` | Disabled | No | idiomatic | No | 3.0.0 

Combine multiple pattern matching bindings by moving keywords out of tuples.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
switch foo {
    default: break
}
```

```swift
switch foo {
    case 1: break
}
```

```swift
switch foo {
    case bar: break
}
```

```swift
switch foo {
    case let (x, y): break
}
```

```swift
switch foo {
    case .foo(let x): break
}
```

```swift
switch foo {
    case let .foo(x, y): break
}
```

```swift
switch foo {
    case .foo(let x), .bar(let x): break
}
```

```swift
switch foo {
    case .foo(let x, var y): break
}
```

```swift
switch foo {
    case var (x, y): break
}
```

```swift
switch foo {
    case .foo(var x): break
}
```

```swift
switch foo {
    case var .foo(x, y): break
}
```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
switch foo {
    case (↓let x,  ↓let y): break
}
```

```swift
switch foo {
    case .foo(↓let x, ↓let y): break
}
```

```swift
switch foo {
    case (.yamlParsing(↓let x), .yamlParsing(↓let y)): break
}
```

```swift
switch foo {
    case (↓var x,  ↓var y): break
}
```

```swift
switch foo {
    case .foo(↓var x, ↓var y): break
}
```

```swift
switch foo {
    case (.yamlParsing(↓var x), .yamlParsing(↓var y)): break
}
```

</details>



## Prefixed Top-Level Constant

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`prefixed_toplevel_constant` | Disabled | No | style | No | 3.0.0 

Top-level constants should be prefixed by `k`.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
private let kFoo = 20.0
```

```swift
public let kFoo = false
```

```swift
internal let kFoo = "Foo"
```

```swift
let kFoo = true
```

```swift
struct Foo {
   let bar = 20.0
}
```

```swift
private var foo = 20.0
```

```swift
public var foo = false
```

```swift
internal var foo = "Foo"
```

```swift
var foo = true
```

```swift
var foo = true, bar = true
```

```swift
var foo = true, let kFoo = true
```

```swift
let
   kFoo = true
```

```swift
var foo: Int {
   return a + b
}
```

```swift
let kFoo = {
   return a + b
}()
```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
private let ↓Foo = 20.0
```

```swift
public let ↓Foo = false
```

```swift
internal let ↓Foo = "Foo"
```

```swift
let ↓Foo = true
```

```swift
let ↓foo = 2, ↓bar = true
```

```swift
var foo = true, let ↓Foo = true
```

```swift
let
    ↓foo = true
```

```swift
let ↓foo = {
   return a + b
}()
```

</details>



## Private Actions

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`private_action` | Disabled | No | lint | No | 3.0.0 

IBActions should be private.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
class Foo {
	@IBAction private func barButtonTapped(_ sender: UIButton) {}
}

```

```swift
struct Foo {
	@IBAction private func barButtonTapped(_ sender: UIButton) {}
}

```

```swift
class Foo {
	@IBAction fileprivate func barButtonTapped(_ sender: UIButton) {}
}

```

```swift
struct Foo {
	@IBAction fileprivate func barButtonTapped(_ sender: UIButton) {}
}

```

```swift
private extension Foo {
	@IBAction func barButtonTapped(_ sender: UIButton) {}
}

```

```swift
fileprivate extension Foo {
	@IBAction func barButtonTapped(_ sender: UIButton) {}
}

```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
class Foo {
	@IBAction ↓func barButtonTapped(_ sender: UIButton) {}
}

```

```swift
struct Foo {
	@IBAction ↓func barButtonTapped(_ sender: UIButton) {}
}

```

```swift
class Foo {
	@IBAction public ↓func barButtonTapped(_ sender: UIButton) {}
}

```

```swift
struct Foo {
	@IBAction public ↓func barButtonTapped(_ sender: UIButton) {}
}

```

```swift
class Foo {
	@IBAction internal ↓func barButtonTapped(_ sender: UIButton) {}
}

```

```swift
struct Foo {
	@IBAction internal ↓func barButtonTapped(_ sender: UIButton) {}
}

```

```swift
extension Foo {
	@IBAction ↓func barButtonTapped(_ sender: UIButton) {}
}

```

```swift
extension Foo {
	@IBAction public ↓func barButtonTapped(_ sender: UIButton) {}
}

```

```swift
extension Foo {
	@IBAction internal ↓func barButtonTapped(_ sender: UIButton) {}
}

```

```swift
public extension Foo {
	@IBAction ↓func barButtonTapped(_ sender: UIButton) {}
}

```

```swift
internal extension Foo {
	@IBAction ↓func barButtonTapped(_ sender: UIButton) {}
}

```

</details>



## Private Outlets

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`private_outlet` | Disabled | No | lint | No | 3.0.0 

IBOutlets should be private to avoid leaking UIKit to higher layers.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
class Foo {
  @IBOutlet private var label: UILabel?
}

```

```swift
class Foo {
  @IBOutlet private var label: UILabel!
}

```

```swift
class Foo {
  var notAnOutlet: UILabel
}

```

```swift
class Foo {
  @IBOutlet weak private var label: UILabel?
}

```

```swift
class Foo {
  @IBOutlet private weak var label: UILabel?
}

```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
class Foo {
  @IBOutlet ↓var label: UILabel?
}

```

```swift
class Foo {
  @IBOutlet ↓var label: UILabel!
}

```

</details>



## Private over fileprivate

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`private_over_fileprivate` | Enabled | Yes | idiomatic | No | 3.0.0 

Prefer `private` over `fileprivate` declarations.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
extension String {}
```

```swift
private extension String {}
```

```swift
public 
 enum MyEnum {}
```

```swift
open extension 
 String {}
```

```swift
internal extension String {}
```

```swift
extension String {
  fileprivate func Something(){}
}
```

```swift
class MyClass {
  fileprivate let myInt = 4
}
```

```swift
class MyClass {
  fileprivate(set) var myInt = 4
}
```

```swift
struct Outter {
  struct Inter {
    fileprivate struct Inner {}
  }
}
```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
↓fileprivate enum MyEnum {}
```

```swift
↓fileprivate class MyClass {
  fileprivate(set) var myInt = 4
}
```

</details>



## Private Unit Test

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`private_unit_test` | Enabled | No | lint | No | 3.0.0 

Unit tests marked private are silently skipped.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
class FooTest: XCTestCase { func test1() {}
 internal func test2() {}
 public func test3() {}
 }
```

```swift
internal class FooTest: XCTestCase { func test1() {}
 internal func test2() {}
 public func test3() {}
 }
```

```swift
public class FooTest: XCTestCase { func test1() {}
 internal func test2() {}
 public func test3() {}
 }
```

```swift
@objc private class FooTest: XCTestCase { @objc private func test1() {}
 internal func test2() {}
 public func test3() {}
 }
```

```swift
private class Foo: NSObject { func test1() {}
 internal func test2() {}
 public func test3() {}
 }
```

```swift
private class Foo { func test1() {}
 internal func test2() {}
 public func test3() {}
 }
```

```swift
public class FooTest: XCTestCase { func test1(param: Int) {}
 }
```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
private ↓class FooTest: XCTestCase { func test1() {}
 internal func test2() {}
 public func test3() {}
 private func test4() {}
 }
```

```swift
class FooTest: XCTestCase { func test1() {}
 internal func test2() {}
 public func test3() {}
 private ↓func test4() {}
 }
```

```swift
internal class FooTest: XCTestCase { func test1() {}
 internal func test2() {}
 public func test3() {}
 private ↓func test4() {}
 }
```

```swift
public class FooTest: XCTestCase { func test1() {}
 internal func test2() {}
 public func test3() {}
 private ↓func test4() {}
 }
```

</details>



## Prohibited Interface Builder

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`prohibited_interface_builder` | Disabled | No | lint | No | 3.0.0 

Creating views using Interface Builder should be avoided.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
class ViewController: UIViewController {
    var label: UILabel!
}
```

```swift
class ViewController: UIViewController {
    @objc func buttonTapped(_ sender: UIButton) {}
}
```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
class ViewController: UIViewController {
    @IBOutlet ↓var label: UILabel!
}
```

```swift
class ViewController: UIViewController {
    @IBAction ↓func buttonTapped(_ sender: UIButton) {}
}
```

</details>



## Prohibited calls to super

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`prohibited_super_call` | Disabled | No | lint | No | 3.0.0 

Some methods should not call super

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
class VC: UIViewController {
    override func loadView() {
    }
}
```

```swift
class NSView {
    func updateLayer() {
        self.method1()
    }
}
```

```swift
public class FileProviderExtension: NSFileProviderExtension {
    override func providePlaceholder(at url: URL, completionHandler: @escaping (Error?) -> Void) {
        guard let identifier = persistentIdentifierForItem(at: url) else {
            completionHandler(NSFileProviderError(.noSuchItem))
            return
        }
    }
}
```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
class VC: UIViewController {
    override func loadView() {↓
        super.loadView()
    }
}
```

```swift
class VC: NSFileProviderExtension {
    override func providePlaceholder(at url: URL, completionHandler: @escaping (Error?) -> Void) {↓
        self.method1()
        super.providePlaceholder(at:url, completionHandler: completionHandler)
    }
}
```

```swift
class VC: NSView {
    override func updateLayer() {↓
        self.method1()
        super.updateLayer()
        self.method2()
    }
}
```

```swift
class VC: NSView {
    override func updateLayer() {↓
        defer {
            super.updateLayer()
        }
    }
}
```

</details>



## Protocol Property Accessors Order

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`protocol_property_accessors_order` | Enabled | Yes | style | No | 3.0.0 

When declaring properties in protocols, the order of accessors should be `get set`.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
protocol Foo {
 var bar: String { get set }
 }
```

```swift
protocol Foo {
 var bar: String { get }
 }
```

```swift
protocol Foo {
 var bar: String { set }
 }
```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
protocol Foo {
 var bar: String { ↓set get }
 }
```

</details>



## Quick Discouraged Call

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`quick_discouraged_call` | Disabled | No | lint | No | 3.0.0 

Discouraged call inside 'describe' and/or 'context' block.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
class TotoTests: QuickSpec {
   override func spec() {
       describe("foo") {
           beforeEach {
               let foo = Foo()
               foo.toto()
           }
       }
   }
}

```

```swift
class TotoTests: QuickSpec {
   override func spec() {
       describe("foo") {
           beforeEach {
               let foo = Foo()
               foo.toto()
           }
           afterEach {
               let foo = Foo()
               foo.toto()
           }
           describe("bar") {
           }
           context("bar") {
           }
           it("bar") {
               let foo = Foo()
               foo.toto()
           }
       }
   }
}

```

```swift
class TotoTests: QuickSpec {
   override func spec() {
       describe("foo") {
          itBehavesLike("bar")
       }
   }
}

```

```swift
class TotoTests: QuickSpec {
   override func spec() {
       describe("foo") {
           it("does something") {
               let foo = Foo()
               foo.toto()
           }
       }
   }
}

```

```swift
class TotoTests: QuickSpec {
   override func spec() {
       context("foo") {
           afterEach { toto.append(foo) }
       }
   }
}

```

```swift
class TotoTests: QuickSpec {
   override func spec() {
       xcontext("foo") {
           afterEach { toto.append(foo) }
       }
   }
}

```

```swift
class TotoTests: QuickSpec {
   override func spec() {
       xdescribe("foo") {
           afterEach { toto.append(foo) }
       }
   }
}

```

```swift
class TotoTests: QuickSpec {
   override func spec() {
       describe("foo") {
           xit("does something") {
               let foo = Foo()
               foo.toto()
           }
       }
   }
}

```

```swift
class TotoTests: QuickSpec {
   override func spec() {
       fcontext("foo") {
           afterEach { toto.append(foo) }
       }
   }
}

```

```swift
class TotoTests: QuickSpec {
   override func spec() {
       fdescribe("foo") {
           afterEach { toto.append(foo) }
       }
   }
}

```

```swift
class TotoTests: QuickSpec {
   override func spec() {
       describe("foo") {
           fit("does something") {
               let foo = Foo()
               foo.toto()
           }
       }
   }
}

```

```swift
class TotoTests: QuickSpec {
   override func spec() {
       fitBehavesLike("foo")
   }
}

```

```swift
class TotoTests: QuickSpec {
   override func spec() {
       xitBehavesLike("foo")
   }
}

```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
class TotoTests {
   override func spec() {
       describe("foo") {
           let foo = Foo()
       }
   }
}
class TotoTests: QuickSpec {
   override func spec() {
       describe("foo") {
           let foo = ↓Foo()
       }
   }
}

```

```swift
class TotoTests: QuickSpec {
   override func spec() {
       describe("foo") {
           let foo = ↓Foo()
       }
   }
}

```

```swift
class TotoTests: QuickSpec {
   override func spec() {
       describe("foo") {
           context("foo") {
               let foo = ↓Foo()
           }
           context("bar") {
               let foo = ↓Foo()
               ↓foo.bar()
               it("does something") {
                   let foo = Foo()
                   foo.toto()
               }
           }
       }
   }
}

```

```swift
class TotoTests: QuickSpec {
   override func spec() {
       describe("foo") {
           context("foo") {
               context("foo") {
                   beforeEach {
                       let foo = Foo()
                       foo.toto()
                   }
                   it("bar") {
                   }
                   context("foo") {
                       let foo = ↓Foo()
                   }
               }
           }
       }
   }
}

```

```swift
class TotoTests: QuickSpec {
   override func spec() {
       context("foo") {
           let foo = ↓Foo()
       }
   }
}

```

```swift
class TotoTests: QuickSpec {
   override func spec() {
       sharedExamples("foo") {
           let foo = ↓Foo()
       }
   }
}

```

```swift
class TotoTests: QuickSpec {
   override func spec() {
       describe("foo") {
           ↓foo()
       }
   }
}

```

```swift
class TotoTests: QuickSpec {
   override func spec() {
       context("foo") {
           ↓foo()
       }
   }
}

```

```swift
class TotoTests: QuickSpec {
   override func spec() {
       sharedExamples("foo") {
           ↓foo()
       }
   }
}

```

```swift
class TotoTests: QuickSpec {
   override func spec() {
       xdescribe("foo") {
           let foo = ↓Foo()
       }
       fdescribe("foo") {
           let foo = ↓Foo()
       }
   }
}

```

```swift
class TotoTests: QuickSpec {
   override func spec() {
       xcontext("foo") {
           let foo = ↓Foo()
       }
       fcontext("foo") {
           let foo = ↓Foo()
       }
   }
}

```

</details>



## Quick Discouraged Focused Test

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`quick_discouraged_focused_test` | Disabled | No | lint | No | 3.0.0 

Discouraged focused test. Other tests won't run while this one is focused.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
class TotoTests: QuickSpec {
   override func spec() {
       describe("foo") {
           describe("bar") { } 
           context("bar") {
               it("bar") { }
           }
           it("bar") { }
           itBehavesLike("bar")
       }
   }
}

```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
class TotoTests: QuickSpec {
   override func spec() {
       ↓fdescribe("foo") { }
   }
}

```

```swift
class TotoTests: QuickSpec {
   override func spec() {
       ↓fcontext("foo") { }
   }
}

```

```swift
class TotoTests: QuickSpec {
   override func spec() {
       ↓fit("foo") { }
   }
}

```

```swift
class TotoTests: QuickSpec {
   override func spec() {
       describe("foo") {
           ↓fit("bar") { }
       }
   }
}

```

```swift
class TotoTests: QuickSpec {
   override func spec() {
       context("foo") {
           ↓fit("bar") { }
       }
   }
}

```

```swift
class TotoTests: QuickSpec {
   override func spec() {
       describe("foo") {
           context("bar") {
               ↓fit("toto") { }
           }
       }
   }
}

```

```swift
class TotoTests: QuickSpec {
   override func spec() {
       ↓fitBehavesLike("foo")
   }
}

```

</details>



## Quick Discouraged Pending Test

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`quick_discouraged_pending_test` | Disabled | No | lint | No | 3.0.0 

Discouraged pending test. This test won't run while it's marked as pending.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
class TotoTests: QuickSpec {
   override func spec() {
       describe("foo") {
           describe("bar") { } 
           context("bar") {
               it("bar") { }
           }
           it("bar") { }
           itBehavesLike("bar")
       }
   }
}

```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
class TotoTests: QuickSpec {
   override func spec() {
       ↓xdescribe("foo") { }
   }
}

```

```swift
class TotoTests: QuickSpec {
   override func spec() {
       ↓xcontext("foo") { }
   }
}

```

```swift
class TotoTests: QuickSpec {
   override func spec() {
       ↓xit("foo") { }
   }
}

```

```swift
class TotoTests: QuickSpec {
   override func spec() {
       describe("foo") {
           ↓xit("bar") { }
       }
   }
}

```

```swift
class TotoTests: QuickSpec {
   override func spec() {
       context("foo") {
           ↓xit("bar") { }
       }
   }
}

```

```swift
class TotoTests: QuickSpec {
   override func spec() {
       describe("foo") {
           context("bar") {
               ↓xit("toto") { }
           }
       }
   }
}

```

```swift
class TotoTests: QuickSpec {
   override func spec() {
       ↓pending("foo")
   }
}

```

```swift
class TotoTests: QuickSpec {
   override func spec() {
       ↓xitBehavesLike("foo")
   }
}

```

</details>



## Reduce Boolean

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`reduce_boolean` | Enabled | No | performance | No | 4.2.0 

Prefer using `.allSatisfy()` or `.contains()` over `reduce(true)` or `reduce(false)`

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
nums.reduce(0) { $0.0 + $0.1 }
```

```swift
nums.reduce(0.0) { $0.0 + $0.1 }
```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
let allNines = nums.↓reduce(true) { $0.0 && $0.1 == 9 }
```

```swift
let anyNines = nums.↓reduce(false) { $0.0 || $0.1 == 9 }
```

```swift
let allValid = validators.↓reduce(true) { $0 && $1(input) }
```

```swift
let anyValid = validators.↓reduce(false) { $0 || $1(input) }
```

```swift
let allNines = nums.↓reduce(true, { $0.0 && $0.1 == 9 })
```

```swift
let anyNines = nums.↓reduce(false, { $0.0 || $0.1 == 9 })
```

```swift
let allValid = validators.↓reduce(true, { $0 && $1(input) })
```

```swift
let anyValid = validators.↓reduce(false, { $0 || $1(input) })
```

</details>



## Reduce Into

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`reduce_into` | Disabled | No | performance | No | 4.0.0 

Prefer `reduce(into:_:)` over `reduce(_:_:)` for copy-on-write types

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
let foo = values.reduce(into: "abc") { $0 += "\($1)" }
```

```swift
values.reduce(into: Array<Int>()) { result, value in
    result.append(value)
}
```

```swift
let rows = violations.enumerated().reduce(into: "") { rows, indexAndViolation in
    rows.append(generateSingleRow(for: indexAndViolation.1, at: indexAndViolation.0 + 1))
}
```

```swift
zip(group, group.dropFirst()).reduce(into: []) { result, pair in
    result.append(pair.0 + pair.1)
}
```

```swift
let foo = values.reduce(into: [String: Int]()) { result, value in
    result["\(value)"] = value
}
```

```swift
let foo = values.reduce(into: Dictionary<String, Int>.init()) { result, value in
    result["\(value)"] = value
}
```

```swift
let foo = values.reduce(into: [Int](repeating: 0, count: 10)) { result, value in
    result.append(value)
}
```

```swift
let foo = values.reduce(MyClass()) { result, value in
    result.handleValue(value)
    return result
}
```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
let bar = values.↓reduce("abc") { $0 + "\($1)" }
```

```swift
values.↓reduce(Array<Int>()) { result, value in
    result += [value]
}
```

```swift
let rows = violations.enumerated().↓reduce("") { rows, indexAndViolation in
    return rows + generateSingleRow(for: indexAndViolation.1, at: indexAndViolation.0 + 1)
}
```

```swift
zip(group, group.dropFirst()).↓reduce([]) { result, pair in
    result + [pair.0 + pair.1]
}
```

```swift
let foo = values.↓reduce([String: Int]()) { result, value in
    var result = result
    result["\(value)"] = value
    return result
}
```

```swift
let bar = values.↓reduce(Dictionary<String, Int>.init()) { result, value in
    var result = result
    result["\(value)"] = value
    return result
}
```

```swift
let bar = values.↓reduce([Int](repeating: 0, count: 10)) { result, value in
    return result + [value]
}
```

</details>



## Redundant Discardable Let

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`redundant_discardable_let` | Enabled | Yes | style | No | 3.0.0 

Prefer `_ = foo()` over `let _ = foo()` when discarding a result from a function.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
_ = foo()

```

```swift
if let _ = foo() { }

```

```swift
guard let _ = foo() else { return }

```

```swift
let _: ExplicitType = foo()
```

```swift
while let _ = SplashStyle(rawValue: maxValue) { maxValue += 1 }

```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
↓let _ = foo()

```

```swift
if _ = foo() { ↓let _ = bar() }

```

</details>



## Redundant Nil Coalescing

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`redundant_nil_coalescing` | Disabled | Yes | idiomatic | No | 3.0.0 

nil coalescing operator is only evaluated if the lhs is nil, coalescing operator with nil as rhs is redundant

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
var myVar: Int?; myVar ?? 0

```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
var myVar: Int? = nil; myVar↓ ?? nil

```

```swift
var myVar: Int? = nil; myVar↓??nil

```

</details>



## Redundant @objc Attribute

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`redundant_objc_attribute` | Enabled | Yes | idiomatic | No | 4.1.0 

Objective-C attribute (@objc) is redundant in declaration.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
@objc private var foo: String? {}
```

```swift
@IBInspectable private var foo: String? {}
```

```swift
@objc private func foo(_ sender: Any) {}
```

```swift
@IBAction private func foo(_ sender: Any) {}
```

```swift
@GKInspectable private var foo: String! {}
```

```swift
private @GKInspectable var foo: String! {}
```

```swift
@NSManaged var foo: String!
```

```swift
@objc @NSCopying var foo: String!
```

```swift
@objcMembers
class Foo {
    var bar: Any?
    @objc
    class Bar {
        @objc
        var foo: Any?
    }
}
```

```swift
@objc
extension Foo {
    var bar: Int {
        return 0
    }
}
```

```swift
extension Foo {
    @objc
    var bar: Int { return 0 }
}
```

```swift
@objc @IBDesignable
extension Foo {
    var bar: Int { return 0 }
}
```

```swift
@IBDesignable
extension Foo {
    @objc
    var bar: Int { return 0 }
    var fooBar: Int { return 1 }
}
```

```swift
@objcMembers
class Foo: NSObject {
    @objc
    private var bar: Int {
        return 0
    }
}
```

```swift
@objcMembers
class Foo {
    class Bar: NSObject {
        @objc var foo: Any
    }
}
```

```swift
@objcMembers
class Foo {
    @objc class Bar {}
}
```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
↓@objc @IBInspectable private var foo: String? {}
```

```swift
@IBInspectable ↓@objc private var foo: String? {}
```

```swift
↓@objc @IBAction private func foo(_ sender: Any) {}
```

```swift
@IBAction ↓@objc private func foo(_ sender: Any) {}
```

```swift
↓@objc @GKInspectable private var foo: String! {}
```

```swift
@GKInspectable ↓@objc private var foo: String! {}
```

```swift
↓@objc @NSManaged private var foo: String!
```

```swift
@NSManaged ↓@objc private var foo: String!
```

```swift
↓@objc @IBDesignable class Foo {}
```

```swift
@objcMembers
class Foo {
    ↓@objc var bar: Any?
}
```

```swift
@objcMembers
class Foo {
    ↓@objc var bar: Any?
    ↓@objc var foo: Any?
    @objc
    class Bar {
        @objc
        var foo: Any?
    }
}
```

```swift
@objc
extension Foo {
    ↓@objc
    var bar: Int {
        return 0
    }
}
```

```swift
@objc @IBDesignable
extension Foo {
    ↓@objc
    var bar: Int {
        return 0
    }
}
```

```swift
@objcMembers
class Foo {
    @objcMembers
    class Bar: NSObject {
        ↓@objc var foo: Any
    }
}
```

```swift
@objc
extension Foo {
    ↓@objc
    private var bar: Int {
        return 0
    }
}
```

</details>



## Redundant Optional Initialization

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`redundant_optional_initialization` | Enabled | Yes | idiomatic | No | 3.0.0 

Initializing an optional variable with nil is redundant.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
var myVar: Int?

```

```swift
let myVar: Int? = nil

```

```swift
var myVar: Int? = 0

```

```swift
func foo(bar: Int? = 0) { }

```

```swift
var myVar: Optional<Int>

```

```swift
let myVar: Optional<Int> = nil

```

```swift
var myVar: Optional<Int> = 0

```

```swift
var foo: Int? {
  if bar != nil { }
  return 0
}
```

```swift
var foo: Int? = {
  if bar != nil { }
  return 0
}()
```

```swift
lazy var test: Int? = nil
```

```swift
func funcName() {
  var myVar: String?
}
```

```swift
func funcName() {
  let myVar: String? = nil
}
```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
var myVar: Int?↓ = nil

```

```swift
var myVar: Optional<Int>↓ = nil

```

```swift
var myVar: Int?↓=nil

```

```swift
var myVar: Optional<Int>↓=nil

```

```swift
func funcName() {
    var myVar: String?↓ = nil
}
```

</details>



## Redundant Set Access Control Rule

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`redundant_set_access_control` | Enabled | No | idiomatic | No | 4.1.0 

Property setter access level shouldn't be explicit if it's the same as the variable access level.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
private(set) public var foo: Int
```

```swift
public let foo: Int
```

```swift
public var foo: Int
```

```swift
var foo: Int
```

```swift
private final class A {
  private(set) var value: Int
}
```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
↓private(set) private var foo: Int
```

```swift
↓fileprivate(set) fileprivate var foo: Int
```

```swift
↓internal(set) internal var foo: Int
```

```swift
↓public(set) public var foo: Int
```

```swift
open class Foo {
  ↓open(set) open var bar: Int
}
```

```swift
class A {
  ↓internal(set) var value: Int
}
```

```swift
fileprivate class A {
  ↓fileprivate(set) var value: Int
}
```

</details>



## Redundant String Enum Value

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`redundant_string_enum_value` | Enabled | No | idiomatic | No | 3.0.0 

String enum values can be omitted when they are equal to the enumcase name.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
enum Numbers: String {
  case one
  case two
}
```

```swift
enum Numbers: Int {
  case one = 1
  case two = 2
}
```

```swift
enum Numbers: String {
  case one = "ONE"
  case two = "TWO"
}
```

```swift
enum Numbers: String {
  case one = "ONE"
  case two = "two"
}
```

```swift
enum Numbers: String {
  case one, two
}
```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
enum Numbers: String {
  case one = ↓"one"
  case two = ↓"two"
}
```

```swift
enum Numbers: String {
  case one = ↓"one", two = ↓"two"
}
```

```swift
enum Numbers: String {
  case one, two = ↓"two"
}
```

</details>



## Redundant Type Annotation

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`redundant_type_annotation` | Disabled | Yes | idiomatic | No | 3.0.0 

Variables should not have redundant type annotation

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
var url = URL()
```

```swift
var url: CustomStringConvertible = URL()
```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
var url↓:URL=URL()
```

```swift
var url↓:URL = URL(string: "")
```

```swift
var url↓: URL = URL()
```

```swift
let url↓: URL = URL()
```

```swift
lazy var url↓: URL = URL()
```

```swift
let alphanumerics↓: CharacterSet = CharacterSet.alphanumerics
```

```swift
class ViewController: UIViewController {
  func someMethod() {
    let myVar↓: Int = Int(5)
  }
}
```

</details>



## Redundant Void Return

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`redundant_void_return` | Enabled | Yes | idiomatic | No | 3.0.0 

Returning Void in a function declaration is redundant.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
func foo() {}

```

```swift
func foo() -> Int {}

```

```swift
func foo() -> Int -> Void {}

```

```swift
func foo() -> VoidResponse

```

```swift
let foo: Int -> Void

```

```swift
func foo() -> Int -> () {}

```

```swift
let foo: Int -> ()

```

```swift
func foo() -> ()?

```

```swift
func foo() -> ()!

```

```swift
func foo() -> Void?

```

```swift
func foo() -> Void!

```

```swift
struct A {
    subscript(key: String) {
        print(key)
    }
}
```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
func foo()↓ -> Void {}

```

```swift
protocol Foo {
  func foo()↓ -> Void
}
```

```swift
func foo()↓ -> () {}

```

```swift
protocol Foo {
  func foo()↓ -> ()
}
```

</details>



## Required Deinit

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`required_deinit` | Disabled | No | lint | No | 3.0.0 

Classes should have an explicit deinit method.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
class Apple {
    deinit { }
}
```

```swift
enum Banana { }
```

```swift
protocol Cherry { }
```

```swift
struct Damson { }
```

```swift
class Outer {
    deinit { print("Deinit Outer") }
    class Inner {
        deinit { print("Deinit Inner") }
    }
}
```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
↓class Apple { }
```

```swift
↓class Banana: NSObject, Equatable { }
```

```swift
↓class Cherry {
    // deinit { }
}
```

```swift
↓class Damson {
    func deinitialize() { }
}
```

```swift
class Outer {
    func hello() -> String { return "outer" }
    deinit { }
    ↓class Inner {
        func hello() -> String { return "inner" }
    }
}
```

```swift
↓class Outer {
    func hello() -> String { return "outer" }
    class Inner {
        func hello() -> String { return "inner" }
        deinit { }
    }
}
```

</details>



## Required Enum Case

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`required_enum_case` | Disabled | No | lint | No | 3.0.0 

Enums conforming to a specified protocol must implement a specific case(s).

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
enum MyNetworkResponse: String, NetworkResponsable {
    case success, error, notConnected 
}
```

```swift
enum MyNetworkResponse: String, NetworkResponsable {
    case success, error, notConnected(error: Error) 
}
```

```swift
enum MyNetworkResponse: String, NetworkResponsable {
    case success
    case error
    case notConnected
}
```

```swift
enum MyNetworkResponse: String, NetworkResponsable {
    case success
    case error
    case notConnected(error: Error)
}
```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
enum MyNetworkResponse: String, NetworkResponsable {
    case success, error 
}
```

```swift
enum MyNetworkResponse: String, NetworkResponsable {
    case success, error 
}
```

```swift
enum MyNetworkResponse: String, NetworkResponsable {
    case success
    case error
}
```

```swift
enum MyNetworkResponse: String, NetworkResponsable {
    case success
    case error
}
```

</details>



## Returning Whitespace

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`return_arrow_whitespace` | Enabled | Yes | style | No | 3.0.0 

Return arrow and return type should be separated by a single space or on a separate line.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
func abc() -> Int {}

```

```swift
func abc() -> [Int] {}

```

```swift
func abc() -> (Int, Int) {}

```

```swift
var abc = {(param: Int) -> Void in }

```

```swift
func abc() ->
    Int {}

```

```swift
func abc()
    -> Int {}

```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
func abc()↓->Int {}

```

```swift
func abc()↓->[Int] {}

```

```swift
func abc()↓->(Int, Int) {}

```

```swift
func abc()↓-> Int {}

```

```swift
func abc()↓ ->Int {}

```

```swift
func abc()↓  ->  Int {}

```

```swift
var abc = {(param: Int)↓ ->Bool in }

```

```swift
var abc = {(param: Int)↓->Bool in }

```

</details>



## Shorthand Operator

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`shorthand_operator` | Enabled | No | style | No | 3.0.0 

Prefer shorthand operators (+=, -=, *=, /=) over doing the operation and assigning.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
foo -= 1
```

```swift
foo -= variable
```

```swift
foo -= bar.method()
```

```swift
self.foo = foo - 1
```

```swift
foo = self.foo - 1
```

```swift
page = ceilf(currentOffset - pageWidth)
```

```swift
foo = aMethod(foo - bar)
```

```swift
foo = aMethod(bar - foo)
```

```swift
foo /= 1
```

```swift
foo /= variable
```

```swift
foo /= bar.method()
```

```swift
self.foo = foo / 1
```

```swift
foo = self.foo / 1
```

```swift
page = ceilf(currentOffset / pageWidth)
```

```swift
foo = aMethod(foo / bar)
```

```swift
foo = aMethod(bar / foo)
```

```swift
foo += 1
```

```swift
foo += variable
```

```swift
foo += bar.method()
```

```swift
self.foo = foo + 1
```

```swift
foo = self.foo + 1
```

```swift
page = ceilf(currentOffset + pageWidth)
```

```swift
foo = aMethod(foo + bar)
```

```swift
foo = aMethod(bar + foo)
```

```swift
foo *= 1
```

```swift
foo *= variable
```

```swift
foo *= bar.method()
```

```swift
self.foo = foo * 1
```

```swift
foo = self.foo * 1
```

```swift
page = ceilf(currentOffset * pageWidth)
```

```swift
foo = aMethod(foo * bar)
```

```swift
foo = aMethod(bar * foo)
```

```swift
var helloWorld = "world!"
 helloWorld = "Hello, " + helloWorld
```

```swift
angle = someCheck ? angle : -angle
```

```swift
seconds = seconds * 60 + value
```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
↓foo = foo - 1

```

```swift
↓foo = foo - aVariable

```

```swift
↓foo = foo - bar.method()

```

```swift
↓foo.aProperty = foo.aProperty - 1

```

```swift
↓self.aProperty = self.aProperty - 1

```

```swift
↓foo = foo / 1

```

```swift
↓foo = foo / aVariable

```

```swift
↓foo = foo / bar.method()

```

```swift
↓foo.aProperty = foo.aProperty / 1

```

```swift
↓self.aProperty = self.aProperty / 1

```

```swift
↓foo = foo + 1

```

```swift
↓foo = foo + aVariable

```

```swift
↓foo = foo + bar.method()

```

```swift
↓foo.aProperty = foo.aProperty + 1

```

```swift
↓self.aProperty = self.aProperty + 1

```

```swift
↓foo = foo * 1

```

```swift
↓foo = foo * aVariable

```

```swift
↓foo = foo * bar.method()

```

```swift
↓foo.aProperty = foo.aProperty * 1

```

```swift
↓self.aProperty = self.aProperty * 1

```

```swift
n = n + i / outputLength
```

```swift
n = n - i / outputLength
```

</details>



## Single Test Class

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`single_test_class` | Disabled | No | style | No | 3.0.0 

Test files should contain a single QuickSpec or XCTestCase class.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
class FooTests {  }

```

```swift
class FooTests: QuickSpec {  }

```

```swift
class FooTests: XCTestCase {  }

```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
↓class FooTests: QuickSpec {  }
↓class BarTests: QuickSpec {  }

```

```swift
↓class FooTests: QuickSpec {  }
↓class BarTests: QuickSpec {  }
↓class TotoTests: QuickSpec {  }

```

```swift
↓class FooTests: XCTestCase {  }
↓class BarTests: XCTestCase {  }

```

```swift
↓class FooTests: XCTestCase {  }
↓class BarTests: XCTestCase {  }
↓class TotoTests: XCTestCase {  }

```

```swift
↓class FooTests: QuickSpec {  }
↓class BarTests: XCTestCase {  }

```

```swift
↓class FooTests: QuickSpec {  }
↓class BarTests: XCTestCase {  }
class TotoTests {  }

```

</details>



## Min or Max over Sorted First or Last

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`sorted_first_last` | Disabled | No | performance | No | 3.0.0 

Prefer using `min()` or `max()` over `sorted().first` or `sorted().last`

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
let min = myList.min()

```

```swift
let min = myList.min(by: { $0 < $1 })

```

```swift
let min = myList.min(by: >)

```

```swift
let max = myList.max()

```

```swift
let max = myList.max(by: { $0 < $1 })

```

```swift
let message = messages.sorted(byKeyPath: #keyPath(Message.timestamp)).last
```

```swift
let message = messages.sorted(byKeyPath: "timestamp", ascending: false).first
```

```swift
myList.sorted().firstIndex(of: key)
```

```swift
myList.sorted().lastIndex(of: key)
```

```swift
myList.sorted().firstIndex(where: someFunction)
```

```swift
myList.sorted().lastIndex(where: someFunction)
```

```swift
myList.sorted().firstIndex { $0 == key }
```

```swift
myList.sorted().lastIndex { $0 == key }
```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
↓myList.sorted().first

```

```swift
↓myList.sorted(by: { $0.description < $1.description }).first

```

```swift
↓myList.sorted(by: >).first

```

```swift
↓myList.map { $0 + 1 }.sorted().first

```

```swift
↓myList.sorted(by: someFunction).first

```

```swift
↓myList.map { $0 + 1 }.sorted { $0.description < $1.description }.first

```

```swift
↓myList.sorted().last

```

```swift
↓myList.sorted().last?.something()

```

```swift
↓myList.sorted(by: { $0.description < $1.description }).last

```

```swift
↓myList.map { $0 + 1 }.sorted().last

```

```swift
↓myList.sorted(by: someFunction).last

```

```swift
↓myList.map { $0 + 1 }.sorted { $0.description < $1.description }.last

```

```swift
↓myList.map { $0 + 1 }.sorted { $0.first < $1.first }.last

```

</details>



## Sorted Imports

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`sorted_imports` | Disabled | Yes | style | No | 3.0.0 

Imports should be sorted.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
import AAA
import BBB
import CCC
import DDD
```

```swift
import Alamofire
import API
```

```swift
import labc
import Ldef
```

```swift
import BBB
// comment
import AAA
import CCC
```

```swift
@testable import AAA
import   CCC
```

```swift
import AAA
@testable import   CCC
```

```swift
import EEE.A
import FFF.B
#if os(Linux)
import DDD.A
import EEE.B
#else
import CCC
import DDD.B
#endif
import AAA
import BBB
```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
import AAA
import ZZZ
import ↓BBB
import CCC
```

```swift
import DDD
// comment
import CCC
import ↓AAA
```

```swift
@testable import CCC
import   ↓AAA
```

```swift
import CCC
@testable import   ↓AAA
```

```swift
import FFF.B
import ↓EEE.A
#if os(Linux)
import DDD.A
import EEE.B
#else
import DDD.B
import ↓CCC
#endif
import AAA
import BBB
```

</details>



## Statement Position

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`statement_position` | Enabled | Yes | style | No | 3.0.0 

Else and catch should be on the same line, one space after the previous declaration.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
} else if {
```

```swift
} else {
```

```swift
} catch {
```

```swift
"}else{"
```

```swift
struct A { let catchphrase: Int }
let a = A(
 catchphrase: 0
)
```

```swift
struct A { let `catch`: Int }
let a = A(
 `catch`: 0
)
```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
↓}else if {
```

```swift
↓}  else {
```

```swift
↓}
catch {
```

```swift
↓}
	  catch {
```

</details>



## Static Operator

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`static_operator` | Disabled | No | idiomatic | No | 3.0.0 

Operators should be declared as static functions, not free functions.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
class A: Equatable {
  static func == (lhs: A, rhs: A) -> Bool {
    return false
  }
```

```swift
class A<T>: Equatable {
    static func == <T>(lhs: A<T>, rhs: A<T>) -> Bool {
        return false
    }
```

```swift
public extension Array where Element == Rule {
  static func == (lhs: Array, rhs: Array) -> Bool {
    if lhs.count != rhs.count { return false }
    return !zip(lhs, rhs).contains { !$0.0.isEqualTo($0.1) }
  }
}
```

```swift
private extension Optional where Wrapped: Comparable {
  static func < (lhs: Optional, rhs: Optional) -> Bool {
    switch (lhs, rhs) {
    case let (lhs?, rhs?):
      return lhs < rhs
    case (nil, _?):
      return true
    default:
      return false
    }
  }
}
```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
↓func == (lhs: A, rhs: A) -> Bool {
  return false
}
```

```swift
↓func == <T>(lhs: A<T>, rhs: A<T>) -> Bool {
  return false
}
```

```swift
↓func == (lhs: [Rule], rhs: [Rule]) -> Bool {
  if lhs.count != rhs.count { return false }
  return !zip(lhs, rhs).contains { !$0.0.isEqualTo($0.1) }
}
```

```swift
private ↓func < <T: Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (lhs?, rhs?):
    return lhs < rhs
  case (nil, _?):
    return true
  default:
    return false
  }
}
```

</details>



## Strict fileprivate

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`strict_fileprivate` | Disabled | No | idiomatic | No | 3.0.0 

`fileprivate` should be avoided.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
extension String {}
```

```swift
private extension String {}
```

```swift
public
extension String {}
```

```swift
open extension
  String {}
```

```swift
internal extension String {}
```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
↓fileprivate extension String {}
```

```swift
↓fileprivate
  extension String {}
```

```swift
↓fileprivate extension
  String {}
```

```swift
extension String {
  ↓fileprivate func Something(){}
}
```

```swift
class MyClass {
  ↓fileprivate let myInt = 4
}
```

```swift
class MyClass {
  ↓fileprivate(set) var myInt = 4
}
```

```swift
struct Outter {
  struct Inter {
    ↓fileprivate struct Inner {}
  }
}
```

</details>



## Strong IBOutlet

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`strong_iboutlet` | Disabled | No | lint | No | 3.0.0 

@IBOutlets shouldn't be declared as weak.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
class ViewController: UIViewController {
    @IBOutlet var label: UILabel?
}
```

```swift
class ViewController: UIViewController {
    weak var label: UILabel?
}
```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
class ViewController: UIViewController {
    @IBOutlet weak ↓var label: UILabel?
}
```

```swift
class ViewController: UIViewController {
    @IBOutlet unowned ↓var label: UILabel!
}
```

```swift
class ViewController: UIViewController {
    @IBOutlet weak ↓var textField: UITextField?
}
```

</details>



## Superfluous Disable Command

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`superfluous_disable_command` | Enabled | No | lint | No | 3.0.0 

SwiftLint 'disable' commands are superfluous when the disabled rule would not have triggered a violation in the disabled region. Use " - " if you wish to document a command.



## Switch and Case Statement Alignment

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`switch_case_alignment` | Enabled | No | style | No | 3.0.0 

Case statements should vertically align with their enclosing switch statement, or indented if configured otherwise.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
switch someBool {
case true: // case 1
    print('red')
case false:
    /*
    case 2
    */
    if case let .someEnum(val) = someFunc() {
        print('blue')
    }
}
enum SomeEnum {
    case innocent
}
```

```swift
if aBool {
    switch someBool {
    case true:
        print('red')
    case false:
        print('blue')
    }
}
```

```swift
switch someInt {
// comments ignored
case 0:
    // zero case
    print('Zero')
case 1:
    print('One')
default:
    print('Some other number')
}
```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
switch someBool {
    ↓case true:
        print("red")
    ↓case false:
        print("blue")
}
```

```swift
if aBool {
    switch someBool {
        ↓case true:
            print('red')
        ↓case false:
            print('blue')
    }
}
```

```swift
switch someInt {
    ↓case 0:
        print('Zero')
    ↓case 1:
        print('One')
    ↓default:
        print('Some other number')
}
```

```swift
switch someBool {
case true:
    print('red')
    ↓case false:
        print('blue')
}
```

```swift
if aBool {
    switch someBool {
        ↓case true:
        print('red')
    case false:
    print('blue')
    }
}
```

</details>



## Switch Case on Newline

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`switch_case_on_newline` | Disabled | No | style | No | 3.0.0 

Cases inside a switch should always be on a newline

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
/*case 1: */return true
```

```swift
//case 1:
 return true
```

```swift
let x = [caseKey: value]
```

```swift
let x = [key: .default]
```

```swift
if case let .someEnum(value) = aFunction([key: 2]) { }
```

```swift
guard case let .someEnum(value) = aFunction([key: 2]) { }
```

```swift
for case let .someEnum(value) = aFunction([key: 2]) { }
```

```swift
enum Environment {
 case development
}
```

```swift
enum Environment {
 case development(url: URL)
}
```

```swift
enum Environment {
 case development(url: URL) // staging
}
```

```swift
switch foo {
  case 1:
 return true
}

```

```swift
switch foo {
  default:
 return true
}

```

```swift
switch foo {
  case let value:
 return true
}

```

```swift
switch foo {
  case .myCase: // error from network
 return true
}

```

```swift
switch foo {
  case let .myCase(value) where value > 10:
 return false
}

```

```swift
switch foo {
  case let .myCase(value)
 where value > 10:
 return false
}

```

```swift
switch foo {
  case let .myCase(code: lhsErrorCode, description: _)
 where lhsErrorCode > 10:
 return false
}

```

```swift
switch foo {
  case #selector(aFunction(_:)):
 return false

}

```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
switch foo {
  ↓case 1: return true
}

```

```swift
switch foo {
  ↓case let value: return true
}

```

```swift
switch foo {
  ↓default: return true
}

```

```swift
switch foo {
  ↓case "a string": return false
}

```

```swift
switch foo {
  ↓case .myCase: return false // error from network
}

```

```swift
switch foo {
  ↓case let .myCase(value) where value > 10: return false
}

```

```swift
switch foo {
  ↓case #selector(aFunction(_:)): return false

}

```

```swift
switch foo {
  ↓case let .myCase(value)
 where value > 10: return false
}

```

```swift
switch foo {
  ↓case .first,
 .second: return false
}

```

</details>



## Syntactic Sugar

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`syntactic_sugar` | Enabled | No | idiomatic | No | 3.0.0 

Shorthand syntactic sugar should be used, i.e. [Int] instead of Array<Int>.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
let x: [Int]
```

```swift
let x: [Int: String]
```

```swift
let x: Int?
```

```swift
func x(a: [Int], b: Int) -> [Int: Any]
```

```swift
let x: Int!
```

```swift
extension Array {
  func x() { }
}
```

```swift
extension Dictionary {
  func x() { }
}
```

```swift
let x: CustomArray<String>
```

```swift
var currentIndex: Array<OnboardingPage>.Index?
```

```swift
func x(a: [Int], b: Int) -> Array<Int>.Index
```

```swift
unsafeBitCast(nonOptionalT, to: Optional<T>.self)
```

```swift
type is Optional<String>.Type
```

```swift
let x: Foo.Optional<String>
```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
let x: ↓Array<String>
```

```swift
let x: ↓Dictionary<Int, String>
```

```swift
let x: ↓Optional<Int>
```

```swift
let x: ↓ImplicitlyUnwrappedOptional<Int>
```

```swift
func x(a: ↓Array<Int>, b: Int) -> [Int: Any]
```

```swift
func x(a: [Int], b: Int) -> ↓Dictionary<Int, String>
```

```swift
func x(a: ↓Array<Int>, b: Int) -> ↓Dictionary<Int, String>
```

```swift
let x = ↓Array<String>.array(of: object)
```

```swift
let x: ↓Swift.Optional<String>
```

</details>



## Todo

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`todo` | Enabled | No | lint | No | 3.0.0 

TODOs and FIXMEs should be resolved.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
// notaTODO:

```

```swift
// notaFIXME:

```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
// ↓TODO:

```

```swift
// ↓FIXME:

```

```swift
// ↓TODO(note)

```

```swift
// ↓FIXME(note)

```

```swift
/* ↓FIXME: */

```

```swift
/* ↓TODO: */

```

```swift
/** ↓FIXME: */

```

```swift
/** ↓TODO: */

```

</details>



## Toggle Bool

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`toggle_bool` | Disabled | No | idiomatic | No | 4.2.0 

Prefer `someBool.toggle()` over `someBool = !someBool`.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
isHidden.toggle()

```

```swift
view.clipsToBounds.toggle()

```

```swift
func foo() { abc.toggle() }
```

```swift
view.clipsToBounds = !clipsToBounds

```

```swift
disconnected = !connected

```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
↓isHidden = !isHidden

```

```swift
↓view.clipsToBounds = !view.clipsToBounds

```

```swift
func foo() { ↓abc = !abc }
```

</details>



## Trailing Closure

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`trailing_closure` | Disabled | No | style | No | 3.0.0 

Trailing closure syntax should be used whenever possible.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
foo.map { $0 + 1 }

```

```swift
foo.bar()

```

```swift
foo.reduce(0) { $0 + 1 }

```

```swift
if let foo = bar.map({ $0 + 1 }) { }

```

```swift
foo.something(param1: { $0 }, param2: { $0 + 1 })

```

```swift
offsets.sorted { $0.offset < $1.offset }

```

```swift
foo.something({ return 1 }())
```

```swift
foo.something({ return $0 }(1))
```

```swift
foo.something(0, { return 1 }())
```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
↓foo.map({ $0 + 1 })

```

```swift
↓foo.reduce(0, combine: { $0 + 1 })

```

```swift
↓offsets.sorted(by: { $0.offset < $1.offset })

```

```swift
↓foo.something(0, { $0 + 1 })

```

</details>



## Trailing Comma

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`trailing_comma` | Enabled | Yes | style | No | 3.0.0 

Trailing commas in arrays and dictionaries should be avoided/enforced.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
let foo = [1, 2, 3]

```

```swift
let foo = []

```

```swift
let foo = [:]

```

```swift
let foo = [1: 2, 2: 3]

```

```swift
let foo = [Void]()

```

```swift
let example = [ 1,
 2
 // 3,
]
```

```swift
foo([1: "\(error)"])

```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
let foo = [1, 2, 3↓,]

```

```swift
let foo = [1, 2, 3↓, ]

```

```swift
let foo = [1, 2, 3   ↓,]

```

```swift
let foo = [1: 2, 2: 3↓, ]

```

```swift
struct Bar {
 let foo = [1: 2, 2: 3↓, ]
}

```

```swift
let foo = [1, 2, 3↓,] + [4, 5, 6↓,]

```

```swift
let example = [ 1,
2↓,
 // 3,
]
```

```swift
let foo = ["אבג", "αβγ", "🇺🇸"↓,]

```

```swift
class C {
 #if true
 func f() {
 let foo = [1, 2, 3↓,]
 }
 #endif
}
```

```swift
foo([1: "\(error)"↓,])

```

</details>



## Trailing Newline

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`trailing_newline` | Enabled | Yes | style | No | 3.0.0 

Files should have a single trailing newline.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
let a = 0

```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
let a = 0
```

```swift
let a = 0


```

</details>



## Trailing Semicolon

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`trailing_semicolon` | Enabled | Yes | idiomatic | No | 3.0.0 

Lines should not have trailing semicolons.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
let a = 0

```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
let a = 0↓;

```

```swift
let a = 0↓;
let b = 1

```

```swift
let a = 0↓;;

```

```swift
let a = 0↓;    ;;

```

```swift
let a = 0↓; ; ;

```

</details>



## Trailing Whitespace

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`trailing_whitespace` | Enabled | Yes | style | No | 3.0.0 

Lines should not have trailing whitespace.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
let name: String

```

```swift
//

```

```swift
// 

```

```swift
let name: String //

```

```swift
let name: String // 

```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
let name: String 

```

```swift
/* */ let name: String 

```

</details>



## Type Body Length

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`type_body_length` | Enabled | No | metrics | No | 3.0.0 

Type bodies should not span too many lines.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
class Abc {
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
}

```

```swift
class Abc {









































































































































































































}

```

```swift
class Abc {
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
}

```

```swift
class Abc {
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0

/* this is
a multiline comment
*/
}

```

```swift
struct Abc {
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
}

```

```swift
struct Abc {









































































































































































































}

```

```swift
struct Abc {
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
}

```

```swift
struct Abc {
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0

/* this is
a multiline comment
*/
}

```

```swift
enum Abc {
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
}

```

```swift
enum Abc {









































































































































































































}

```

```swift
enum Abc {
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
// this is a comment
}

```

```swift
enum Abc {
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0

/* this is
a multiline comment
*/
}

```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
↓class Abc {
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
}

```

```swift
↓struct Abc {
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
}

```

```swift
↓enum Abc {
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
let abc = 0
}

```

</details>



## Type Contents Order

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`type_contents_order` | Disabled | No | style | No | 3.0.0 

Specifies the order of subtypes, properties, methods & more within a type.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
class TestViewController: UIViewController {
    // Type Aliases
    typealias CompletionHandler = ((TestEnum) -> Void)

    // Subtypes
    class TestClass {
        // 10 lines
    }

    struct TestStruct {
        // 3 lines
    }

    enum TestEnum {
        // 5 lines
    }

    // Type Properties
    static let cellIdentifier: String = "AmazingCell"

    // Instance Properties
    var shouldLayoutView1: Bool!
    weak var delegate: TestViewControllerDelegate?
    private var hasLayoutedView1: Bool = false
    private var hasLayoutedView2: Bool = false

    private var hasAnyLayoutedView: Bool {
         return hasLayoutedView1 || hasLayoutedView2
    }

    // IBOutlets
    @IBOutlet private var view1: UIView!
    @IBOutlet private var view2: UIView!

    // Initializers
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // Type Methods
    static func makeViewController() -> TestViewController {
        // some code
    }

    // View Life-Cycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()

        view1.setNeedsLayout()
        view1.layoutIfNeeded()
        hasLayoutedView1 = true
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        view2.setNeedsLayout()
        view2.layoutIfNeeded()
        hasLayoutedView2 = true
    }

    // IBActions
    @IBAction func goNextButtonPressed() {
        goToNextVc()
        delegate?.didPressTrackedButton()
    }

    // Other Methods
    func goToNextVc() { /* TODO */ }

    func goToInfoVc() { /* TODO */ }

    func goToRandomVc() {
        let viewCtrl = getRandomVc()
        present(viewCtrl, animated: true)
    }

    private func getRandomVc() -> UIViewController { return UIViewController() }

    // Subscripts
    subscript(_ someIndexThatIsNotEvenUsed: Int) -> String {
        get {
            return "This is just a test"
        }

        set {
            log.warning("Just a test", newValue)
        }
    }
}
```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
class TestViewController: UIViewController {
    // Subtypes
    ↓class TestClass {
        // 10 lines
    }

    // Type Aliases
    typealias CompletionHandler = ((TestEnum) -> Void)
}
```

```swift
class TestViewController: UIViewController {
    // Stored Type Properties
    ↓static let cellIdentifier: String = "AmazingCell"

    // Subtypes
    class TestClass {
        // 10 lines
    }
}
```

```swift
class TestViewController: UIViewController {
    // Stored Instance Properties
    ↓var shouldLayoutView1: Bool!

    // Stored Type Properties
    static let cellIdentifier: String = "AmazingCell"
}
```

```swift
class TestViewController: UIViewController {
    // IBOutlets
    @IBOutlet private ↓var view1: UIView!

    // Computed Instance Properties
    private var hasAnyLayoutedView: Bool {
         return hasLayoutedView1 || hasLayoutedView2
    }
}
```

```swift
class TestViewController: UIViewController {
    // Initializers
    override ↓init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    // IBOutlets
    @IBOutlet private var view1: UIView!
    @IBOutlet private var view2: UIView!
}
```

```swift
class TestViewController: UIViewController {
    // View Life-Cycle Methods
    override ↓func viewDidLoad() {
        super.viewDidLoad()

        view1.setNeedsLayout()
        view1.layoutIfNeeded()
        hasLayoutedView1 = true
    }

    // Type Methods
    static func makeViewController() -> TestViewController {
        // some code
    }
}
```

```swift
class TestViewController: UIViewController {
    // IBActions
    @IBAction ↓func goNextButtonPressed() {
        goToNextVc()
        delegate?.didPressTrackedButton()
    }

    // View Life-Cycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()

        view1.setNeedsLayout()
        view1.layoutIfNeeded()
        hasLayoutedView1 = true
    }
}
```

```swift
class TestViewController: UIViewController {
    // Other Methods
    ↓func goToNextVc() { /* TODO */ }

    // IBActions
    @IBAction func goNextButtonPressed() {
        goToNextVc()
        delegate?.didPressTrackedButton()
    }
}
```

```swift
class TestViewController: UIViewController {
    // Subscripts
    ↓subscript(_ someIndexThatIsNotEvenUsed: Int) -> String {
        get {
            return "This is just a test"
        }

        set {
            log.warning("Just a test", newValue)
        }
    }

    // MARK: Other Methods
    func goToNextVc() { /* TODO */ }
}
```

</details>



## Type Name

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`type_name` | Enabled | No | idiomatic | No | 3.0.0 

Type name should only contain alphanumeric characters, start with an uppercase character and span between 3 and 40 characters in length.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
class MyType {}
```

```swift
private class _MyType {}
```

```swift
class AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA {}
```

```swift
struct MyType {}
```

```swift
private struct _MyType {}
```

```swift
struct AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA {}
```

```swift
enum MyType {}
```

```swift
private enum _MyType {}
```

```swift
enum AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA {}
```

```swift
typealias Foo = Void
```

```swift
private typealias Foo = Void
```

```swift
protocol Foo {
  associatedtype Bar
}
```

```swift
protocol Foo {
  associatedtype Bar: Equatable
}
```

```swift
enum MyType {
case value
}
```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
class ↓myType {}
```

```swift
class ↓_MyType {}
```

```swift
private class ↓MyType_ {}
```

```swift
class ↓My {}
```

```swift
class ↓AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA {}
```

```swift
struct ↓myType {}
```

```swift
struct ↓_MyType {}
```

```swift
private struct ↓MyType_ {}
```

```swift
struct ↓My {}
```

```swift
struct ↓AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA {}
```

```swift
enum ↓myType {}
```

```swift
enum ↓_MyType {}
```

```swift
private enum ↓MyType_ {}
```

```swift
enum ↓My {}
```

```swift
enum ↓AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA {}
```

```swift
typealias ↓X = Void
```

```swift
private typealias ↓Foo_Bar = Void
```

```swift
private typealias ↓foo = Void
```

```swift
typealias ↓AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA = Void
```

```swift
protocol Foo {
  associatedtype ↓X
}
```

```swift
protocol Foo {
  associatedtype ↓Foo_Bar: Equatable
}
```

```swift
protocol Foo {
  associatedtype ↓AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
}
```

</details>



## Unavailable Function

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`unavailable_function` | Disabled | No | idiomatic | No | 4.1.0 

Unimplemented functions should be marked as unavailable.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
class ViewController: UIViewController {
  @available(*, unavailable)
  public required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
```

```swift
func jsonValue(_ jsonString: String) -> NSObject {
   let data = jsonString.data(using: .utf8)!
   let result = try! JSONSerialization.jsonObject(with: data, options: [])
   if let dict = (result as? [String: Any])?.bridge() {
    return dict
   } else if let array = (result as? [Any])?.bridge() {
    return array
   }
   fatalError()
}
```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
class ViewController: UIViewController {
  public required ↓init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
```

```swift
class ViewController: UIViewController {
  public required ↓init?(coder aDecoder: NSCoder) {
    let reason = "init(coder:) has not been implemented"
    fatalError(reason)
  }
}
```

</details>



## Unneeded Break in Switch

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`unneeded_break_in_switch` | Enabled | No | idiomatic | No | 3.0.0 

Avoid using unneeded break statements.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
switch foo {
case .bar:
    break
}
```

```swift
switch foo {
default:
    break
}
```

```swift
switch foo {
case .bar:
    for i in [0, 1, 2] { break }
}
```

```swift
switch foo {
case .bar:
    if true { break }
}
```

```swift
switch foo {
case .bar:
    something()
}
```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
switch foo {
case .bar:
    something()
    ↓break
}
```

```swift
switch foo {
case .bar:
    something()
    ↓break // comment
}
```

```swift
switch foo {
default:
    something()
    ↓break
}
```

```swift
switch foo {
case .foo, .foo2 where condition:
    something()
    ↓break
}
```

</details>



## Unneeded Parentheses in Closure Argument

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`unneeded_parentheses_in_closure_argument` | Disabled | Yes | style | No | 3.0.0 

Parentheses are not needed when declaring closure arguments.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
let foo = { (bar: Int) in }

```

```swift
let foo = { bar, _  in }

```

```swift
let foo = { bar in }

```

```swift
let foo = { bar -> Bool in return true }

```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
call(arg: { ↓(bar) in })

```

```swift
call(arg: { ↓(bar, _) in })

```

```swift
let foo = { ↓(bar) -> Bool in return true }

```

```swift
foo.map { ($0, $0) }.forEach { ↓(x, y) in }
```

```swift
foo.bar { [weak self] ↓(x, y) in }
```

```swift
[].first { ↓(temp) in
    [].first { ↓(temp) in
        [].first { ↓(temp) in
            _ = temp
            return false
        }
        return false
    }
    return false
}
```

```swift
[].first { temp in
    [].first { ↓(temp) in
        [].first { ↓(temp) in
            _ = temp
            return false
        }
        return false
    }
    return false
}
```

</details>



## Unowned Variable Capture

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`unowned_variable_capture` | Disabled | No | lint | No | 5.0.0 

Prefer capturing references as weak to avoid potential crashes.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
foo { [weak self] in _ }
```

```swift
foo { [weak self] param in _ }
```

```swift
foo { [weak bar] in _ }
```

```swift
foo { [weak bar] param in _ }
```

```swift
foo { bar in _ }
```

```swift
foo { $0 }
```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
foo { [↓unowned self] in _ }
```

```swift
foo { [↓unowned bar] in _ }
```

```swift
foo { [bar, ↓unowned self] in _ }
```

</details>



## Untyped Error in Catch

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`untyped_error_in_catch` | Disabled | Yes | idiomatic | No | 3.0.0 

Catch statements should not declare error variables without type casting.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
do {
  try foo()
} catch {}
```

```swift
do {
  try foo()
} catch Error.invalidOperation {
} catch {}
```

```swift
do {
  try foo()
} catch let error as MyError {
} catch {}
```

```swift
do {
  try foo()
} catch var error as MyError {
} catch {}
```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
do {
  try foo()
} ↓catch var error {}
```

```swift
do {
  try foo()
} ↓catch let error {}
```

```swift
do {
  try foo()
} ↓catch let someError {}
```

```swift
do {
  try foo()
} ↓catch var someError {}
```

```swift
do {
  try foo()
} ↓catch let e {}
```

```swift
do {
  try foo()
} ↓catch(let error) {}
```

```swift
do {
  try foo()
} ↓catch (let error) {}
```

</details>



## Unused Capture List

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`unused_capture_list` | Enabled | No | lint | No | 4.2.0 

Unused reference in a capture list should be removed.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
[1, 2].map { [weak self] num in
    self?.handle(num)
}
```

```swift
let failure: Failure = { [weak self, unowned delegate = self.delegate!] foo in
    delegate.handle(foo, self)
}
```

```swift
numbers.forEach({
    [weak handler] in
    handler?.handle($0)
})
```

```swift
withEnvironment(apiService: MockService(fetchProjectResponse: project)) {
    [Device.phone4_7inch, Device.phone5_8inch, Device.pad].forEach { device in
        device.handle()
    }
}
```

```swift
{ [foo] _ in foo.bar() }()
```

```swift
sizes.max().flatMap { [(offset: offset, size: $0)] } ?? []
```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
[1, 2].map { [↓weak self] num in
    print(num)
}
```

```swift
let failure: Failure = { [weak self, ↓unowned delegate = self.delegate!] foo in
    self?.handle(foo)
}
```

```swift
let failure: Failure = { [↓weak self, ↓unowned delegate = self.delegate!] foo in
    print(foo)
}
```

```swift
numbers.forEach({
    [weak handler] in
    print($0)
})
```

```swift
withEnvironment(apiService: MockService(fetchProjectResponse: project)) { [↓foo] in
    [Device.phone4_7inch, Device.phone5_8inch, Device.pad].forEach { device in
        device.handle()
    }
}
```

```swift
{ [↓foo] in _ }()
```

</details>



## Unused Closure Parameter

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`unused_closure_parameter` | Enabled | Yes | lint | No | 3.0.0 

Unused parameter in a closure should be replaced with _.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
[1, 2].map { $0 + 1 }

```

```swift
[1, 2].map({ $0 + 1 })

```

```swift
[1, 2].map { number in
 number + 1 
}

```

```swift
[1, 2].map { _ in
 3 
}

```

```swift
[1, 2].something { number, idx in
 return number * idx
}

```

```swift
let isEmpty = [1, 2].isEmpty()

```

```swift
violations.sorted(by: { lhs, rhs in 
 return lhs.location > rhs.location
})

```

```swift
rlmConfiguration.migrationBlock.map { rlmMigration in
return { migration, schemaVersion in
rlmMigration(migration.rlmMigration, schemaVersion)
}
}
```

```swift
genericsFunc { (a: Type, b) in
a + b
}

```

```swift
var label: UILabel = { (lbl: UILabel) -> UILabel in
   lbl.backgroundColor = .red
   return lbl
}(UILabel())

```

```swift
hoge(arg: num) { num in
  return num
}

```

```swift
({ (manager: FileManager) in
  print(manager)
})(FileManager.default)
```

```swift
withPostSideEffect { input in
    if true { print("\(input)") }
}
```

```swift
viewModel?.profileImage.didSet(weak: self) { (self, profileImage) in
    self.profileImageView.image = profileImage
}
```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
[1, 2].map { ↓number in
 return 3
}

```

```swift
[1, 2].map { ↓number in
 return numberWithSuffix
}

```

```swift
[1, 2].map { ↓number in
 return 3 // number
}

```

```swift
[1, 2].map { ↓number in
 return 3 "number"
}

```

```swift
[1, 2].something { number, ↓idx in
 return number
}

```

```swift
genericsFunc { (↓number: TypeA, idx: TypeB) in return idx
}

```

```swift
hoge(arg: num) { ↓num in
}

```

```swift
fooFunc { ↓아 in
 }
```

```swift
func foo () {
 bar { ↓number in
 return 3
}

```

```swift
viewModel?.profileImage.didSet(weak: self) { (↓self, profileImage) in
    profileImageView.image = profileImage
}
```

</details>



## Unused Control Flow Label

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`unused_control_flow_label` | Enabled | Yes | lint | No | 3.0.0 

Unused control flow label should be removed.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
loop: while true { break loop }
```

```swift
loop: while true { continue loop }
```

```swift
loop:
    while true { break loop }
```

```swift
while true { break }
```

```swift
loop: for x in array { break loop }
```

```swift
label: switch number {
case 1: print("1")
case 2: print("2")
default: break label
}
```

```swift
loop: repeat {
    if x == 10 {
        break loop
    }
} while true
```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
↓loop: while true { break }
```

```swift
↓loop: while true { break loop1 }
```

```swift
↓loop: while true { break outerLoop }
```

```swift
↓loop: for x in array { break }
```

```swift
↓label: switch number {
case 1: print("1")
case 2: print("2")
default: break
}
```

```swift
↓loop: repeat {
    if x == 10 {
        break
    }
} while true
```

</details>



## Unused Declaration

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`unused_declaration` | Disabled | No | lint | Yes | 3.0.0 

Declarations should be referenced at least once within all files linted.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
let kConstant = 0
_ = kConstant
```

```swift
struct Item {}
struct ResponseModel: Codable {
    let items: [Item]

    enum CodingKeys: String, CodingKey {
        case items = "ResponseItems"
    }
}

_ = ResponseModel(items: [Item()]).items
```

```swift
class ResponseModel {
    @objc func foo() {
    }
}
_ = ResponseModel()
```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
let ↓kConstant = 0
```

```swift
struct Item {}
struct ↓ResponseModel: Codable {
    let ↓items: [Item]

    enum ↓CodingKeys: String {
        case items = "ResponseItems"
    }
}
```

```swift
class ↓ResponseModel {
    func ↓foo() {
    }
}
```

</details>



## Unused Enumerated

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`unused_enumerated` | Enabled | No | idiomatic | No | 3.0.0 

When the index or the item is not used, `.enumerated()` can be removed.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
for (idx, foo) in bar.enumerated() { }

```

```swift
for (_, foo) in bar.enumerated().something() { }

```

```swift
for (_, foo) in bar.something() { }

```

```swift
for foo in bar.enumerated() { }

```

```swift
for foo in bar { }

```

```swift
for (idx, _) in bar.enumerated().something() { }

```

```swift
for (idx, _) in bar.something() { }

```

```swift
for idx in bar.indices { }

```

```swift
for (section, (event, _)) in data.enumerated() {}

```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
for (↓_, foo) in bar.enumerated() { }

```

```swift
for (↓_, foo) in abc.bar.enumerated() { }

```

```swift
for (↓_, foo) in abc.something().enumerated() { }

```

```swift
for (idx, ↓_) in bar.enumerated() { }

```

</details>



## Unused Import

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`unused_import` | Disabled | Yes | lint | Yes | 3.0.0 

All imported modules should be required to make the file compile.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
import Dispatch
dispatchMain()
```

```swift
@testable import Dispatch
dispatchMain()
```

```swift
import Foundation
@objc
class A {}
```

```swift
import UnknownModule
func foo(error: Swift.Error) {}
```

```swift
import Foundation
import ObjectiveC
let 👨‍👩‍👧‍👦 = #selector(NSArray.contains(_:))
👨‍👩‍👧‍👦 == 👨‍👩‍👧‍👦
```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
↓import Dispatch
struct A {
  static func dispatchMain() {}
}
A.dispatchMain()
```

```swift
↓import Foundation
struct A {
  static func dispatchMain() {}
}
A.dispatchMain()
↓import Dispatch

```

```swift
↓import Foundation
dispatchMain()
```

```swift
↓import Foundation
// @objc
class A {}
```

```swift
↓import Foundation
import UnknownModule
func foo(error: Swift.Error) {}
```

</details>



## Unused Optional Binding

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`unused_optional_binding` | Enabled | No | style | No | 3.0.0 

Prefer `!= nil` over `let _ =`

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
if let bar = Foo.optionalValue {
}

```

```swift
if let (_, second) = getOptionalTuple() {
}

```

```swift
if let (_, asd, _) = getOptionalTuple(), let bar = Foo.optionalValue {
}

```

```swift
if foo() { let _ = bar() }

```

```swift
if foo() { _ = bar() }

```

```swift
if case .some(_) = self {}
```

```swift
if let point = state.find({ _ in true }) {}
```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
if let ↓_ = Foo.optionalValue {
}

```

```swift
if let a = Foo.optionalValue, let ↓_ = Foo.optionalValue2 {
}

```

```swift
guard let a = Foo.optionalValue, let ↓_ = Foo.optionalValue2 {
}

```

```swift
if let (first, second) = getOptionalTuple(), let ↓_ = Foo.optionalValue {
}

```

```swift
if let (first, _) = getOptionalTuple(), let ↓_ = Foo.optionalValue {
}

```

```swift
if let (_, second) = getOptionalTuple(), let ↓_ = Foo.optionalValue {
}

```

```swift
if let ↓(_, _, _) = getOptionalTuple(), let bar = Foo.optionalValue {
}

```

```swift
func foo() {
if let ↓_ = bar {
}

```

```swift
if case .some(let ↓_) = self {}
```

</details>



## Unused Setter Value

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`unused_setter_value` | Enabled | No | lint | No | 3.0.0 

Setter value is not used.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
var aValue: String {
    get {
        return Persister.shared.aValue
    }
    set {
        Persister.shared.aValue = newValue
    }
}
```

```swift
var aValue: String {
    set {
        Persister.shared.aValue = newValue
    }
    get {
        return Persister.shared.aValue
    }
}
```

```swift
var aValue: String {
    get {
        return Persister.shared.aValue
    }
    set(value) {
        Persister.shared.aValue = value
    }
}
```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
var aValue: String {
    get {
        return Persister.shared.aValue
    }
    ↓set {
        Persister.shared.aValue = aValue
    }
}
```

```swift
var aValue: String {
    ↓set {
        Persister.shared.aValue = aValue
    }
    get {
        return Persister.shared.aValue
    }
}
```

```swift
var aValue: String {
    get {
        return Persister.shared.aValue
    }
    ↓set {
        Persister.shared.aValue = aValue
    }
}
```

```swift
var aValue: String {
    get {
        let newValue = Persister.shared.aValue
        return newValue
    }
    ↓set {
        Persister.shared.aValue = aValue
    }
}
```

```swift
var aValue: String {
    get {
        return Persister.shared.aValue
    }
    ↓set(value) {
        Persister.shared.aValue = aValue
    }
}
```

</details>



## Valid IBInspectable

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`valid_ibinspectable` | Enabled | No | lint | No | 3.0.0 

@IBInspectable should be applied to variables only, have its type explicit and be of a supported type

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
class Foo {
  @IBInspectable private var x: Int
}

```

```swift
class Foo {
  @IBInspectable private var x: String?
}

```

```swift
class Foo {
  @IBInspectable private var x: String!
}

```

```swift
class Foo {
  @IBInspectable private var count: Int = 0
}

```

```swift
class Foo {
  private var notInspectable = 0
}

```

```swift
class Foo {
  private let notInspectable: Int
}

```

```swift
class Foo {
  private let notInspectable: UInt8
}

```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
class Foo {
  @IBInspectable private ↓let count: Int
}

```

```swift
class Foo {
  @IBInspectable private ↓var insets: UIEdgeInsets
}

```

```swift
class Foo {
  @IBInspectable private ↓var count = 0
}

```

```swift
class Foo {
  @IBInspectable private ↓var count: Int?
}

```

```swift
class Foo {
  @IBInspectable private ↓var count: Int!
}

```

```swift
class Foo {
  @IBInspectable private ↓var x: ImplicitlyUnwrappedOptional<Int>
}

```

```swift
class Foo {
  @IBInspectable private ↓var count: Optional<Int>
}

```

```swift
class Foo {
  @IBInspectable private ↓var x: Optional<String>
}

```

```swift
class Foo {
  @IBInspectable private ↓var x: ImplicitlyUnwrappedOptional<String>
}

```

</details>



## Vertical Parameter Alignment

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`vertical_parameter_alignment` | Enabled | No | style | No | 3.0.0 

Function parameters should be aligned vertically if they're in multiple lines in a declaration.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
func validateFunction(_ file: File, kind: SwiftDeclarationKind,
                      dictionary: [String: SourceKitRepresentable]) { }

```

```swift
func validateFunction(_ file: File, kind: SwiftDeclarationKind,
                      dictionary: [String: SourceKitRepresentable]) -> [StyleViolation]

```

```swift
func foo(bar: Int)

```

```swift
func foo(bar: Int) -> String 

```

```swift
func validateFunction(_ file: File, kind: SwiftDeclarationKind,
                      dictionary: [String: SourceKitRepresentable])
                      -> [StyleViolation]

```

```swift
func validateFunction(
   _ file: File, kind: SwiftDeclarationKind,
   dictionary: [String: SourceKitRepresentable]) -> [StyleViolation]

```

```swift
func validateFunction(
   _ file: File, kind: SwiftDeclarationKind,
   dictionary: [String: SourceKitRepresentable]
) -> [StyleViolation]

```

```swift
func regex(_ pattern: String,
           options: NSRegularExpression.Options = [.anchorsMatchLines,
                                                   .dotMatchesLineSeparators]) -> NSRegularExpression

```

```swift
func foo(a: Void,
         b: [String: String] =
           [:]) {
}

```

```swift
func foo(data: (size: CGSize,
                identifier: String)) {}
```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
func validateFunction(_ file: File, kind: SwiftDeclarationKind,
                  ↓dictionary: [String: SourceKitRepresentable]) { }

```

```swift
func validateFunction(_ file: File, kind: SwiftDeclarationKind,
                       ↓dictionary: [String: SourceKitRepresentable]) { }

```

```swift
func validateFunction(_ file: File,
                  ↓kind: SwiftDeclarationKind,
                  ↓dictionary: [String: SourceKitRepresentable]) { }

```

</details>



## Vertical Parameter Alignment On Call

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`vertical_parameter_alignment_on_call` | Disabled | No | style | No | 3.0.0 

Function parameters should be aligned vertically if they're in multiple lines in a method call.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
foo(param1: 1, param2: bar
    param3: false, param4: true)
```

```swift
foo(param1: 1, param2: bar)
```

```swift
foo(param1: 1, param2: bar
    param3: false,
    param4: true)
```

```swift
foo(
   param1: 1
) { _ in }
```

```swift
UIView.animate(withDuration: 0.4, animations: {
    blurredImageView.alpha = 1
}, completion: { _ in
    self.hideLoading()
})
```

```swift
UIView.animate(withDuration: 0.4, animations: {
    blurredImageView.alpha = 1
},
completion: { _ in
    self.hideLoading()
})
```

```swift
foo(param1: 1, param2: { _ in },
    param3: false, param4: true)
```

```swift
foo({ _ in
       bar()
   },
   completion: { _ in
       baz()
   }
)
```

```swift
foo(param1: 1, param2: [
   0,
   1
], param3: 0)
```

```swift
myFunc(foo: 0,
       bar: baz == 0)
```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
foo(param1: 1, param2: bar
                ↓param3: false, param4: true)
```

```swift
foo(param1: 1, param2: bar
 ↓param3: false, param4: true)
```

```swift
foo(param1: 1, param2: bar
       ↓param3: false,
       ↓param4: true)
```

```swift
foo(param1: 1,
       ↓param2: { _ in })
```

```swift
foo(param1: 1,
    param2: { _ in
}, param3: 2,
 ↓param4: 0)
```

```swift
foo(param1: 1, param2: { _ in },
       ↓param3: false, param4: true)
```

```swift
myFunc(foo: 0,
        ↓bar: baz == 0)
```

</details>



## Vertical Whitespace

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`vertical_whitespace` | Enabled | Yes | style | No | 3.0.0 

Limit vertical whitespace to a single empty line.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
let abc = 0

```

```swift
let abc = 0


```

```swift
/* bcs 



*/
```

```swift
// bca 


```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
let aaaa = 0



```

```swift
struct AAAA {}




```

```swift
class BBBB {}



```

</details>



## Vertical Whitespace Between Cases

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`vertical_whitespace_between_cases` | Disabled | Yes | style | No | 3.0.0 

Include a single empty line between switch cases.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
    switch x {
    case .valid:
        print("multiple ...")
        print("... lines")

    case .invalid:
        print("multiple ...")
        print("... lines")
    }
```

```swift
    switch x {
    case .valid:
        print("x is valid")

    case .invalid:
        print("x is invalid")
    }
```

```swift
    switch x {
    case 0..<5:
        print("x is valid")

    default:
        print("x is invalid")
    }
```

```swift
switch x {

case 0..<5:
    print("x is low")

case 5..<10:
    print("x is high")

default:
    print("x is invalid")

}
```

```swift
switch x {
case 0..<5:
    print("x is low")

case 5..<10:
    print("x is high")

default:
    print("x is invalid")
}
```

```swift
switch x {
case 0..<5: print("x is low")
case 5..<10: print("x is high")
default: print("x is invalid")
}
```

```swift
switch x {    
case 1:    
    print("one")    
    
default:    
    print("not one")    
}    
```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
    switch x {
    case .valid:
        print("multiple ...")
        print("... lines")
↓    case .invalid:
        print("multiple ...")
        print("... lines")
    }
```

```swift
    switch x {
    case .valid:
        print("x is valid")
↓    case .invalid:
        print("x is invalid")
    }
```

```swift
    switch x {
    case 0..<5:
        print("x is valid")
↓    default:
        print("x is invalid")
    }
```

</details>



## Vertical Whitespace before Closing Braces

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`vertical_whitespace_closing_braces` | Disabled | Yes | style | No | 3.0.0 

Don't include vertical whitespace (empty line) before closing braces.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
        )
}
    }
}
```

```swift
    print("x is 5")
}
```

```swift
    print("x is 5")
}
```

```swift
    print("x is 5")
}
```

```swift
/*
    class X {

        let x = 5

    }
*/
```

```swift
[
1,
2,
3
]
```

```swift
[1, 2].map { $0 }.filter {
```

```swift
[1, 2].map { $0 }.filter { num in
```

```swift
class Name {
    run(5) { x in print(x) }
}
```

```swift
foo(
x: 5,
y:6
)
```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
        )
}
↓
    }
}
```

```swift
    print("x is 5")
↓

}
```

```swift
    print("x is 5")
↓
}
```

```swift
    print("x is 5")
↓    
}
```

```swift
[
1,
2,
3
↓
]
```

```swift
class Name {
    run(5) { x in print(x) }
↓
}
```

```swift
foo(
x: 5,
y:6
↓
)
```

</details>



## Vertical Whitespace after Opening Braces

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`vertical_whitespace_opening_braces` | Disabled | Yes | style | No | 3.0.0 

Don't include vertical whitespace (empty line) after opening braces.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
/*
    class X {

        let x = 5

    }
*/
```

```swift
// [1, 2].map { $0 }.filter { num in
```

```swift
KingfisherManager.shared.retrieveImage(with: url, options: nil, progressBlock: nil) { image, _, _, _ in
    guard let img = image else { return }
```

```swift
[
1,
2,
3
]
```

```swift
[1, 2].map { $0 }.filter { num in
```

```swift
[1, 2].map { $0 }.foo()
```

```swift
class Name {
    run(5) { x in print(x) }
}
```

```swift
class X {
    struct Y {
    class Z {

```

```swift
foo(
x: 5,
y:6
)
```

```swift
if x == 5 {
	print("x is 5")
```

```swift
if x == 5 {
    print("x is 5")
```

```swift
if x == 5 {
    print("x is 5")
```

```swift
if x == 5 {
  print("x is 5")
```

```swift
struct MyStruct {
	let x = 5
```

```swift
struct MyStruct {
    let x = 5
```

```swift
struct MyStruct {
  let x = 5
```

```swift
}) { _ in
    self.dismiss(animated: false, completion: {
```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
KingfisherManager.shared.retrieveImage(with: url, options: nil, progressBlock: nil) { image, _, _, _ in
↓
    guard let img = image else { return }
```

```swift
[
↓
1,
2,
3
]
```

```swift
class Name {
↓
    run(5) { x in print(x) }
}
```

```swift
class X {
    struct Y {
↓
    class Z {

```

```swift
foo(
↓
x: 5,
y:6
)
```

```swift
if x == 5 {
↓
	print("x is 5")
```

```swift
if x == 5 {
↓

    print("x is 5")
```

```swift
if x == 5 {
↓
    print("x is 5")
```

```swift
if x == 5 {
↓
  print("x is 5")
```

```swift
struct MyStruct {
↓
	let x = 5
```

```swift
struct MyStruct {
↓
    let x = 5
```

```swift
struct MyStruct {
↓
  let x = 5
```

```swift
}) { _ in
↓
    self.dismiss(animated: false, completion: {
```

</details>



## Void Return

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`void_return` | Enabled | Yes | style | No | 3.0.0 

Prefer `-> Void` over `-> ()`.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
let abc: () -> Void = {}

```

```swift
let abc: () -> (VoidVoid) = {}

```

```swift
func foo(completion: () -> Void)

```

```swift
let foo: (ConfigurationTests) -> () throws -> Void)

```

```swift
let foo: (ConfigurationTests) ->   () throws -> Void)

```

```swift
let foo: (ConfigurationTests) ->() throws -> Void)

```

```swift
let foo: (ConfigurationTests) -> () -> Void)

```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
let abc: () -> ↓() = {}

```

```swift
let abc: () -> ↓(Void) = {}

```

```swift
let abc: () -> ↓(   Void ) = {}

```

```swift
func foo(completion: () -> ↓())

```

```swift
func foo(completion: () -> ↓(   ))

```

```swift
func foo(completion: () -> ↓(Void))

```

```swift
let foo: (ConfigurationTests) -> () throws -> ↓())

```

</details>



## Weak Delegate

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`weak_delegate` | Enabled | No | lint | No | 3.0.0 

Delegates should be weak to avoid reference cycles.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
class Foo {
  weak var delegate: SomeProtocol?
}

```

```swift
class Foo {
  weak var someDelegate: SomeDelegateProtocol?
}

```

```swift
class Foo {
  weak var delegateScroll: ScrollDelegate?
}

```

```swift
class Foo {
  var scrollHandler: ScrollDelegate?
}

```

```swift
func foo() {
  var delegate: SomeDelegate
}

```

```swift
class Foo {
  var delegateNotified: Bool?
}

```

```swift
protocol P {
 var delegate: AnyObject? { get set }
}

```

```swift
class Foo {
 protocol P {
 var delegate: AnyObject? { get set }
}
}

```

```swift
class Foo {
 var computedDelegate: ComputedDelegate {
 return bar() 
} 
}
```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
class Foo {
  ↓var delegate: SomeProtocol?
}

```

```swift
class Foo {
  ↓var scrollDelegate: ScrollDelegate?
}

```

</details>



## XCTest Specific Matcher

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`xct_specific_matcher` | Disabled | No | idiomatic | No | 4.1.0 

Prefer specific XCTest matchers over `XCTAssertEqual` and `XCTAssertNotEqual`

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
XCTAssertFalse(foo)
```

```swift
XCTAssertTrue(foo)
```

```swift
XCTAssertNil(foo)
```

```swift
XCTAssertNotNil(foo)
```

```swift
XCTAssertEqual(foo, 2)
```

```swift
XCTAssertNotEqual(foo, "false")
```

```swift
XCTAssertEqual(foo, [1, 2, 3, true])
```

```swift
XCTAssertEqual(foo, [1, 2, 3, false])
```

```swift
XCTAssertEqual(foo, [1, 2, 3, nil])
```

```swift
XCTAssertEqual(foo, [true, nil, true, nil])
```

```swift
XCTAssertEqual([1, 2, 3, true], foo)
```

```swift
XCTAssertEqual([1, 2, 3, false], foo)
```

```swift
XCTAssertEqual([1, 2, 3, nil], foo)
```

```swift
XCTAssertEqual([true, nil, true, nil], foo)
```

```swift
XCTAssertEqual(2, foo)
```

```swift
XCTAssertNotEqual("false", foo)
```

```swift
XCTAssertEqual(false, foo?.bar)
```

```swift
XCTAssertEqual(true, foo?.bar)
```

```swift
XCTAssertFalse(  foo  )
```

```swift
XCTAssertTrue(  foo  )
```

```swift
XCTAssertNil(  foo  )
```

```swift
XCTAssertNotNil(  foo  )
```

```swift
XCTAssertEqual(  foo  , 2  )
```

```swift
XCTAssertNotEqual(  foo, "false")
```

```swift
XCTAssertEqual(foo?.bar, false)
```

```swift
XCTAssertEqual(foo?.bar, true)
```

```swift
XCTAssertNil(foo?.bar)
```

```swift
XCTAssertNotNil(foo?.bar)
```

```swift
XCTAssertEqual(foo?.bar, 2)
```

```swift
XCTAssertNotEqual(foo?.bar, "false")
```

```swift
XCTAssertEqual(foo?.bar, toto())
```

```swift
XCTAssertEqual(foo?.bar, .toto(.zoo))
```

```swift
XCTAssertEqual(toto(), foo?.bar)
```

```swift
XCTAssertEqual(.toto(.zoo), foo?.bar)
```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
↓XCTAssertEqual(foo, true)
```

```swift
↓XCTAssertEqual(foo, false)
```

```swift
↓XCTAssertEqual(foo, nil)
```

```swift
↓XCTAssertNotEqual(foo, true)
```

```swift
↓XCTAssertNotEqual(foo, false)
```

```swift
↓XCTAssertNotEqual(foo, nil)
```

```swift
↓XCTAssertEqual(true, foo)
```

```swift
↓XCTAssertEqual(false, foo)
```

```swift
↓XCTAssertEqual(nil, foo)
```

```swift
↓XCTAssertNotEqual(true, foo)
```

```swift
↓XCTAssertNotEqual(false, foo)
```

```swift
↓XCTAssertNotEqual(nil, foo)
```

```swift
↓XCTAssertEqual(foo, true, "toto")
```

```swift
↓XCTAssertEqual(foo, false, "toto")
```

```swift
↓XCTAssertEqual(foo, nil, "toto")
```

```swift
↓XCTAssertNotEqual(foo, true, "toto")
```

```swift
↓XCTAssertNotEqual(foo, false, "toto")
```

```swift
↓XCTAssertNotEqual(foo, nil, "toto")
```

```swift
↓XCTAssertEqual(true, foo, "toto")
```

```swift
↓XCTAssertEqual(false, foo, "toto")
```

```swift
↓XCTAssertEqual(nil, foo, "toto")
```

```swift
↓XCTAssertNotEqual(true, foo, "toto")
```

```swift
↓XCTAssertNotEqual(false, foo, "toto")
```

```swift
↓XCTAssertNotEqual(nil, foo, "toto")
```

```swift
↓XCTAssertEqual(foo,true)
```

```swift
↓XCTAssertEqual( foo , false )
```

```swift
↓XCTAssertEqual(  foo  ,  nil  )
```

```swift
↓XCTAssertEqual(true, [1, 2, 3, true].hasNumbers())
```

```swift
↓XCTAssertEqual([1, 2, 3, true].hasNumbers(), true)
```

```swift
↓XCTAssertEqual(foo?.bar, nil)
```

```swift
↓XCTAssertNotEqual(foo?.bar, nil)
```

```swift
↓XCTAssertEqual(nil, true)
```

```swift
↓XCTAssertEqual(nil, false)
```

```swift
↓XCTAssertEqual(true, nil)
```

```swift
↓XCTAssertEqual(false, nil)
```

```swift
↓XCTAssertEqual(nil, nil)
```

```swift
↓XCTAssertEqual(true, true)
```

```swift
↓XCTAssertEqual(false, false)
```

</details>



## XCTFail Message

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`xctfail_message` | Enabled | No | idiomatic | No | 3.0.0 

An XCTFail call should include a description of the assertion.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
func testFoo() {
  XCTFail("bar")
}
```

```swift
func testFoo() {
  XCTFail(bar)
}
```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
func testFoo() {
  ↓XCTFail()
}
```

```swift
func testFoo() {
  ↓XCTFail("")
}
```

</details>



## Yoda condition rule

Identifier | Enabled by default | Supports autocorrection | Kind | Analyzer | Minimum Swift Compiler Version
--- | --- | --- | --- | --- | ---
`yoda_condition` | Disabled | No | lint | No | 3.0.0 

The variable should be placed on the left, the constant on the right of a comparison operator.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
if foo == 42 {}

```

```swift
if foo <= 42.42 {}

```

```swift
guard foo >= 42 else { return }

```

```swift
guard foo != "str str" else { return }
```

```swift
while foo < 10 { }

```

```swift
while foo > 1 { }

```

```swift
while foo + 1 == 2
```

```swift
if optionalValue?.property ?? 0 == 2
```

```swift
if foo == nil
```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
↓if 42 == foo {}

```

```swift
↓if 42.42 >= foo {}

```

```swift
↓guard 42 <= foo else { return }

```

```swift
↓guard "str str" != foo else { return }
```

```swift
↓while 10 > foo { }
```

```swift
↓while 1 < foo { }
```

```swift
↓if nil == foo
```

</details>
