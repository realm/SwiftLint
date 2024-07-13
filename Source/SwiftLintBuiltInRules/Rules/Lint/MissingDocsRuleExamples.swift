struct MissingDocsRuleExamples {
    static let nonTriggeringExamples = [
        // locally-defined superclass member is documented, but subclass member is not
        Example("""
        /// docs
        public class A {
        /// docs
        public func b() {}
        }
        // no docs
        public class B: A { override public func b() {} }
        """),
        // externally-defined superclass member is documented, but subclass member is not
        Example("""
        import Foundation
        // no docs
        public class B: NSObject {
        // no docs
        override public var description: String { fatalError() } }
        """),
        Example("""
        /// docs
        public class A {
            var j = 1
            var i: Int { 1 }
            func f() {}
            deinit {}
        }
        """),
        Example("""
        public extension A {}
        """),
        Example("""
        enum E {
            case A
        }
        """),
        Example("""
        /// docs
        public class A {
            public init() {}
        }
        """, configuration: ["excludes_trivial_init": true]),
        Example("""
        class C {
            public func f() {}
        }
        """, configuration: ["evaluate_effective_access_control_level": true]),
        Example("""
        public struct S: ~Copyable, P {
            public init() {}
        }
        """),
        Example("""
        /// my doc
        #if os(macOS)
        public func f() {}
        #else
        public func f() async {}
        #endif
        """, excludeFromDocumentation: true),
        Example("""
        /// my doc
        #if os(macOS)
            #if is(iOS)
            public func f() {}
            #endif
        #else
        public func f() async {}
        #endif
        """, excludeFromDocumentation: true),
    ]

    static let triggeringExamples = [
        // public, undocumented
        Example("public ↓func a() {}"),
        // public, undocumented
        Example("// regular comment\npublic ↓func a() {}"),
        // public, undocumented
        Example("/* regular comment */\npublic ↓func a() {}"),
        // protocol member and inherited member are both undocumented
        Example("""
        /// docs
        public protocol A {
            // no docs
            ↓var b: Int { get }
        }
        /// docs
        public struct C: A {
            public let b: Int
        }
        """),
        // Violation marker is on `static` keyword.
        Example("""
        /// a doc
        public class C {
            public static ↓let i = 1
        }
        """),
        // `excludes_extensions` only excludes the extension declaration itself; not its children.
        Example("""
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
        """),
        Example("""
        public extension A {
            ↓enum E {
                enum Inner {
                    case a
                }
            }
        }
        """),
        Example("""
        extension E {
            public ↓struct S {
                public static ↓let i = 1
            }
        }
        """),
        Example("""
        extension E {
            public ↓func f() {}
        }
        """),
        Example("""
        /// docs
        public class A {
            public ↓init(argument: String) {}
        }
        """, configuration: ["excludes_trivial_init": true]),
        Example("""
        public ↓struct C: A {
            public ↓let b: Int
        }
        """, configuration: ["excludes_inherited_types": false]),
        Example("""
        public ↓extension A {
            public ↓func f() {}
        }
        """, configuration: ["excludes_extensions": false]),
        Example("""
        public extension E {
            ↓var i: Int {
                let j = 1
                func f() {}
                return j
            }
        }
        """),
        Example("""
        #if os(macOS)
        public ↓func f() {}
        #endif
        """),
        Example("""
        public ↓enum E {
            ↓case A, B
            func f() {}
            init(_ i: Int) { self = .A }
        }
        """),
        Example("""
        open ↓class C {
            public ↓enum E {
                ↓case A
                func f() {}
                init(_ i: Int) { self = .A }
            }
        }
        """, excludeFromDocumentation: true),
        /// Nested types inherit the ACL from the declaring extension.
        Example("""
        /// a doc
        public struct S {}
        public extension S {
            ↓enum E {
                ↓case A
            }
        }
        """),
        Example("""
        public extension URL {
            fileprivate enum E {
                static let source = ""
            }
            static ↓var a: Int { 1 }
        }
        """, excludeFromDocumentation: true),
        Example("""
        class C {
            public ↓func f() {}
        }
        """, configuration: ["evaluate_effective_access_control_level": false]),
        Example("""
        public ↓struct S: ~Copyable, ~Escapable {
            public ↓init() {}
        }
        """),
        Example("""
        /// my doc
        #if os(macOS)
        public func f() {}
        public ↓func g() {}
        #endif
        """, excludeFromDocumentation: true),
    ]
}
