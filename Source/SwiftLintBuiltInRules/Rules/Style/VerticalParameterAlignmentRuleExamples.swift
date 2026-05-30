internal struct VerticalParameterAlignmentRuleExamples {
    static let nonTriggeringExamples: [Example] = [
        Example("""
        func validateFunction(_ file: SwiftLintFile, kind: SwiftDeclarationKind,
                              dictionary: SourceKittenDictionary) { }
        """),
        Example("""
        func validateFunction(_ file: SwiftLintFile, kind: SwiftDeclarationKind,
                              dictionary: SourceKittenDictionary) -> [StyleViolation]
        """),
        Example("""
        func foo(bar: Int)
        """),
        Example("""
        func foo(bar: Int) -> String
        """),
        Example("""
        func validateFunction(_ file: SwiftLintFile, kind: SwiftDeclarationKind,
                              dictionary: SourceKittenDictionary)
                              -> [StyleViolation]
        """),
        Example("""
        func validateFunction(
           _ file: SwiftLintFile, kind: SwiftDeclarationKind,
           dictionary: SourceKittenDictionary) -> [StyleViolation]
        """),
        Example("""
        func validateFunction(
           _ file: SwiftLintFile, kind: SwiftDeclarationKind,
           dictionary: SourceKittenDictionary
        ) -> [StyleViolation]
        """),
        Example("""
        func regex(_ pattern: String,
                   options: NSRegularExpression.Options = [.anchorsMatchLines,
                                                           .dotMatchesLineSeparators]) -> NSRegularExpression
        """),
        Example("""
        func foo(a: Void,
                 b: [String: String] =
                 [:]) {
        }
        """),
        Example("""
        func foo(data: (size: CGSize,
                        identifier: String)) {}
        """),
        Example("""
        func foo(data: Data,
                 @ViewBuilder content: @escaping (Data.Element.IdentifiedValue) -> Content) {}
        """),
        Example("""
        class A {
            init(bar: Int)
        }
        """),
        Example("""
        class A {
            init(foo: Int,
                 bar: String)
        }
        """),
        // Regression: Cyrillic function name must not affect UTF-8 vs display column alignment (#5037).
        Example("""
        func сheckprofileexistence(_ param: Bool,
                                   param1: Bool,
                                   param2: Bool,
                                   param3: Bool) -> Bool {
            false
        }
        """),
    ]

    static let triggeringExamples: [Example] = [
        Example("""
            func validateFunction(_ file: SwiftLintFile, kind: SwiftDeclarationKind,
                              ↓dictionary: SourceKittenDictionary) { }
            """),
        Example("""
            func validateFunction(_ file: SwiftLintFile, kind: SwiftDeclarationKind,
                                   ↓dictionary: SourceKittenDictionary) { }
            """),
        Example("""
            func validateFunction(_ file: SwiftLintFile,
                              ↓kind: SwiftDeclarationKind,
                              ↓dictionary: SourceKittenDictionary) { }
            """),
        Example("""
            func foo(data: Data,
                        ↓@ViewBuilder content: @escaping (Data.Element.IdentifiedValue) -> Content) {}
            """),
        Example("""
        class A {
            init(data: Data,
                        ↓@ViewBuilder content: @escaping (Data.Element.IdentifiedValue) -> Content) {}
        }
        """),
    ]
}
