// swiftlint:disable file_length

// swiftlint:disable:next type_body_length
enum PreferSelfInStaticReferencesRuleExamples {
    static let nonTriggeringExamples = #examples([
        """
            class C {
                static let primes = [2, 3, 5, 7]
                func isPrime(i: Int) -> Bool { Self.primes.contains(i) }
            """,
        """
            struct T {
                static let i = 0
            }
            struct S {
                static let i = 0
            }
            extension T {
                static let j = S.i + T.i
                static let k = { T.j }()
            }
            """,
        """
            class `Self` {
                static let i = 0
                func f() -> Int { Self.i }
            }
            """,
        """
            class C {
                static private(set) var i = 0, j = C.i
                static let k = { C.i }()
                let h = C.i
                var n: Int = C.k { didSet { m += 1 } }
                @GreaterThan(C.j) var m: Int
            }
            """.excludeFromDocumentation(),
        """
            struct S {
                struct T {
                    struct R {
                        static let i = 3
                    }
                }
                struct R {
                    static let j = S.T.R.i
                }
                static let j = Self.T.R.i + Self.R.j
                let h = Self.T.R.i + Self.R.j
            }
            """.excludeFromDocumentation(),
        """
            class C {
                static let s = 2
                func f(i: Int = C.s) -> Int {
                    func g(@GreaterEqualThan(C.s) j: Int = C.s) -> Int { j }
                    return i + Self.s
                }
                func g() -> Any { C.self }
            }
            """.excludeFromDocumentation(),
        """
            struct Record<T> {
                static func get() -> Record<T> { Record<T>() }
            }
            """.excludeFromDocumentation(),
        """
            @objc class C: NSObject {
                @objc var s = ""
                @objc func f() { _ = #keyPath(C.s) }
            }
            """.excludeFromDocumentation(),
        """
            class C<T> {
                let i = 1
                let c: C = C()
                func f(c: C) -> KeyPath<C, Int> { \\Self.i }
            }
            """.excludeFromDocumentation(),
        """
            protocol P {}
            struct S: P {}
            extension P {
                func f<A>() -> some P where A: P { S() }
                func g<A: P>() -> some P { S() }
            }
            """.excludeFromDocumentation(),
        """
            class C<A> {
                func f() where A: C {}
                func g<B: C>() {}
            }
            """.excludeFromDocumentation(),
        """
            class C1<T> {}
            class C2: C1<C2> {}
            """.excludeFromDocumentation(),
        """
                class C1<T> {}
                class C2: C1<C2.C3> {
                    class C3 {}
                }
                """.excludeFromDocumentation(),
        """
            class C1<T> {}
            class C2: C1<C2.C3.C4> {
                class C3 {
                    class C4 {}
                }
            }
            """.excludeFromDocumentation(),
        """
            class S1<T> {
                class S2 {}
                func f() {
                    let s1 = S1<S1.S2>()
                    let s2 = S1<S1>()
                }
            }
            """.excludeFromDocumentation(),
        """
            struct S1 {
                struct S1 {}
                var s = S1()
            }
            """.excludeFromDocumentation(),
        """
            struct S1 {
                var s = S1()
                struct S1 {}
            }
            """.excludeFromDocumentation(),
        """
            class Foo {
                static let i = 0
            }
            class Bar {}
            extension Bar {
                func f() -> Int { Foo.i }
            }
            """.excludeFromDocumentation(),
        """
            class Outer {
                class Inner {
                    static let i = 0
                }
                class Other {
                    static let i = 0
                }
            }
            extension Outer.Inner {
                func f() -> Int { Outer.Other.i }
            }
            """.excludeFromDocumentation(),
        """
            enum Outer {
                static let i = 0
                struct Inner {
                    static let j = 0
                }
            }
            extension Outer.Inner {
                func f() -> Int { Outer.i }
            }
            """.excludeFromDocumentation(),
        """
            class Outer {
                class Inner<T> {
                    static let i = 0
                }
            }
            extension Outer.Inner {
                func f() { _ = Outer.Inner<Int>() }
                func g() { _ = Outer.Inner<Int>.i }
            }
            """.excludeFromDocumentation(),
        """
            protocol A {}
            extension A {
                func f(_ x: Any) -> Bool { x is any A }
            }
            """.excludeFromDocumentation(),
        """
            protocol A {}
            extension A {
                func f(_ x: Any) -> Bool { x is A.Protocol }
            }
            """.excludeFromDocumentation(),
        """
            protocol A {}
            protocol B {}
            extension A {
                func f(_ x: Any) -> Bool { x is any A & B }
            }
            """.excludeFromDocumentation(),
        """
            class Outer {
                class Inner {}
            }
            protocol B {}
            extension Outer.Inner {
                func f(_ x: Any) -> Bool { x is Outer.Inner & B }
            }
            """.excludeFromDocumentation(),
        """
            class A {}
            extension A {
                func f(_ x: Any) -> Bool { x is A }
                func g(_ x: Any) -> A? { x as? A }
            }
            """.excludeFromDocumentation(),
        """
            protocol A {}
            extension A {
                func f(_ x: Any) -> Bool { x is A.Type }
            }
            """.excludeFromDocumentation(),
        """
            class T {
                let child: T
                init(input: Any) {
                    child = (input as! T).child
                }
            }
            """.excludeFromDocumentation(),
    ])

    static let triggeringExamples = #examples([
        """
            final class CheckCellView: NSTableCellView {
                @IBOutlet var checkButton: NSButton!

                override func awakeFromNib() {
                checkButton.action = #selector(↓CheckCellView.check(_:))
                }

                @objc func check(_ button: AnyObject?) {}
            }
            """,
        """
            class C {
                static let i = 1
                var j: Int {
                    let ii = ↓C.i
                    return ii
                }
            }
            """,
        """
            class C {
                func f() {
                    _ = [↓C]()
                    _ = [Int: ↓C]()
                }
            }
            """,
        """
            struct S {
                let j: Int
                static let i = 1
                static func f() -> Int { ↓S.i }
                func g() -> Any { ↓S.self }
                func h() -> ↓S { ↓S(j: 2) }
                func i() -> KeyPath<↓S, Int> { \\↓S.j }
                func j(@Wrap(-↓S.i, ↓S.i) n: Int = ↓S.i) {}
            }
            """,
        """
            struct S {
                struct T {
                    static let i = 3
                }
                struct R {
                    static let j = S.T.i
                }
                static let h = ↓S.T.i + ↓S.R.j
            }
            """,
        """
            enum E {
                case A
                static func f() -> ↓E { ↓E.A }
                static func g() -> ↓E { ↓E.f() }
            }
            """,
        """
            extension E {
                class C {
                    static var i = 2
                    var j: Int { ↓C.i }
                    var k: Int {
                        get { ↓C.i }
                        set { ↓C.i = newValue }
                    }
                    var l: Int {
                        let ii = ↓C.i
                        return ii
                    }
                }
            }
            """.excludeFromDocumentation(),
        """
            class C {
                typealias A = C
                let d: C? = nil
                var c: C { C() }
                let b: [C] = [C]()
                init() {}
                func f(e: C) -> C {
                    let f: C = C()
                    return f
                }
                func g(a: [C]) -> [C] { a }
            }
            final class D {
                typealias A = D
                let c: D? = nil
                var d: D { D() }
                let b: [D] = [D]()
                init() {}
                func f(e: D) -> D {
                    let f: D = D()
                    return f
                }
                func g(a: [D]) -> [D] { a }
            }
            struct S {
                typealias A = ↓S
                // let s: S? = nil // Struct cannot contain itself
                var t: ↓S { ↓S() }
                let b: [↓S] = [↓S]()
                init() {}
                func f(e: ↓S) -> ↓S {
                    let f: ↓S = ↓S()
                    return f
                }
                func g(a: [↓S]) -> [↓S] { a }
            }
            """.excludeFromDocumentation(),
        """
            class C {
                static let i = 0
            }
            extension C {
                func f() -> Int { ↓C.i }
                var v: Int { ↓C.i }
            }
            """.excludeFromDocumentation(),
        """
            class Outer {
                class Inner {
                    static let i = 0
                }
            }
            extension Outer.Inner {
                func f() -> Int { ↓Outer.Inner.i }
            }
            """.excludeFromDocumentation(),
        """
            enum Outer {
                enum Middle {
                    struct Inner {
                        static let i = 0
                    }
                }
            }
            extension Outer.Middle.Inner {
                func f() -> Int { ↓Outer.Middle.Inner.i }
            }
            """.excludeFromDocumentation(),
    ])

    static let corrections = #corrections([
        """
            final class CheckCellView: NSTableCellView {
                @IBOutlet var checkButton: NSButton!

                override func awakeFromNib() {
                    checkButton.action = #selector(↓CheckCellView.check(_:))
                }

                @objc func check(_ button: AnyObject?) {}
            }
            """:
            """
                final class CheckCellView: NSTableCellView {
                    @IBOutlet var checkButton: NSButton!

                    override func awakeFromNib() {
                        checkButton.action = #selector(Self.check(_:))
                    }

                    @objc func check(_ button: AnyObject?) {}
                }
                """,
        """
            struct S {
                static let i = 1
                static let j = ↓S.i
                let k = ↓S  . j
                static func f(_ l: Int = ↓S.i) -> Int { l*↓S.j }
                func g() { ↓S.i + ↓S.f() + k }
            }
            """: """
                struct S {
                    static let i = 1
                    static let j = Self.i
                    let k = Self  . j
                    static func f(_ l: Int = Self.i) -> Int { l*Self.j }
                    func g() { Self.i + Self.f() + k }
                }
                """,
        """
            class C {
                static let i = 0
            }
            extension C {
                func f() -> Int { ↓C.i }
            }
            """: """
                class C {
                    static let i = 0
                }
                extension C {
                    func f() -> Int { Self.i }
                }
                """,
        """
            class Outer {
                class Inner {
                    static let i = 0
                }
            }
            extension Outer.Inner {
                func f() -> Int { ↓Outer.Inner.i }
            }
            """: """
                class Outer {
                    class Inner {
                        static let i = 0
                    }
                }
                extension Outer.Inner {
                    func f() -> Int { Self.i }
                }
                """,
    ])
}
