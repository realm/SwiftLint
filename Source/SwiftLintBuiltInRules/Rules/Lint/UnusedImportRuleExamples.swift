struct UnusedImportRuleExamples {
    static let nonTriggeringExamples = #examples([
        """
        import Dispatch // This is used
        dispatchMain()
        """,
        """
        @testable import Dispatch
        dispatchMain()
        """,
        """
        import Foundation
        @objc
        class A {}
        """,
        """
        import UnknownModule
        func foo(error: Swift.Error) {}
        """,
        """
        @_exported import UnknownModule
        """,
        """
        import Foundation
        let 👨‍👩‍👧‍👦 = #selector(NSArray.contains(_:))
        👨‍👩‍👧‍👦 == 👨‍👩‍👧‍👦
        """,
        """
        import Foundation
        enum E {
            static let min: CGFloat = 44
        }
        """.configuration([
            "allowed_transitive_imports": [
                [
                    "module": "Foundation",
                    "allowed_transitive_imports": ["CoreFoundation"],
                ] as [String: any Sendable],
            ],
        ]),
        """
        import SwiftUI

        final class EditMode: ObservableObject {
            @Published var isEditing = false
        }
        """.configuration([
            "allowed_transitive_imports": [
                [
                    "module": "SwiftUI",
                    "allowed_transitive_imports": ["Foundation"],
                ] as [String: any Sendable],
            ],
        ]).excludeFromDocumentation(),
    ])

    static let triggeringExamples = #examples([
        """
        ↓import Dispatch
        struct A {
          static func dispatchMain() {}
        }
        A.dispatchMain()
        """,
        """
        ↓import Foundation // This is unused
        struct A {
          static func dispatchMain() {}
        }
        A.dispatchMain()
        ↓import Dispatch

        """,
        """
        ↓import Foundation
        dispatchMain()
        """,
        """
        ↓import Foundation
        // @objc
        class A {}
        """,
        """
        ↓public import Foundation
        import UnknownModule
        func foo(error: Swift.Error) {}
        """,
        """
        ↓internal import Swift
        ↓private import SwiftShims
        func foo(error: Swift.Error) {}
        """,
    ])

    static let corrections = #examplesDictionary([
        """
        ↓import Dispatch
        struct A {
          static func dispatchMain() {}
        }
        A.dispatchMain()
        """:
            """
            struct A {
              static func dispatchMain() {}
            }
            A.dispatchMain()
            """,
        """
        ↓import Foundation // This is unused
        struct A {
          static func dispatchMain() {}
        }
        A.dispatchMain()
        ↓import Dispatch

        """:
            """
            struct A {
              static func dispatchMain() {}
            }
            A.dispatchMain()

            """,
        """
        ↓import Foundation
        dispatchMain()
        """:
            """
            dispatchMain()
            """,
        """
        ↓@testable import Foundation
        import Dispatch
        dispatchMain()
        """:
            """
            import Dispatch
            dispatchMain()
            """,
        """
        ↓@_implementationOnly import Foundation
        import Dispatch
        dispatchMain()
        """:
            """
            import Dispatch
            dispatchMain()
            """,
        """
        ↓import Foundation
        // @objc
        class A {}
        """:
            """
            // @objc
            class A {}
            """,
        """
        @testable import Foundation
        ↓import Dispatch
        @objc
        class A {}
        """:
            """
            @testable import Foundation
            @objc
            class A {}
            """,
        """
        @testable import Foundation
        ↓@testable import Dispatch
        @objc
        class A {}
        """:
            """
            @testable import Foundation
            @objc
            class A {}
            """,
        Example("""
        import Foundation
        typealias Foo = CFArray
        dispatchMain()
        """, configuration: [
            "require_explicit_imports": true,
            "allowed_transitive_imports": [
                [
                    "module": "Foundation",
                    "allowed_transitive_imports": ["CoreFoundation", "Dispatch"],
                ] as [String: any Sendable],
            ],
        ] as [String: any Sendable], testMultiByteOffsets: false, testOnLinux: false, testOnWindows: false):
            """
            import Foundation
            typealias Foo = CFArray
            dispatchMain()
            """,
        Example("""
        ↓↓↓import Foundation
        typealias Foo = CFData
        dispatchMain()
        """, configuration: [
            "require_explicit_imports": true
        ], testMultiByteOffsets: false, testOnLinux: false, testOnWindows: false):
            """
            import CoreFoundation
            import Dispatch
            typealias Foo = CFData
            dispatchMain()
            """,
        """
        import Foundation
        typealias Foo = CFData
        @objc
        class A {}
        """.configuration([
            "require_explicit_imports": true,
            "allowed_transitive_imports": [
                [
                    "module": "Foundation",
                    "allowed_transitive_imports": ["CoreFoundation"],
                ] as [String: any Sendable],
            ],
        ] as [String: any Sendable]):
            """
            import Foundation
            typealias Foo = CFData
            @objc
            class A {}
            """,
        Example("""
        ↓import Foundation
        typealias Bar = CFData
        @objc
        class A {}
        """, configuration: [
            "require_explicit_imports": true
        ], testMultiByteOffsets: false, testOnLinux: false, testOnWindows: false):
            """
            import CoreFoundation
            import Foundation
            typealias Bar = CFData
            @objc
            class A {}
            """,
        """
        import Foundation
        func bar() {}
        """.configuration([
            "always_keep_imports": ["Foundation"]
        ]):
            """
            import Foundation
            func bar() {}
            """,
        """
        ↓import Swift
        ↓import SwiftShims
        func foo(error: Swift.Error) {}
        """:
            """
            func foo(error: Swift.Error) {}
            """,
    ])
}
