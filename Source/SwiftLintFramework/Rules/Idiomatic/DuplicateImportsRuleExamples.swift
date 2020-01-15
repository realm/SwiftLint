internal struct DuplicateImportsRuleExamples {
    static let nonTriggeringExamples: [Example] = [
        "import A\nimport B\nimport C",
        "import A.B\nimport A.C",
        """
        #if DEBUG
            @testable import KsApi
        #else
            import KsApi
        #endif
        """,
        "import A // module\nimport B // module"
    ]

    static let triggeringExamples: [Example] = {
        var list: [Example] = [
            "import Foundation\nimport Dispatch\n↓import Foundation",
            "import Foundation\n↓import Foundation.NSString",
            "↓import Foundation.NSString\nimport Foundation",
            "↓import A.B.C\nimport A.B",
            "import A.B\n↓import A.B.C",
            """
            import A
            #if DEBUG
                @testable import KsApi
            #else
                import KsApi
            #endif
            ↓import A
            """
        ]

        list += DuplicateImportsRule.importKinds.map { importKind in
            Example("""
                import A
                ↓import \(importKind) A.Foo
                """)
        }

        list += DuplicateImportsRule.importKinds.map { importKind in
            Example("""
                import A
                ↓import \(importKind) A.B.Foo
                """)
        }

        list += DuplicateImportsRule.importKinds.map { importKind in
            Example("""
                import A.B
                ↓import \(importKind) A.B.Foo
                """)
        }

        return list
    }()
}
