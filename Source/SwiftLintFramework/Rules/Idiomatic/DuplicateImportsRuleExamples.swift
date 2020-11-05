internal struct DuplicateImportsRuleExamples {
    static let nonTriggeringExamples: [Example] = [
        Example("import A\nimport B\nimport C"),
        Example("import A.B\nimport A.C"),
        Example("@_implementationOnly import A\n@_implementationOnly import B"),
        Example("@testable import A\n@testable import B"),
        Example("""
        #if DEBUG
            @testable import KsApi
        #else
            import KsApi
        #endif
        """),
        Example("import A // module\nimport B // module"),
        Example("""
        #if TEST
        func test() {
        }
        """)
    ]

    static let triggeringExamples: [Example] = {
        var list: [Example] = [
            Example("import Foundation\nimport Dispatch\n↓import Foundation"),
            Example("import Foundation\n↓import Foundation.NSString"),
            Example("@_implementationOnly import A\n@_implementationOnly import A"),
            Example("@testable import A\n@testable import A"),
            Example("↓import Foundation.NSString\nimport Foundation"),
            Example("↓import A.B.C\nimport A.B"),
            Example("import A.B\n↓import A.B.C"),
            Example("""
            import A
            #if DEBUG
                @testable import KsApi
            #else
                import KsApi
            #endif
            ↓import A
            """)
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
