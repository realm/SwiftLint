struct UnusedImportRuleExamples {
    static let nonTriggeringExamples = [
        Example("""
        import Dispatch // This is used
        dispatchMain()
        """),
        Example("""
        @testable import Dispatch
        dispatchMain()
        """),
        Example("""
        import Foundation
        @objc
        class A {}
        """),
        Example("""
        import UnknownModule
        func foo(error: Swift.Error) {}
        """),
        Example("""
        import Foundation
        import ObjectiveC
        let 👨‍👩‍👧‍👦 = #selector(NSArray.contains(_:))
        👨‍👩‍👧‍👦 == 👨‍👩‍👧‍👦
        """)
    ]

    static let triggeringExamples = [
        Example("""
        ↓import Dispatch
        struct A {
          static func dispatchMain() {}
        }
        A.dispatchMain()
        """),
        Example("""
        ↓import Foundation // This is unused
        struct A {
          static func dispatchMain() {}
        }
        A.dispatchMain()
        ↓import Dispatch

        """),
        Example("""
        ↓import Foundation
        dispatchMain()
        """),
        Example("""
        ↓import Foundation
        // @objc
        class A {}
        """),
        Example("""
        ↓import Foundation
        import UnknownModule
        func foo(error: Swift.Error) {}
        """),
        Example("""
        ↓import Swift
        ↓import SwiftShims
        func foo(error: Swift.Error) {}
        """)
    ]

    static let corrections = [
        Example("""
        ↓import Dispatch
        struct A {
          static func dispatchMain() {}
        }
        A.dispatchMain()
        """):
            Example("""
            struct A {
              static func dispatchMain() {}
            }
            A.dispatchMain()
            """),
        Example("""
        ↓import Foundation // This is unused
        struct A {
          static func dispatchMain() {}
        }
        A.dispatchMain()
        ↓import Dispatch

        """):
            Example("""
            struct A {
              static func dispatchMain() {}
            }
            A.dispatchMain()

            """),
        Example("""
        ↓import Foundation
        dispatchMain()
        """):
            Example("""
            dispatchMain()
            """),
        Example("""
        ↓@testable import Foundation
        import Dispatch
        dispatchMain()
        """):
            Example("""
            import Dispatch
            dispatchMain()
            """),
        Example("""
        ↓@_exported import Foundation
        import Dispatch
        dispatchMain()
        """):
            Example("""
            import Dispatch
            dispatchMain()
            """),
        Example("""
        ↓import Foundation
        // @objc
        class A {}
        """):
            Example("""
            // @objc
            class A {}
            """),
        Example("""
        @testable import Foundation
        ↓import Dispatch
        @objc
        class A {}
        """):
            Example("""
            @testable import Foundation
            @objc
            class A {}
            """),
        Example("""
        @testable import Foundation
        ↓@testable import Dispatch
        @objc
        class A {}
        """):
            Example("""
            @testable import Foundation
            @objc
            class A {}
            """),
        Example("""
        ↓↓import Foundation
        typealias Foo = CFArray
        """, configuration: [
            "require_explicit_imports": true,
            "allowed_transitive_imports": [
                [
                    "module": "Foundation",
                    "allowed_transitive_imports": ["CoreFoundation"]
                ]
            ]
        ], testMultiByteOffsets: false, testOnLinux: false):
            Example("""
            import CoreFoundation
            typealias Foo = CFArray
            """),
        Example("""
        ↓↓import Foundation
        typealias Foo = CFData
        """, configuration: [
            "require_explicit_imports": true
        ], testMultiByteOffsets: false, testOnLinux: false):
            Example("""
            import CoreFoundation
            typealias Foo = CFData
            """),
        Example("""
        import Foundation
        typealias Foo = CFData
        @objc
        class A {}
        """, configuration: [
            "require_explicit_imports": true,
            "allowed_transitive_imports": [
                [
                    "module": "Foundation",
                    "allowed_transitive_imports": ["CoreFoundation"]
                ]
            ]
        ]):
            Example("""
            import Foundation
            typealias Foo = CFData
            @objc
            class A {}
            """),
        Example("""
        ↓import Foundation
        typealias Bar = CFData
        @objc
        class A {}
        """, configuration: [
            "require_explicit_imports": true
        ], testMultiByteOffsets: false, testOnLinux: false):
            Example("""
            import CoreFoundation
            import Foundation
            typealias Bar = CFData
            @objc
            class A {}
            """),
        Example("""
        import Foundation
        func bar() {}
        """, configuration: [
            "always_keep_imports": ["Foundation"]
        ]):
            Example("""
            import Foundation
            func bar() {}
            """),
        Example("""
        ↓import Swift
        ↓import SwiftShims
        func foo(error: Swift.Error) {}
        """):
            Example("""
            func foo(error: Swift.Error) {}
            """)
    ]
}
