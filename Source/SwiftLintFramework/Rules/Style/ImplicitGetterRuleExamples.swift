// swiftlint:disable:next type_body_length
struct ImplicitGetterRuleExamples {
    static var nonTriggeringExamples: [Example] {
        let commonExamples = [
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
            }
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
            }
            """),
            Example("""
            var next: Int? {
                mutating get {
                    defer { self.count += 1 }
                    return self.count
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
            extension Float {
                var clamped: Float {
                    set {
                        self = min(1, max(0, newValue))
                    }
                    get {
                        min(1, max(0, self))
                    }
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
            """)
        ]

        guard SwiftVersion.current >= .fourDotOne else {
            return commonExamples
        }

        return commonExamples + [
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
            """)
        ]
    }

    static var triggeringExamples: [Example] {
        let commonExamples = [
            Example("""
            class Foo {
                var foo: Int {
                    ↓get {
                        return 20
                    }
                }
            }
            """),
            Example("""
            class Foo {
                var foo: Int {
                    ↓get{ return 20 }
                }
            }
            """),
            Example("""
            class Foo {
                static var foo: Int {
                    ↓get {
                        return 20
                    }
                }
            }
            """),
            Example("""
            var foo: Int {
                ↓get { return 20 }
            }
            """),
            Example("""
            class Foo {
                @objc func bar() {}
                var foo: Int {
                    ↓get {
                        return 20
                    }
                }
            }
            """),
            Example("""
            extension Foo {
                var bar: Bool {
                    ↓get { _bar }
                }
            }
            """)
        ]

        guard SwiftVersion.current >= .fourDotOne else {
            return commonExamples
        }

        return commonExamples + [
            Example("""
            class Foo {
                subscript(i: Int) -> Int {
                    ↓get {
                        return 20
                    }
                }
            }
            """)
        ]
    }
}
