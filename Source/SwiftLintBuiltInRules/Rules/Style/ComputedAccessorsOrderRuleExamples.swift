import SwiftLintCore

struct ComputedAccessorsOrderRuleExamples {
    static var nonTriggeringExamples: [Example] {
        #examples([
            """
            class Foo {
                var foo: Int {
                    get { return 3 }
                    set { _abc = newValue }
                }
            }
            """,
            """
            class Foo {
                var foo: Int {
                    return 20
                }
            }
            """,
            """
            class Foo {
                static var foo: Int {
                    return 20
                }
            }
            """,
            """
            class Foo {
                static var foo: Int {
                    get { return 3 }
                    set { _abc = newValue }
                }
            }
            """,
            """
            class Foo {
                var foo: Int
            }
            """,
            """
            class Foo {
                var foo: Int {
                    return getValueFromDisk()
                }
            }
            """,
            """
            class Foo {
                var foo: String {
                    return "get"
                }
            }
            """,
            """
            protocol Foo {
                var foo: Int { get }
            """,
            """
            protocol Foo {
                var foo: Int { get set }
            }
            """,
            """
            protocol Foo {
                var foo: Int { set get }
            """,
            """
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
            """,
            """
            var _objCTaggedPointerBits: UInt {
                @inline(__always) get { return 0 }
                set { print(newValue) }
            }
            """,
            """
            var next: Int? {
                mutating get {
                    defer { self.count += 1 }
                    return self.count
                }
                set {
                    self.count = newValue
                }
            }
            """,
            """
            extension Foo {
                var bar: Bool {
                    get { _bar }
                    set { self._bar = newValue }
                }
            }
            """,
            """
            extension Foo {
                var bar: Bool {
                    get { _bar }
                    set(newValue) { self._bar = newValue }
                }
            }
            """,
            """
            extension Reactive where Base: UITapGestureRecognizer {
                var tapped: CocoaAction<Base>? {
                    get {
                        return associatedAction.withValue { $0.flatMap { $0.action } }
                    }
                    nonmutating set {
                        setAction(newValue)
                    }
                }
            }
            """,
            """
            extension Test {
                var foo: Bool {
                    get {
                        bar?.boolValue ?? true // Comment mentioning word set which triggers violation
                    }
                    set {
                        bar = NSNumber(value: newValue as Bool)
                    }
                }
            }
            """,
            """
            class Foo {
                subscript(i: Int) -> Int {
                    return 20
                }
            }
            """,
            """
            class Foo {
                subscript(i: Int) -> Int {
                    get { return 3 }
                    set { _abc = newValue }
                }
            }
            """,
            """
            protocol Foo {
                subscript(i: Int) -> Int { get }
            }
            """,
            """
            protocol Foo {
                subscript(i: Int) -> Int { get set }
            }
            """,
            """
            protocol Foo {
                subscript(i: Int) -> Int { set get }
            }
            """,
        ])
    }

    static var triggeringExamples: [Example] {
        #examples([
            """
            class Foo {
                var foo: Int {
                    ↓set {
                        print(newValue)
                    }
                    get {
                        return 20
                    }
                }
            }
            """,
            """
            class Foo {
                static var foo: Int {
                    ↓set {
                        print(newValue)
                    }
                    get {
                        return 20
                    }
                }
            }
            """,
            """
            var foo: Int {
                ↓set { print(newValue) }
                get { return 20 }
            }
            """,
            """
            extension Foo {
                var bar: Bool {
                    ↓set { print(bar) }
                    get { _bar }
                }
            }
            """,
            """
            class Foo {
                var foo: Int {
                    ↓set {
                        print(newValue)
                    }
                    mutating get {
                        return 20
                    }
                }
            }
            """,
            """
            class Foo {
                subscript(i: Int) -> Int {
                    ↓set {
                        print(i)
                    }
                    get {
                        return 20
                    }
                }
            }
            """,
        ])
    }
}
