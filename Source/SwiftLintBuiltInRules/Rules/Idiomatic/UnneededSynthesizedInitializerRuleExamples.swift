// swiftlint:disable file_length
// swiftlint:disable:next type_name type_body_length
enum UnneededSynthesizedInitializerRuleExamples {
    static let nonTriggering = #examples([
        """
                struct Foo {
                    let bar: String

                    // Synthesized initializer would not be private.
                    private init(bar: String) {
                        self.bar = bar
                    }
                }
                """,
        """
                struct Foo {
                    var bar: String

                    // Synthesized initializer would not be private.
                    private init(bar: String) {
                        self.bar = bar
                    }
                }
                """,
        """
                struct Foo {
                    let bar: String

                    // Synthesized initializer would not be fileprivate.
                    fileprivate init(bar: String) {
                        self.bar = bar
                    }
                }
                """,
        """
                struct Foo {
                    let bar: String

                    // Synthesized initializer would not prepend "foo".
                    init(bar: String) {
                        self.bar = "foo" + bar
                    }
                }
                """,
        """
                internal struct Foo {
                    let bar: String

                    // Failable initializer
                    init?(bar: String) {
                        self.bar = bar
                    }
                }
                """,
        """
                internal struct Foo {
                    let bar: String

                    // Initializer throws
                    init(bar: String) throws {
                        self.bar = bar
                    }
                }
                """,
        """
                internal struct Foo {
                    let bar: String

                    // Different argument labels
                    init(_ bar: String) {
                        self.bar = bar
                    }
                }
                """,
        """
                internal struct Foo {
                    var bar: String = "foo"

                    // Different default values
                    init(bar: String = "bar") {
                        self.bar = bar
                    }
                }
                """,
        """
                internal struct Foo {
                    private static var bar: String

                    // var is static
                    init(bar: String) {
                        Self.bar = bar
                    }
                }
                """,
        """
                internal struct Foo {
                    private var bar: String

                    // var is private
                    init(bar: String) {
                        self.bar = bar
                    }
                }
                """,
        """
                internal struct Foo {
                    fileprivate var bar: String

                    // var is fileprivate
                    init(bar: String) {
                        self.bar = bar
                    }
                }
                """,
        """
                struct Foo {
                    var foo: String
                    var bar: String

                    // init has no body
                    init(foo: String, bar: String) {
                    }
                }
                """,
        """
                struct Foo {
                    var foo: String
                    var bar: String

                    // foo is not initialized
                    init(foo: String, bar: String) {
                        self.bar = bar
                    }
                }
                """,
        """
                struct Foo {
                    var foo: String
                    var bar: String

                    // Ordering of args is different from properties.
                    init(bar: String, foo: String) {
                        self.foo = foo
                        self.bar = bar
                    }
                }
                """,
        """
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
                """,
        """
                internal struct Foo {
                    var bar: String = ""
                    var baz: Int = 0

                    // These initializers must be declared.
                    init() { }

                    init(bar: String = "", baz: Int = 0) {
                        self.bar = bar
                        self.baz = baz
                    }

                    // Because manually declared initializers block
                    // synthesization.
                    init(bar: String) {
                        self.bar = bar
                    }
                }
                """,
        """
                struct Foo {
                    init() {
                        print("perform side effect")
                    }
                }
                """,
        """
                struct Foo {
                    var bar: Int = 0

                    init(bar: Int = 0) {
                        self.bar = bar
                        print("perform side effect")
                    }
                }
                """,
        """
                struct Foo {
                    var bar: Int

                    init(@Clamped bar: Int) {
                        self.bar = bar
                    }
                }
                """,
        """
                struct Foo {
                    let bar: Int

                    init(bar: Int) {
                        self.bar = bar
                    }
                    init?() {
                        return nil
                    }
                }
                """,
        // Treat conditional code as if it was active.
        """
        struct Foo {
            var bar: String

            init(bar: String) {
                self.bar = bar
            }

            #if DEBUG
            init() {
                self.bar = ""
            }
            #endif
        }
        """.excludeFromDocumentation(),
        """
        struct Foo {
            #if DEBUG
            var bar: String
            #endif

            init() {}
        }
        """.excludeFromDocumentation(),
        """
        struct Foo {
            @available(*, unavailable)
            init() {}
        }
        """,
    ])

    static let triggering = #examples([
        """
                struct Foo {
                    let bar: String

                   ↓init(bar: String) {
                        self.bar = bar
                    }
                }
                """,
        """
                struct Foo {
                    var bar: String

                   ↓init(bar: String) {
                        self.bar = bar
                    }
                }
                """,
        """
                private struct Foo {
                    let bar: String

                   ↓init(bar: String) {
                        self.bar = bar
                    }
                }
                """,
        """
                fileprivate struct Foo {
                    let bar: String

                   ↓init(bar: String) {
                        self.bar = bar
                    }
                }
                """,
        """
                internal struct Foo {
                    fileprivate var bar: String

                   ↓fileprivate init(bar: String) {
                        self.bar = bar
                    }
                }
                """,
        """
                internal struct Foo {
                    private var bar: String

                   ↓private init(bar: String) {
                        self.bar = bar
                    }
                }
                """,
        """
                struct Foo {
                    var foo: String
                    var bar: String

                   ↓init(foo: String, bar: String) {
                        self.foo = foo
                        self.bar = bar
                    }
                }
                """,
        """
                internal struct Foo {
                    var bar: String

                   ↓internal init(bar: String) {
                        self.bar = bar
                    }
                }
                """,
        """
                struct Foo {
                    var bar: String = ""

                   ↓init() {
                        // Empty initializer will be generated automatically
                        // when all vars have default values.
                    }
                }
                """,
        """
                struct Foo {
                    var bar: String = ""

                   ↓init() {
                        // Empty initializer
                    }

                   ↓init(bar: String = "") {
                        self.bar = bar
                    }
                }
                """,
        """
                struct Foo {
                    var bar = ""

                   ↓init(bar: String = "") {
                        self.bar = bar
                    }
                }
                """,
        """
                struct Outer {
                    struct Inner {
                        let prop: Int

                       ↓init(prop: Int) {
                            self.prop = prop
                        }
                    }
                }
                """,
        """
                class Foo {
                    struct Bar {
                        let baz: Int

                       ↓init(baz: Int) {
                            self.baz = baz
                        }
                    }
                }
                """,
        """
                struct Foo {
                    let i: Int
                    struct Bar {
                        let j: Int
                        ↓init(j: Int) {
                            self.j = j
                        }
                    }
                    ↓init(i: Int) {
                        self.i = i
                    }
                }
                """,
    ])

    static let corrections = #examplesDictionary([
        """
                struct Foo {
                    let bar: String

                   ↓init(bar: String) {
                        self.bar = bar
                    }

                    // A comment that should be preserved.
                    func baz() {
                        // Padding
                    }
                }
                """: """
                              struct Foo {
                                  let bar: String

                                  // A comment that should be preserved.
                                  func baz() {
                                      // Padding
                                  }
                              }
                              """,
        """
                struct Foo {
                    var bar: String

                   ↓init(bar: String) {
                        self.bar = bar
                    }
                }
                """: """
                              struct Foo {
                                  var bar: String
                              }
                              """,
        """
                private struct Foo {
                    let bar: String

                   ↓init(bar: String) {
                        self.bar = bar
                    }
                }
                """: """
                              private struct Foo {
                                  let bar: String
                              }
                              """,
        """
                fileprivate struct Foo {
                    let bar: String

                   ↓init(bar: String) {
                        self.bar = bar
                    }
                }
                """: """
                              fileprivate struct Foo {
                                  let bar: String
                              }
                              """,
        """
                internal struct Foo {
                    fileprivate var bar: String

                   ↓fileprivate init(bar: String) {
                        self.bar = bar
                    }
                }
                """: """
                              internal struct Foo {
                                  fileprivate var bar: String
                              }
                              """,
        """
                internal struct Foo {
                    private var bar: String

                   ↓private init(bar: String) {
                        self.bar = bar
                    }
                }
                """: """
                              internal struct Foo {
                                  private var bar: String
                              }
                              """,
        """
                struct Foo {
                    var foo: String
                    var bar: String

                   ↓init(foo: String, bar: String) {
                        self.foo = foo
                        self.bar = bar
                    }
                }
                """: """
                              struct Foo {
                                  var foo: String
                                  var bar: String
                              }
                              """,
        """
                internal struct Foo {
                    var bar: String

                   ↓internal init(bar: String) {
                        self.bar = bar
                    }
                }
                """: """
                              internal struct Foo {
                                  var bar: String
                              }
                              """,
        """
                struct Foo {
                    var bar: String = ""

                   ↓init() {
                        // Empty initializer will be generated automatically
                        // when all vars have default values.
                    }
                }
                """: """
                              struct Foo {
                                  var bar: String = ""
                              }
                              """,
        """
                struct Outer {
                    struct Inner {
                        let prop: Int

                       ↓init(prop: Int) {
                            self.prop = prop
                        }
                    }
                }
                """: """
                struct Outer {
                    struct Inner {
                        let prop: Int
                    }
                }
                """,
    ])
}
