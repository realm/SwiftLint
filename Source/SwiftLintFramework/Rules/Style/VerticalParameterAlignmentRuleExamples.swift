internal struct VerticalParameterAlignmentRuleExamples {
    static let nonTriggeringExamples: [Example] = {
        let commonExamples = [
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
            """)
        ]

        guard SwiftVersion.current >= .fiveDotOne else {
            return commonExamples
        }

        return commonExamples + [
            Example("""
            func foo(data: Data,
                     @ViewBuilder content: @escaping (Data.Element.IdentifiedValue) -> Content) {}
            """)
        ]
    }()

    static let triggeringExamples: [Example] = {
        let commonExamples = [
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
            """)
        ]

        guard SwiftVersion.current >= .fiveDotOne else {
            return commonExamples
        }

        return commonExamples + [
            Example("""
            func foo(data: Data,
                        ↓@ViewBuilder content: @escaping (Data.Element.IdentifiedValue) -> Content) {}
            """)
        ]
    }()
}
