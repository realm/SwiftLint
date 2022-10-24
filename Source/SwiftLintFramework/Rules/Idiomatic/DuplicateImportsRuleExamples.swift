internal struct DuplicateImportsRuleExamples {
    static let nonTriggeringExamples = [
        Example("""
        import A
        import B
        import C
        """),
        Example("""
        import A.B
        import A.C
        """),
        Example("""
        @_implementationOnly import A
        @_implementationOnly import B
        """),
        Example("""
        @testable import A
        @testable import B
        """),
        Example("""
        #if DEBUG
            @testable import KsApi
        #else
            import KsApi
        #endif
        """),
        Example("""
        import A // module
        import B // module
        """),
        Example("""
        #if TEST
        func test() {
        }
        """)
    ]

    static let triggeringExamples = [
        Example("""
        import Foundation
        import Dispatch
        ↓import Foundation
        """)
    ]

    static let corrections: [Example: Example] = [:]
}
