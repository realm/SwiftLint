// swiftlint:disable:next type_body_length
struct ComputedAccessorsOrderRuleExamples {
    static var nonTriggeringExamples: [Example] {
        return [
            Example("""
            class Foo {
                var foo: Int {
                    get { return 3 }
                    set { _abc = newValue }
                }
            }
            """),
            Example("""
            class Foo {
                var foo: Int {
                    return 20
                }
            }
            """),
            Example("""
            class Foo {
                static var foo: Int {
                    return 20
                }
            }
            """),
            Example("""
            class Foo {
                static var foo: Int {
                    get { return 3 }
                    set { _abc = newValue }
                }
            }
            """),
            Example("""
            class Foo {
                var foo: Int
            }
            """),
            Example("""
            class Foo {
                var foo: Int {
                    return getValueFromDisk()
                }
            }
            """),
            Example("""
            class Foo {
                var foo: String {
                    return "get"
                }
            }
            """),
            Example("""
            protocol Foo {
                var foo: Int { get }
            """),
            Example("""
            protocol Foo {
                var foo: Int { get set }
            """),
            Example("""
            protocol Foo {
                var foo: Int { set get }
            """),
            Example("""
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
            """),
            Example("""
            var _objCTaggedPointerBits: UInt {
                @inline(__always) get { return 0 }
                set { print(newValue) }
            }
            """),
            Example("""
            var next: Int? {
                mutating get {
                    defer { self.count += 1 }
                    return self.count
                }
                set {
                    self.count = newValue
                }
            }
            """),
            Example("""
            extension Foo {
                var bar: Bool {
                    get { _bar }
                    set { self._bar = newValue }
                }
            }
            """),
            Example("""
            extension Foo {
                var bar: Bool {
                    get { _bar }
                    set(newValue) { self._bar = newValue }
                }
            }
            """),
            Example("""
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
            """),
            Example("""
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
            """),
            Example("""
            class Foo {
                subscript(i: Int) -> Int {
                    return 20
                }
            }
            """),
            Example("""
            class Foo {
                subscript(i: Int) -> Int {
                    get { return 3 }
                    set { _abc = newValue }
                }
            }
            """),
            Example("""
            protocol Foo {
                subscript(i: Int) -> Int { get }
            }
            """),
            Example("""
            protocol Foo {
                subscript(i: Int) -> Int { get set }
            }
            """),
            Example("""
            protocol Foo {
                subscript(i: Int) -> Int { set get }
            }
            """)
        ]
    }

    static var triggeringExamples: [Example] {
        return [
            Example("""
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
            """),
            Example("""
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
            """),
            Example("""
            var foo: Int {
                ↓set { print(newValue) }
                get { return 20 }
            }
            """),
            Example("""
            extension Foo {
                var bar: Bool {
                    ↓set { print(bar) }
                    get { _bar }
                }
            }
            """),
            Example("""
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
            """),
            Example("""
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
            """)
        ]
    }
}
