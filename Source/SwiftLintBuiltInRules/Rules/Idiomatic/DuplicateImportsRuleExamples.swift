internal struct DuplicateImportsRuleExamples {
    static let nonTriggeringExamples = #examples([
        """
        import A
        import B
        import C
        """,
        """
        import A.B
        import A.C
        """,
        """
        @_implementationOnly import A
        @_implementationOnly import B
        """,
        """
        @testable import A
        @testable import B
        """,
        """
        #if DEBUG
            @testable import KsApi
        #else
            import KsApi
        #endif
        """,
        """
        import A // module
        import B // module
        """,
        """
        #if TEST
        func test() {
        }
        """,
        """
        import Foo
        @testable import struct Foo.Bar
        """,
        """
        import CoreImage
        import CoreImage.CIFilterBuiltins
        """,
    ])

    static let triggeringExamples = Array(corrections.keys.sorted())

    // swiftlint:disable:next closure_body_length
    static let corrections: [Example: Example] = {
        var corrections = #corrections([
            """
            import Foundation
            import Dispatch
            ↓import Foundation

            """: """
                import Foundation
                import Dispatch

                """,
            """
            import Foundation
            ↓import Foundation.NSString

            """: """
                import Foundation

                """,
            """
            ↓import Foundation.NSString
            import Foundation

            """: """
                import Foundation

                """,
            """
            @_implementationOnly import A
            ↓@_implementationOnly import A

            """: """
                @_implementationOnly import A

                """,
            """
            @testable import A
            ↓@testable import A

            """: """
                @testable import A

                """,
            """
            ↓import A.B.C
            import A.B

            """: """
                import A.B

                """,
            """
            import A.B
            ↓import A.B.C

            """: """
                import A.B

                """,
            """
            import A
            #if DEBUG
                @testable import KsApi
            #else
                import KsApi
            #endif
            ↓import A

            """: """
                import A
                #if DEBUG
                    @testable import KsApi
                #else
                    import KsApi
                #endif

                """,
            """
            import Foundation
            ↓import Foundation
            ↓import Foundation

            """: """
                import Foundation

                """,
            """
            @testable import Foo
            import struct Foo.Bar
            """: """
                @testable import Foo
                """,
            """
            ↓import A.B.C
            ↓import A.B
            import A

            """.excludeFromDocumentation(): """
                import A

                """,
            """
            import A.B.C
            ↓import A.B.C.D
            ↓import A.B.C.E

            """.excludeFromDocumentation(): """
                import A.B.C

                """,
            """
            ↓import A.B.C
            import A
            ↓import A.B

            """.excludeFromDocumentation(): """
                import A

                """,
            """
            ↓import A.B
            import A
            ↓import A.B.C

            """.excludeFromDocumentation(): """
                import A

                """,
            """
            import A
            ↓import A.B.C
            ↓import A.B

            """.excludeFromDocumentation(): """
                import A

                """,
            """
            import CoreImage.CIFilterBuiltins
            import CoreImage.CIFilterBuiltins
            """.excludeFromDocumentation(): """
                import CoreImage.CIFilterBuiltins
                """,
        ])

        DuplicateImportsRule.importKinds.map { importKind in
            Example("""
                import A
                ↓import \(importKind) A.Foo

                """)
        }.forEach {
            corrections[$0] = Example(
                """
                import A

                """)
        }

        DuplicateImportsRule.importKinds.map { importKind in
            """
                import A
                ↓import \(importKind) A.B.Foo

                """.excludeFromDocumentation()
        }.forEach {
            corrections[$0] = Example(
                """
                import A

                """)
        }

        DuplicateImportsRule.importKinds.map { importKind in
            """
                import A.B
                ↓import \(importKind) A.B.Foo

                """.excludeFromDocumentation()
        }.forEach {
            corrections[$0] = Example(
                """
                import A.B

                """)
        }

        return corrections
    }()
}
