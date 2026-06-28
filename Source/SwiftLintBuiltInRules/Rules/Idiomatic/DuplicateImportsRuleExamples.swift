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
        var corrections = [
            Example("""
            import Foundation
            import Dispatch
            ↓import Foundation

            """): Example(
                """
                import Foundation
                import Dispatch

                """),
            Example("""
            import Foundation
            ↓import Foundation.NSString

            """): Example("""
                import Foundation

                """),
            Example("""
            ↓import Foundation.NSString
            import Foundation

            """): Example("""
                import Foundation

                """),
            Example("""
            @_implementationOnly import A
            ↓@_implementationOnly import A

            """): Example("""
                @_implementationOnly import A

                """),
            Example("""
            @testable import A
            ↓@testable import A

            """): Example("""
                @testable import A

                """),
            Example("""
            ↓import A.B.C
            import A.B

            """): Example("""
                import A.B

                """),
            Example("""
            import A.B
            ↓import A.B.C

            """): Example("""
                import A.B

                """),
            Example("""
            import A
            #if DEBUG
                @testable import KsApi
            #else
                import KsApi
            #endif
            ↓import A

            """): Example("""
                import A
                #if DEBUG
                    @testable import KsApi
                #else
                    import KsApi
                #endif

                """),
            Example("""
            import Foundation
            ↓import Foundation
            ↓import Foundation

            """): Example("""
                import Foundation

                """),
            Example("""
            @testable import Foo
            import struct Foo.Bar
            """): Example("""
                @testable import Foo
                """),
            Example("""
            ↓import A.B.C
            ↓import A.B
            import A

            """, excludeFromDocumentation: true): Example("""
                import A

                """),
            Example("""
            import A.B.C
            ↓import A.B.C.D
            ↓import A.B.C.E

            """, excludeFromDocumentation: true): Example("""
                import A.B.C

                """),
            Example("""
            ↓import A.B.C
            import A
            ↓import A.B

            """, excludeFromDocumentation: true): Example("""
                import A

                """),
            Example("""
            ↓import A.B
            import A
            ↓import A.B.C

            """, excludeFromDocumentation: true): Example("""
                import A

                """),
            Example("""
            import A
            ↓import A.B.C
            ↓import A.B

            """, excludeFromDocumentation: true): Example("""
                import A

                """),
            Example("""
            import CoreImage.CIFilterBuiltins
            import CoreImage.CIFilterBuiltins
            """, excludeFromDocumentation: true): Example("""
                import CoreImage.CIFilterBuiltins
                """),
        ]

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
            Example("""
                import A
                ↓import \(importKind) A.B.Foo

                """, excludeFromDocumentation: true)
        }.forEach {
            corrections[$0] = Example(
                """
                import A

                """)
        }

        DuplicateImportsRule.importKinds.map { importKind in
            Example("""
                import A.B
                ↓import \(importKind) A.B.Foo

                """, excludeFromDocumentation: true)
        }.forEach {
            corrections[$0] = Example(
                """
                import A.B

                """)
        }

        return corrections
    }()
}
