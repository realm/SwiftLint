internal struct VerticalParameterAlignmentRuleExamples {
    static let nonTriggeringExamples: [String] = {
        let commonExamples = [
            "func validateFunction(_ file: File, kind: SwiftDeclarationKind,\n" +
            "                      dictionary: [String: SourceKitRepresentable]) { }\n",
            "func validateFunction(_ file: File, kind: SwiftDeclarationKind,\n" +
            "                      dictionary: [String: SourceKitRepresentable]) -> [StyleViolation]\n",
            "func foo(bar: Int)\n",
            "func foo(bar: Int) -> String \n",
            "func validateFunction(_ file: File, kind: SwiftDeclarationKind,\n" +
            "                      dictionary: [String: SourceKitRepresentable])\n" +
            "                      -> [StyleViolation]\n",
            "func validateFunction(\n" +
            "   _ file: File, kind: SwiftDeclarationKind,\n" +
            "   dictionary: [String: SourceKitRepresentable]) -> [StyleViolation]\n",
            "func validateFunction(\n" +
            "   _ file: File, kind: SwiftDeclarationKind,\n" +
            "   dictionary: [String: SourceKitRepresentable]\n" +
            ") -> [StyleViolation]\n",
            "func regex(_ pattern: String,\n" +
            "           options: NSRegularExpression.Options = [.anchorsMatchLines,\n" +
            "                                                   .dotMatchesLineSeparators]) -> NSRegularExpression\n",
            "func foo(a: Void,\n         b: [String: String] =\n           [:]) {\n}\n",
            "func foo(data: (size: CGSize,\n" +
            "                identifier: String)) {}"
        ]

        guard SwiftVersion.current >= .fiveDotOne else {
            return commonExamples
        }

        return commonExamples + [
            """
            func foo(data: Data,
                     @ViewBuilder content: @escaping (Data.Element.IdentifiedValue) -> Content) {}
            """
        ]
    }()

    static let triggeringExamples: [String] = {
        let commonExamples = [
            "func validateFunction(_ file: File, kind: SwiftDeclarationKind,\n" +
            "                  ↓dictionary: [String: SourceKitRepresentable]) { }\n",
            "func validateFunction(_ file: File, kind: SwiftDeclarationKind,\n" +
            "                       ↓dictionary: [String: SourceKitRepresentable]) { }\n",
            "func validateFunction(_ file: File,\n" +
            "                  ↓kind: SwiftDeclarationKind,\n" +
            "                  ↓dictionary: [String: SourceKitRepresentable]) { }\n"
        ]

        guard SwiftVersion.current >= .fiveDotOne else {
            return commonExamples
        }

        return commonExamples + [
            """
            func foo(data: Data,
                        ↓@ViewBuilder content: @escaping (Data.Element.IdentifiedValue) -> Content) {}
            """
        ]
    }()
}
