// swiftlint:disable:next type_name
enum UnneededSynthesizedInitializerRuleExamples {
    static let nonTriggering = [
        Example("""
                struct Foo {
                    let bar: String

                    // synthesized initializer would not be private
                    private init(bar: String) {
                        self.bar = bar
                    }
                }
                """),
        Example("""
                struct Foo {
                    var bar: String

                    // synthesized initializer would not be private
                    private init(bar: String) {
                        self.bar = bar
                    }
                }
                """),
        Example("""
                struct Foo {
                    let bar: String

                    // synthesized initializer would not be fileprivate
                    fileprivate init(bar: String) {
                        self.bar = bar
                    }
                }
                """),
        Example("""
                struct Foo {
                    let bar: String

                    // synthesized initializer would not prepend "foo"
                    init(bar: String) {
                        self.bar = "foo" + bar
                    }
                }
                """),
        Example("""
                internal struct Foo {
                    let bar: String

                    // failable initializer
                    init?(bar: String) {
                        self.bar = bar
                    }
                }
                """),
        Example("""
                internal struct Foo {
                    let bar: String

                    // initializer throws
                    init(bar: String) throws {
                        self.bar = bar
                    }
                }
                """),
        Example("""
                internal struct Foo {
                    let bar: String

                    // different argument labels
                    init(_ bar: String) {
                        self.bar = bar
                    }
                }
                """),
        Example("""
                internal struct Foo {
                    var bar: String = "foo"

                    // different default values
                    init(bar: String = "bar") {
                        self.bar = bar
                    }
                }
                """),
        Example("""
                internal struct Foo {
                    private static var bar: String

                    // var is static
                    init(bar: String) {
                        Self.bar = bar
                    }
                }
                """),
        Example("""
                internal struct Foo {
                    private var bar: String

                    // var is private
                    init(bar: String) {
                        self.bar = bar
                    }
                }
                """),
        Example("""
                internal struct Foo {
                    fileprivate var bar: String

                    // var is fileprivate
                    init(bar: String) {
                        self.bar = bar
                    }
                }
                """),
        Example("""
                struct Foo {
                    var foo: String
                    var bar: String

                    // init has no body
                    init(foo: String, bar: String) {
                    }
                }
                """),
        Example("""
                struct Foo {
                    var foo: String
                    var bar: String

                    // foo is not initialized
                    init(foo: String, bar: String) {
                        self.bar = bar
                    }
                }
                """),
        Example("""
                struct Foo {
                    var foo: String
                    var bar: String

                    // ordering of args is different from properties
                    init(bar: String, foo: String) {
                        self.foo = foo
                        self.bar = bar
                    }
                }
                """),
        Example("""
                @frozen
                public struct Field {
                    @usableFromInline
                    let index: Int

                    @usableFromInline
                    let parent: Metadata

                    @inlinable // inlinable
                    init(index: Int, parent: Metadata) {
                       self.index = index
                       self.parent = parent
                    }
                }
                """)
    ]

    static let triggering = [
        Example("""
                struct Foo {
                    let bar: String

                   ↓init(bar: String) {
                        self.bar = bar
                    }
                }
                """),
        Example("""
                struct Foo {
                    var bar: String

                   ↓init(bar: String) {
                        self.bar = bar
                    }
                }
                """),
        Example("""
                struct Foo {
                    let bar: String

                   ↓init(bar: String) {
                        self.bar = bar
                    }
                }
                """),
        Example("""
                private struct Foo {
                    let bar: String

                   ↓init(bar: String) {
                        self.bar = bar
                    }
                }
                """),
        Example("""
                fileprivate struct Foo {
                    let bar: String

                   ↓init(bar: String) {
                        self.bar = bar
                    }
                }
                """),
        Example("""
                internal struct Foo {
                    fileprivate var bar: String

                   ↓fileprivate init(bar: String) {
                        self.bar = bar
                    }
                }
                """),
        Example("""
                internal struct Foo {
                    private var bar: String

                   ↓private init(bar: String) {
                        self.bar = bar
                    }
                }
                """),
        Example("""
                struct Foo {
                    var foo: String
                    var bar: String

                   ↓init(foo: String, bar: String) {
                        self.foo = foo
                        self.bar = bar
                    }
                }
                """),
        Example("""
                internal struct Foo {
                    var bar: String

                   ↓internal init(bar: String) {
                        self.bar = bar
                    }
                }
                """)
    ]
}
