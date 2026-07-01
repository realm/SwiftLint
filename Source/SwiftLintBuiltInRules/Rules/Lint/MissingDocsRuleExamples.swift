struct MissingDocsRuleExamples {
    static let nonTriggeringExamples = #examples([
        // locally-defined superclass member is documented, but subclass member is not
        """
        /// docs
        public class A {
        /// docs
        public func b() {}
        }
        // no docs
        public class B: A { override public func b() {} }
        """,
        // externally-defined superclass member is documented, but subclass member is not
        """
        import Foundation
        // no docs
        public class B: NSObject {
        // no docs
        override public var description: String { fatalError() } }
        """,
        """
        /// docs
        public class A {
            var j = 1
            var i: Int { 1 }
            func f() {}
            deinit {}
        }
        """,
        """
        public extension A {}
        """,
        """
        enum E {
            case A
        }
        """,
        """
        /// docs
        public class A {
            public init() {}
        }
        """.configuration(["excludes_trivial_init": true]),
        """
        class C {
            public func f() {}
        }
        """.configuration(["evaluate_effective_access_control_level": true]),
        """
        public struct S: ~Copyable, P {
            public init() {}
        }
        """,
        """
        /// my doc
        #if os(macOS)
        public func f() {}
        #else
        public func f() async {}
        #endif
        """.excludeFromDocumentation(),
        """
        /// my doc
        #if os(macOS)
            #if is(iOS)
            public func f() {}
            #endif
        #else
        public func f() async {}
        #endif
        """.excludeFromDocumentation(),
    ])

    static let triggeringExamples = #examples([
        // public, undocumented
        "public ↓func a() {}",
        // public, undocumented
        "// regular comment\npublic ↓func a() {}",
        // public, undocumented
        "/* regular comment */\npublic ↓func a() {}",
        // protocol member and inherited member are both undocumented
        """
        /// docs
        public protocol A {
            // no docs
            ↓var b: Int { get }
        }
        /// docs
        public struct C: A {
            public let b: Int
        }
        """,
        // Violation marker is on `static` keyword.
        """
        /// a doc
        public class C {
            public static ↓let i = 1
        }
        """,
        // `excludes_extensions` only excludes the extension declaration itself; not its children.
        """
        public extension A {
            public ↓func f() {}
            static ↓var i: Int { 1 }
            ↓struct S {
                func f() {}
            }
            ↓class C {
                func f() {}
            }
            ↓actor A {
                func f() {}
            }
            ↓enum E {
                ↓case a
                func f() {}
            }
        }
        """,
        """
        public extension A {
            ↓enum E {
                enum Inner {
                    case a
                }
            }
        }
        """,
        """
        extension E {
            public ↓struct S {
                public static ↓let i = 1
            }
        }
        """,
        """
        extension E {
            public ↓func f() {}
        }
        """,
        """
        /// docs
        public class A {
            public ↓init(argument: String) {}
        }
        """.configuration(["excludes_trivial_init": true]),
        """
        public ↓struct C: A {
            public ↓let b: Int
        }
        """.configuration(["excludes_inherited_types": false]),
        """
        public ↓extension A {
            public ↓func f() {}
        }
        """.configuration(["excludes_extensions": false]),
        """
        public extension E {
            ↓var i: Int {
                let j = 1
                func f() {}
                return j
            }
        }
        """,
        """
        #if os(macOS)
        public ↓func f() {}
        #endif
        """,
        """
        public ↓enum E {
            ↓case A, B
            func f() {}
            init(_ i: Int) { self = .A }
        }
        """,
        """
        open ↓class C {
            public ↓enum E {
                ↓case A
                func f() {}
                init(_ i: Int) { self = .A }
            }
        }
        """.excludeFromDocumentation(),
        /// Nested types inherit the ACL from the declaring extension.
        """
        /// a doc
        public struct S {}
        public extension S {
            ↓enum E {
                ↓case A
            }
        }
        """,
        """
        public extension URL {
            fileprivate enum E {
                static let source = ""
            }
            static ↓var a: Int { 1 }
        }
        """.excludeFromDocumentation(),
        """
        class C {
            public ↓func f() {}
        }
        """.configuration(["evaluate_effective_access_control_level": false]),
        """
        public ↓struct S: ~Copyable, ~Escapable {
            public ↓init() {}
        }
        """,
        """
        /// my doc
        #if os(macOS)
        public func f() {}
        public ↓func g() {}
        #endif
        """.excludeFromDocumentation(),
    ])
}
