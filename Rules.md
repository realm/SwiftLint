
# Rules

* [Array Init](#array-init)
* [Attributes](#attributes)
* [Block Based KVO](#block-based-kvo)
* [Class Delegate Protocol](#class-delegate-protocol)
* [Closing Brace Spacing](#closing-brace-spacing)
* [Closure End Indentation](#closure-end-indentation)
* [Closure Parameter Position](#closure-parameter-position)
* [Closure Spacing](#closure-spacing)
* [Colon](#colon)
* [Comma Spacing](#comma-spacing)
* [Compiler Protocol Init](#compiler-protocol-init)
* [Conditional Returns on Newline](#conditional-returns-on-newline)
* [Contains over first not nil](#contains-over-first-not-nil)
* [Control Statement](#control-statement)
* [Custom Rules](#custom-rules)
* [Cyclomatic Complexity](#cyclomatic-complexity)
* [Discarded Notification Center Observer](#discarded-notification-center-observer)
* [Discouraged Direct Initialization](#discouraged-direct-initialization)
* [Dynamic Inline](#dynamic-inline)
* [Empty Count](#empty-count)
* [Empty Enum Arguments](#empty-enum-arguments)
* [Empty Parameters](#empty-parameters)
* [Empty Parentheses with Trailing Closure](#empty-parentheses-with-trailing-closure)
* [Explicit Enum Raw Value](#explicit-enum-raw-value)
* [Explicit Init](#explicit-init)
* [Explicit Top Level ACL](#explicit-top-level-acl)
* [Explicit Type Interface](#explicit-type-interface)
* [Extension Access Modifier](#extension-access-modifier)
* [Fallthrough](#fallthrough)
* [Fatal Error Message](#fatal-error-message)
* [File Header](#file-header)
* [File Line Length](#file-line-length)
* [First Where](#first-where)
* [For Where](#for-where)
* [Force Cast](#force-cast)
* [Force Try](#force-try)
* [Force Unwrapping](#force-unwrapping)
* [Function Body Length](#function-body-length)
* [Function Parameter Count](#function-parameter-count)
* [Generic Type Name](#generic-type-name)
* [Identifier Name](#identifier-name)
* [Implicit Getter](#implicit-getter)
* [Implicit Return](#implicit-return)
* [Implicitly Unwrapped Optional](#implicitly-unwrapped-optional)
* [Is Disjoint](#is-disjoint)
* [Joined Default Parameter](#joined-default-parameter)
* [Large Tuple](#large-tuple)
* [Leading Whitespace](#leading-whitespace)
* [Legacy CGGeometry Functions](#legacy-cggeometry-functions)
* [Legacy Constant](#legacy-constant)
* [Legacy Constructor](#legacy-constructor)
* [Legacy NSGeometry Functions](#legacy-nsgeometry-functions)
* [Variable Declaration Whitespace](#variable-declaration-whitespace)
* [Line Length](#line-length)
* [Literal Expression End Indentation](#literal-expression-end-indentation)
* [Mark](#mark)
* [Multiline Arguments](#multiline-arguments)
* [Multiline Parameters](#multiline-parameters)
* [Multiple Closures with Trailing Closure](#multiple-closures-with-trailing-closure)
* [Nesting](#nesting)
* [Nimble Operator](#nimble-operator)
* [No Extension Access Modifier](#no-extension-access-modifier)
* [No Grouping Extension](#no-grouping-extension)
* [Notification Center Detachment](#notification-center-detachment)
* [Number Separator](#number-separator)
* [Object Literal](#object-literal)
* [Opening Brace Spacing](#opening-brace-spacing)
* [Operator Usage Whitespace](#operator-usage-whitespace)
* [Operator Function Whitespace](#operator-function-whitespace)
* [Overridden methods call super](#overridden-methods-call-super)
* [Override in Extension](#override-in-extension)
* [Pattern Matching Keywords](#pattern-matching-keywords)
* [Private Outlets](#private-outlets)
* [Private over fileprivate](#private-over-fileprivate)
* [Private Unit Test](#private-unit-test)
* [Prohibited calls to super](#prohibited-calls-to-super)
* [Protocol Property Accessors Order](#protocol-property-accessors-order)
* [Quick Discouraged Call](#quick-discouraged-call)
* [Redundant Discardable Let](#redundant-discardable-let)
* [Redundant Nil Coalescing](#redundant-nil-coalescing)
* [Redundant Optional Initialization](#redundant-optional-initialization)
* [Redundant String Enum Value](#redundant-string-enum-value)
* [Redundant Void Return](#redundant-void-return)
* [Returning Whitespace](#returning-whitespace)
* [Shorthand Operator](#shorthand-operator)
* [Single Test Class](#single-test-class)
* [Sorted Imports](#sorted-imports)
* [Statement Position](#statement-position)
* [Strict fileprivate](#strict-fileprivate)
* [Superfluous Disable Command](#superfluous-disable-command)
* [Switch and Case Statement Alignment](#switch-and-case-statement-alignment)
* [Switch Case on Newline](#switch-case-on-newline)
* [Syntactic Sugar](#syntactic-sugar)
* [Todo](#todo)
* [Trailing Closure](#trailing-closure)
* [Trailing Comma](#trailing-comma)
* [Trailing Newline](#trailing-newline)
* [Trailing Semicolon](#trailing-semicolon)
* [Trailing Whitespace](#trailing-whitespace)
* [Type Body Length](#type-body-length)
* [Type Name](#type-name)
* [Unneeded Break in Switch](#unneeded-break-in-switch)
* [Unneeded Parentheses in Closure Argument](#unneeded-parentheses-in-closure-argument)
* [Unused Closure Parameter](#unused-closure-parameter)
* [Unused Enumerated](#unused-enumerated)
* [Unused Optional Binding](#unused-optional-binding)
* [Valid IBInspectable](#valid-ibinspectable)
* [Vertical Parameter Alignment](#vertical-parameter-alignment)
* [Vertical Parameter Alignment On Call](#vertical-parameter-alignment-on-call)
* [Vertical Whitespace](#vertical-whitespace)
* [Void Return](#void-return)
* [Weak Delegate](#weak-delegate)
* [XCTFail Message](#xctfail-message)
--------

## Array Init

Identifier | Enabled by default | Supports autocorrection | Kind 
--- | --- | --- | ---
`array_init` | Disabled | No | lint

Prefer using Array(seq) than seq.map { $0 } to convert a sequence into an Array.

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

</details>



## Attributes

Identifier | Enabled by default | Supports autocorrection | Kind 
--- | --- | --- | ---
`attributes` | Disabled | No | style

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

Identifier | Enabled by default | Supports autocorrection | Kind 
--- | --- | --- | ---
`block_based_kvo` | Enabled | No | idiomatic

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

Identifier | Enabled by default | Supports autocorrection | Kind 
--- | --- | --- | ---
`class_delegate_protocol` | Enabled | No | lint

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

Identifier | Enabled by default | Supports autocorrection | Kind 
--- | --- | --- | ---
`closing_brace` | Enabled | Yes | style

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



## Closure End Indentation

Identifier | Enabled by default | Supports autocorrection | Kind 
--- | --- | --- | ---
`closure_end_indentation` | Disabled | No | style

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

</details>



## Closure Parameter Position

Identifier | Enabled by default | Supports autocorrection | Kind 
--- | --- | --- | ---
`closure_parameter_position` | Enabled | No | style

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

Identifier | Enabled by default | Supports autocorrection | Kind 
--- | --- | --- | ---
`closure_spacing` | Disabled | Yes | style

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



## Colon

Identifier | Enabled by default | Supports autocorrection | Kind 
--- | --- | --- | ---
`colon` | Enabled | Yes | style

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
// 周斌佳年周斌佳
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

</details>



## Comma Spacing

Identifier | Enabled by default | Supports autocorrection | Kind 
--- | --- | --- | ---
`comma` | Enabled | Yes | style

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

Identifier | Enabled by default | Supports autocorrection | Kind 
--- | --- | --- | ---
`compiler_protocol_init` | Enabled | No | lint

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

Identifier | Enabled by default | Supports autocorrection | Kind 
--- | --- | --- | ---
`conditional_returns_on_newline` | Disabled | No | style

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

Identifier | Enabled by default | Supports autocorrection | Kind 
--- | --- | --- | ---
`contains_over_first_not_nil` | Disabled | No | performance

Prefer `contains` over `first(where:) != nil`

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
let first = myList.first(where: { $0 % 2 == 0 })

```

```swift
let first = myList.first { $0 % 2 == 0 }

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

</details>



## Control Statement

Identifier | Enabled by default | Supports autocorrection | Kind 
--- | --- | --- | ---
`control_statement` | Enabled | No | style

if,for,while,do statements shouldn't wrap their conditionals in parentheses.

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

</details>



## Custom Rules

Identifier | Enabled by default | Supports autocorrection | Kind 
--- | --- | --- | ---
`custom_rules` | Enabled | No | style

Create custom rules by providing a regex string. Optionally specify what syntax kinds to match against, the severity level, and what message to display.



## Cyclomatic Complexity

Identifier | Enabled by default | Supports autocorrection | Kind 
--- | --- | --- | ---
`cyclomatic_complexity` | Enabled | No | metrics

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



## Discarded Notification Center Observer

Identifier | Enabled by default | Supports autocorrection | Kind 
--- | --- | --- | ---
`discarded_notification_center_observer` | Enabled | No | lint

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

Identifier | Enabled by default | Supports autocorrection | Kind 
--- | --- | --- | ---
`discouraged_direct_init` | Enabled | No | lint

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



## Dynamic Inline

Identifier | Enabled by default | Supports autocorrection | Kind 
--- | --- | --- | ---
`dynamic_inline` | Enabled | No | lint

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

Identifier | Enabled by default | Supports autocorrection | Kind 
--- | --- | --- | ---
`empty_count` | Disabled | No | performance

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
↓count == 0

```

</details>



## Empty Enum Arguments

Identifier | Enabled by default | Supports autocorrection | Kind 
--- | --- | --- | ---
`empty_enum_arguments` | Enabled | Yes | style

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

</details>



## Empty Parameters

Identifier | Enabled by default | Supports autocorrection | Kind 
--- | --- | --- | ---
`empty_parameters` | Enabled | Yes | style

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

Identifier | Enabled by default | Supports autocorrection | Kind 
--- | --- | --- | ---
`empty_parentheses_with_trailing_closure` | Enabled | Yes | style

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

</details>



## Explicit Enum Raw Value

Identifier | Enabled by default | Supports autocorrection | Kind 
--- | --- | --- | ---
`explicit_enum_raw_value` | Disabled | No | idiomatic

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

Identifier | Enabled by default | Supports autocorrection | Kind 
--- | --- | --- | ---
`explicit_init` | Disabled | Yes | idiomatic

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

</details>
<details>
<summary>Triggering Examples</summary>

```swift
[1].flatMap{String↓.init($0)}
```

```swift
[String.self].map { Type in Type↓.init(1) }
```

</details>



## Explicit Top Level ACL

Identifier | Enabled by default | Supports autocorrection | Kind 
--- | --- | --- | ---
`explicit_top_level_acl` | Disabled | No | idiomatic

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

Identifier | Enabled by default | Supports autocorrection | Kind 
--- | --- | --- | ---
`explicit_type_interface` | Disabled | No | idiomatic

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

</details>



## Extension Access Modifier

Identifier | Enabled by default | Supports autocorrection | Kind 
--- | --- | --- | ---
`extension_access_modifier` | Disabled | No | idiomatic

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

Identifier | Enabled by default | Supports autocorrection | Kind 
--- | --- | --- | ---
`fallthrough` | Enabled | No | idiomatic

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

Identifier | Enabled by default | Supports autocorrection | Kind 
--- | --- | --- | ---
`fatal_error_message` | Disabled | No | idiomatic

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

Identifier | Enabled by default | Supports autocorrection | Kind 
--- | --- | --- | ---
`file_header` | Disabled | No | style

Header comments should be consistent with project patterns.

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

Identifier | Enabled by default | Supports autocorrection | Kind 
--- | --- | --- | ---
`file_length` | Enabled | No | metrics

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



## First Where

Identifier | Enabled by default | Supports autocorrection | Kind 
--- | --- | --- | ---
`first_where` | Disabled | No | performance

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

</details>



## For Where

Identifier | Enabled by default | Supports autocorrection | Kind 
--- | --- | --- | ---
`for_where` | Enabled | No | idiomatic

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

Identifier | Enabled by default | Supports autocorrection | Kind 
--- | --- | --- | ---
`force_cast` | Enabled | No | idiomatic

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

Identifier | Enabled by default | Supports autocorrection | Kind 
--- | --- | --- | ---
`force_try` | Enabled | No | idiomatic

Force tries should be avoided.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
func a() throws {}; do { try a() } catch {}
```

</details>
<details>
<summary>Triggering Examples</summary>

```swift
func a() throws {}; ↓try! a()
```

</details>



## Force Unwrapping

Identifier | Enabled by default | Supports autocorrection | Kind 
--- | --- | --- | ---
`force_unwrapping` | Disabled | No | idiomatic

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

</details>



## Function Body Length

Identifier | Enabled by default | Supports autocorrection | Kind 
--- | --- | --- | ---
`function_body_length` | Enabled | No | metrics

Functions bodies should not span too many lines.



## Function Parameter Count

Identifier | Enabled by default | Supports autocorrection | Kind 
--- | --- | --- | ---
`function_parameter_count` | Enabled | No | metrics

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

Identifier | Enabled by default | Supports autocorrection | Kind 
--- | --- | --- | ---
`generic_type_name` | Enabled | No | idiomatic

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
typealias DictionaryOfStrings<↓T_Foo: Hashable> = Dictionary<T, String>

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



## Identifier Name

Identifier | Enabled by default | Supports autocorrection | Kind 
--- | --- | --- | ---
`identifier_name` | Enabled | No | style

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

Identifier | Enabled by default | Supports autocorrection | Kind 
--- | --- | --- | ---
`implicit_getter` | Enabled | No | style

Computed read-only properties should avoid using the get keyword.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
class Foo {
  var foo: Int {
 get {
 return 3
}
 set {
 _abc = newValue 
}
}
}

```

```swift
class Foo {
  var foo: Int {
 return 20 
} 
}
}

```

```swift
class Foo {
  static var foo: Int {
 return 20 
} 
}
}

```

```swift
class Foo {
  static foo: Int {
 get {
 return 3
}
 set {
 _abc = newValue 
}
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
}

```

```swift
class Foo {
  var foo: String {
 return "get" 
} 
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
}

```

```swift
class Foo {
  var foo: Int {
 ↓get{
 return 20 
} 
} 
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
}

```

```swift
var foo: Int {
 ↓get {
 return 20 
} 
} 
}
```

```swift
class Foo {
  @objc func bar() { }
var foo: Int {
 ↓get {
 return 20 
} 
} 
}
}

```

</details>



## Implicit Return

Identifier | Enabled by default | Supports autocorrection | Kind 
--- | --- | --- | ---
`implicit_return` | Disabled | Yes | style

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

</details>



## Implicitly Unwrapped Optional

Identifier | Enabled by default | Supports autocorrection | Kind 
--- | --- | --- | ---
`implicitly_unwrapped_optional` | Disabled | No | idiomatic

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



## Is Disjoint

Identifier | Enabled by default | Supports autocorrection | Kind 
--- | --- | --- | ---
`is_disjoint` | Enabled | No | idiomatic

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

Identifier | Enabled by default | Supports autocorrection | Kind 
--- | --- | --- | ---
`joined_default_parameter` | Disabled | Yes | idiomatic

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
             .joined(↓separator: "")
```

</details>



## Large Tuple

Identifier | Enabled by default | Supports autocorrection | Kind 
--- | --- | --- | ---
`large_tuple` | Enabled | No | metrics

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



## Leading Whitespace

Identifier | Enabled by default | Supports autocorrection | Kind 
--- | --- | --- | ---
`leading_whitespace` | Enabled | Yes | style

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

Identifier | Enabled by default | Supports autocorrection | Kind 
--- | --- | --- | ---
`legacy_cggeometry_functions` | Enabled | Yes | idiomatic

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

Identifier | Enabled by default | Supports autocorrection | Kind 
--- | --- | --- | ---
`legacy_constant` | Enabled | Yes | idiomatic

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

Identifier | Enabled by default | Supports autocorrection | Kind 
--- | --- | --- | ---
`legacy_constructor` | Enabled | Yes | idiomatic

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

</details>



## Legacy NSGeometry Functions

Identifier | Enabled by default | Supports autocorrection | Kind 
--- | --- | --- | ---
`legacy_nsgeometry_functions` | Enabled | Yes | idiomatic

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



## Variable Declaration Whitespace

Identifier | Enabled by default | Supports autocorrection | Kind 
--- | --- | --- | ---
`let_var_whitespace` | Disabled | No | style

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

Identifier | Enabled by default | Supports autocorrection | Kind 
--- | --- | --- | ---
`line_length` | Enabled | No | metrics

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

Identifier | Enabled by default | Supports autocorrection | Kind 
--- | --- | --- | ---
`literal_expression_end_indentation` | Disabled | No | style

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



## Mark

Identifier | Enabled by default | Supports autocorrection | Kind 
--- | --- | --- | ---
`mark` | Enabled | Yes | lint

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
↓//MARK:- Top-Level bad mark
↓//MARK:- Another bad mark
struct MarkTest {}
↓// MARK:- Bad mark
extension MarkTest {}

```

</details>



## Multiline Arguments

Identifier | Enabled by default | Supports autocorrection | Kind 
--- | --- | --- | ---
`multiline_arguments` | Disabled | No | style

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



## Multiline Parameters

Identifier | Enabled by default | Supports autocorrection | Kind 
--- | --- | --- | ---
`multiline_parameters` | Disabled | No | style

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

</details>



## Multiple Closures with Trailing Closure

Identifier | Enabled by default | Supports autocorrection | Kind 
--- | --- | --- | ---
`multiple_closures_with_trailing_closure` | Enabled | No | style

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

Identifier | Enabled by default | Supports autocorrection | Kind 
--- | --- | --- | ---
`nesting` | Enabled | No | metrics

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

Identifier | Enabled by default | Supports autocorrection | Kind 
--- | --- | --- | ---
`nimble_operator` | Disabled | Yes | idiomatic

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
expect(object.asyncFunction()).toEventually(equal(1))

```

```swift
expect(actual).to(haveCount(expected))

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
expect(10) > 2
 ↓expect(10).to(beGreaterThan(2))

```

</details>



## No Extension Access Modifier

Identifier | Enabled by default | Supports autocorrection | Kind 
--- | --- | --- | ---
`no_extension_access_modifier` | Disabled | No | idiomatic

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



## No Grouping Extension

Identifier | Enabled by default | Supports autocorrection | Kind 
--- | --- | --- | ---
`no_grouping_extension` | Disabled | No | idiomatic

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

Identifier | Enabled by default | Supports autocorrection | Kind 
--- | --- | --- | ---
`notification_center_detachment` | Enabled | No | lint

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



## Number Separator

Identifier | Enabled by default | Supports autocorrection | Kind 
--- | --- | --- | ---
`number_separator` | Disabled | Yes | style

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

</details>



## Object Literal

Identifier | Enabled by default | Supports autocorrection | Kind 
--- | --- | --- | ---
`object_literal` | Disabled | No | idiomatic

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

Identifier | Enabled by default | Supports autocorrection | Kind 
--- | --- | --- | ---
`opening_brace` | Enabled | Yes | style

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

Identifier | Enabled by default | Supports autocorrection | Kind 
--- | --- | --- | ---
`operator_usage_whitespace` | Disabled | Yes | style

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

Identifier | Enabled by default | Supports autocorrection | Kind 
--- | --- | --- | ---
`operator_whitespace` | Enabled | No | style

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

Identifier | Enabled by default | Supports autocorrection | Kind 
--- | --- | --- | ---
`overridden_super_call` | Disabled | No | lint

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

Identifier | Enabled by default | Supports autocorrection | Kind 
--- | --- | --- | ---
`override_in_extension` | Disabled | No | lint

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

Identifier | Enabled by default | Supports autocorrection | Kind 
--- | --- | --- | ---
`pattern_matching_keywords` | Disabled | No | idiomatic

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



## Private Outlets

Identifier | Enabled by default | Supports autocorrection | Kind 
--- | --- | --- | ---
`private_outlet` | Disabled | No | lint

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

Identifier | Enabled by default | Supports autocorrection | Kind 
--- | --- | --- | ---
`private_over_fileprivate` | Enabled | Yes | idiomatic

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

Identifier | Enabled by default | Supports autocorrection | Kind 
--- | --- | --- | ---
`private_unit_test` | Enabled | No | lint

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



## Prohibited calls to super

Identifier | Enabled by default | Supports autocorrection | Kind 
--- | --- | --- | ---
`prohibited_super_call` | Disabled | No | lint

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
		self.method1()	}
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
	override func providePlaceholder(at url: URL,completionHandler: @escaping (Error?) -> Void) {↓
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

Identifier | Enabled by default | Supports autocorrection | Kind 
--- | --- | --- | ---
`protocol_property_accessors_order` | Enabled | Yes | style

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

Identifier | Enabled by default | Supports autocorrection | Kind 
--- | --- | --- | ---
`quick_discouraged_call` | Disabled | No | lint

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

</details>



## Redundant Discardable Let

Identifier | Enabled by default | Supports autocorrection | Kind 
--- | --- | --- | ---
`redundant_discardable_let` | Enabled | Yes | style

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

Identifier | Enabled by default | Supports autocorrection | Kind 
--- | --- | --- | ---
`redundant_nil_coalescing` | Disabled | Yes | idiomatic

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



## Redundant Optional Initialization

Identifier | Enabled by default | Supports autocorrection | Kind 
--- | --- | --- | ---
`redundant_optional_initialization` | Enabled | Yes | idiomatic

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

</details>



## Redundant String Enum Value

Identifier | Enabled by default | Supports autocorrection | Kind 
--- | --- | --- | ---
`redundant_string_enum_value` | Enabled | No | idiomatic

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



## Redundant Void Return

Identifier | Enabled by default | Supports autocorrection | Kind 
--- | --- | --- | ---
`redundant_void_return` | Enabled | Yes | idiomatic

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



## Returning Whitespace

Identifier | Enabled by default | Supports autocorrection | Kind 
--- | --- | --- | ---
`return_arrow_whitespace` | Enabled | Yes | style

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

Identifier | Enabled by default | Supports autocorrection | Kind 
--- | --- | --- | ---
`shorthand_operator` | Enabled | No | style

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

Identifier | Enabled by default | Supports autocorrection | Kind 
--- | --- | --- | ---
`single_test_class` | Disabled | No | style

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



## Sorted Imports

Identifier | Enabled by default | Supports autocorrection | Kind 
--- | --- | --- | ---
`sorted_imports` | Disabled | No | style

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

</details>
<details>
<summary>Triggering Examples</summary>

```swift
import AAA
import ZZZ
import ↓BBB
import CCC
```

</details>



## Statement Position

Identifier | Enabled by default | Supports autocorrection | Kind 
--- | --- | --- | ---
`statement_position` | Enabled | Yes | style

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



## Strict fileprivate

Identifier | Enabled by default | Supports autocorrection | Kind 
--- | --- | --- | ---
`strict_fileprivate` | Disabled | No | idiomatic

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



## Superfluous Disable Command

Identifier | Enabled by default | Supports autocorrection | Kind 
--- | --- | --- | ---
`superfluous_disable_command` | Enabled | No | lint

SwiftLint 'disable' commands are superfluous when the disabled rule would not have triggered a violation in the disabled region.



## Switch and Case Statement Alignment

Identifier | Enabled by default | Supports autocorrection | Kind 
--- | --- | --- | ---
`switch_case_alignment` | Enabled | No | style

Case statements should vertically align with the enclosing switch statement.

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

```swift
switch someInt {
    ↓case 0:
    print('Zero')
case 1:
    print('One')
    ↓default:
    print('Some other number')
}
```

</details>



## Switch Case on Newline

Identifier | Enabled by default | Supports autocorrection | Kind 
--- | --- | --- | ---
`switch_case_on_newline` | Disabled | No | style

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

Identifier | Enabled by default | Supports autocorrection | Kind 
--- | --- | --- | ---
`syntactic_sugar` | Enabled | No | idiomatic

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

Identifier | Enabled by default | Supports autocorrection | Kind 
--- | --- | --- | ---
`todo` | Enabled | No | lint

TODOs and FIXMEs should be avoided.

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



## Trailing Closure

Identifier | Enabled by default | Supports autocorrection | Kind 
--- | --- | --- | ---
`trailing_closure` | Disabled | No | style

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

Identifier | Enabled by default | Supports autocorrection | Kind 
--- | --- | --- | ---
`trailing_comma` | Enabled | Yes | style

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

</details>



## Trailing Newline

Identifier | Enabled by default | Supports autocorrection | Kind 
--- | --- | --- | ---
`trailing_newline` | Enabled | Yes | style

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

Identifier | Enabled by default | Supports autocorrection | Kind 
--- | --- | --- | ---
`trailing_semicolon` | Enabled | Yes | idiomatic

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

Identifier | Enabled by default | Supports autocorrection | Kind 
--- | --- | --- | ---
`trailing_whitespace` | Enabled | Yes | style

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

Identifier | Enabled by default | Supports autocorrection | Kind 
--- | --- | --- | ---
`type_body_length` | Enabled | No | metrics

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



## Type Name

Identifier | Enabled by default | Supports autocorrection | Kind 
--- | --- | --- | ---
`type_name` | Enabled | No | idiomatic

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
↓class myType {}
```

```swift
↓class _MyType {}
```

```swift
private ↓class MyType_ {}
```

```swift
↓class My {}
```

```swift
↓class AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA {}
```

```swift
↓struct myType {}
```

```swift
↓struct _MyType {}
```

```swift
private ↓struct MyType_ {}
```

```swift
↓struct My {}
```

```swift
↓struct AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA {}
```

```swift
↓enum myType {}
```

```swift
↓enum _MyType {}
```

```swift
private ↓enum MyType_ {}
```

```swift
↓enum My {}
```

```swift
↓enum AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA {}
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



## Unneeded Break in Switch

Identifier | Enabled by default | Supports autocorrection | Kind 
--- | --- | --- | ---
`unneeded_break_in_switch` | Enabled | No | idiomatic

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

Identifier | Enabled by default | Supports autocorrection | Kind 
--- | --- | --- | ---
`unneeded_parentheses_in_closure_argument` | Disabled | Yes | style

Parentheses are not needed when declaring closure arguments.

### Examples

<details>
<summary>Non Triggering Examples</summary>

```swift
let foo = { (bar: Int) in }

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
let foo = { ↓(bar) -> Bool in return true }

```

```swift
foo.map { ($0, $0) }.forEach { ↓(x, y) in }
```

```swift
foo.bar { [weak self] ↓(x, y) in }
```

</details>



## Unused Closure Parameter

Identifier | Enabled by default | Supports autocorrection | Kind 
--- | --- | --- | ---
`unused_closure_parameter` | Enabled | Yes | lint

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

</details>



## Unused Enumerated

Identifier | Enabled by default | Supports autocorrection | Kind 
--- | --- | --- | ---
`unused_enumerated` | Enabled | No | idiomatic

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



## Unused Optional Binding

Identifier | Enabled by default | Supports autocorrection | Kind 
--- | --- | --- | ---
`unused_optional_binding` | Enabled | No | style

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



## Valid IBInspectable

Identifier | Enabled by default | Supports autocorrection | Kind 
--- | --- | --- | ---
`valid_ibinspectable` | Enabled | No | lint

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

Identifier | Enabled by default | Supports autocorrection | Kind 
--- | --- | --- | ---
`vertical_parameter_alignment` | Enabled | No | style

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

Identifier | Enabled by default | Supports autocorrection | Kind 
--- | --- | --- | ---
`vertical_parameter_alignment_on_call` | Disabled | No | style

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

</details>



## Vertical Whitespace

Identifier | Enabled by default | Supports autocorrection | Kind 
--- | --- | --- | ---
`vertical_whitespace` | Enabled | Yes | style

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



## Void Return

Identifier | Enabled by default | Supports autocorrection | Kind 
--- | --- | --- | ---
`void_return` | Enabled | Yes | style

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

Identifier | Enabled by default | Supports autocorrection | Kind 
--- | --- | --- | ---
`weak_delegate` | Enabled | No | lint

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



## XCTFail Message

Identifier | Enabled by default | Supports autocorrection | Kind 
--- | --- | --- | ---
`xctfail_message` | Enabled | No | idiomatic

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
