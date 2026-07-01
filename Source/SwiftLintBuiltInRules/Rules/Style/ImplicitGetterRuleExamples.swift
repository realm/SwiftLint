import SwiftLintCore

struct ImplicitGetterRuleExamples {
    static let nonTriggeringExamples: [Example] = #examples([
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
                var foo: Int {
                    get { _foo }
                    _modify { yield &_foo }
                }
            }
            """,
        """
            class Foo {
                var _foo: Int
                var foo: Int {
                    @storageRestrictions(initializes: _foo)
                    init { _foo = newValue }
                    get { _foo }
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
            }
            """,
        """
            protocol Foo {
                var foo: Int { get set }
            }
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
            }
            """,
        """
            var next: Int? {
                mutating get {
                    defer { self.count += 1 }
                    return self.count
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
            class DatabaseEntity {
                var isSynced: Bool {
                    get async {
                        await database.isEntitySynced(self)
                    }
                }
            }
            """,
        """
            struct Test {
                subscript(value: Int) -> Int {
                    get throws {
                        if value == 0 {
                            throw NSError()
                        } else {
                            return value
                        }
                    }
                }
            }
            """,
    ])

    static let triggeringExamples: [Example] = #examples([
        """
            class Foo {
                var foo: Int {
                    ↓get {
                        return 20
                    }
                }
            }
            """,
        """
            class Foo {
                var foo: Int {
                    ↓get{ return 20 }
                }
            }
            """,
        """
            class Foo {
                static var foo: Int {
                    ↓get {
                        return 20
                    }
                }
            }
            """,
        """
            var foo: Int {
                ↓get { return 20 }
            }
            """,
        """
            class Foo {
                @objc func bar() {}
                var foo: Int {
                    ↓get {
                        return 20
                    }
                }
            }
            """,
        """
            extension Foo {
                var bar: Bool {
                    ↓get { _bar }
                }
            }
            """,
        """
            class Foo {
                subscript(i: Int) -> Int {
                    ↓get {
                        return 20
                    }
                }
            }
            """,
    ])
}
