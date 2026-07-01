import SwiftLintCore

internal struct VerticalParameterAlignmentRuleExamples {
    static let nonTriggeringExamples: [Example] = #examples([
        """
        func validateFunction(_ file: SwiftLintFile, kind: SwiftDeclarationKind,
                              dictionary: SourceKittenDictionary) { }
        """,
        """
        func validateFunction(_ file: SwiftLintFile, kind: SwiftDeclarationKind,
                              dictionary: SourceKittenDictionary) -> [StyleViolation]
        """,
        """
        func foo(bar: Int)
        """,
        """
        func foo(bar: Int) -> String
        """,
        """
        func validateFunction(_ file: SwiftLintFile, kind: SwiftDeclarationKind,
                              dictionary: SourceKittenDictionary)
                              -> [StyleViolation]
        """,
        """
        func validateFunction(
           _ file: SwiftLintFile, kind: SwiftDeclarationKind,
           dictionary: SourceKittenDictionary) -> [StyleViolation]
        """,
        """
        func validateFunction(
           _ file: SwiftLintFile, kind: SwiftDeclarationKind,
           dictionary: SourceKittenDictionary
        ) -> [StyleViolation]
        """,
        """
        func regex(_ pattern: String,
                   options: NSRegularExpression.Options = [.anchorsMatchLines,
                                                           .dotMatchesLineSeparators]) -> NSRegularExpression
        """,
        """
        func foo(a: Void,
                 b: [String: String] =
                 [:]) {
        }
        """,
        """
        func foo(data: (size: CGSize,
                        identifier: String)) {}
        """,
        """
        func foo(data: Data,
                 @ViewBuilder content: @escaping (Data.Element.IdentifiedValue) -> Content) {}
        """,
        """
        class A {
            init(bar: Int)
        }
        """,
        """
        class A {
            init(foo: Int,
                 bar: String)
        }
        """,
        """
        func résuméBuilder(_ name: String,
                           title: String,
                           summary: String) -> String {
            return name
        }
        """,
    ])

    static let triggeringExamples: [Example] = #examples([
        """
            func validateFunction(_ file: SwiftLintFile, kind: SwiftDeclarationKind,
                              ↓dictionary: SourceKittenDictionary) { }
            """,
        """
            func validateFunction(_ file: SwiftLintFile, kind: SwiftDeclarationKind,
                                   ↓dictionary: SourceKittenDictionary) { }
            """,
        """
            func validateFunction(_ file: SwiftLintFile,
                              ↓kind: SwiftDeclarationKind,
                              ↓dictionary: SourceKittenDictionary) { }
            """,
        """
            func foo(data: Data,
                        ↓@ViewBuilder content: @escaping (Data.Element.IdentifiedValue) -> Content) {}
            """,
        """
        class A {
            init(data: Data,
                        ↓@ViewBuilder content: @escaping (Data.Element.IdentifiedValue) -> Content) {}
        }
        """,
    ])
}
