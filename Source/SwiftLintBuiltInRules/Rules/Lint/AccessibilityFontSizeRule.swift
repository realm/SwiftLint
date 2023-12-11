import SourceKittenFramework

struct AccessibilityFontSizeRule: ASTRule, OptInRule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "accessibility_font_size",
        name: "Accessibility Font Size",
        description: "Text may not have a fixed font size",
        kind: .lint,
        minSwiftVersion: .fiveDotOne,
        nonTriggeringExamples: [
            Example("""
            struct TestView: View {
                var body: some View {
                    Text("Hello World!")
                }
            }
            """)
        ],
        triggeringExamples: [
            Example("""
            struct TestView: View {
                var body: some View {
                    Text("Hello World!")
                        .font(.system(size: 20))
                }
            }
            """)
        ]
    )

    // MARK: AST Rule

    func validate(file: SwiftLintFile, kind: SwiftDeclarationKind,
                  dictionary: SourceKittenDictionary) -> [StyleViolation] {
        // Only proceed to check View structs.
        guard ( kind == .struct && dictionary.inheritedTypes.contains("View")) || kind == .extension,
            dictionary.substructure.isNotEmpty else {
                return []
        }

        return findTextViolations(file: file, substructure: dictionary.substructure)
    }

    /// Recursively check a file for font violations, and return all such violations.
    private func findTextViolations(file: SwiftLintFile, substructure: [SourceKittenDictionary]) -> [StyleViolation] {
        var violations = [StyleViolation]()
        for dictionary in substructure {
            guard let offset: ByteCount = dictionary.offset else {
                continue
            }

            if dictionary.isText && dictionary.hasStrictFontModifier(in: file) {
                violations.append(
                    StyleViolation(ruleDescription: Self.description,
                                   severity: configuration.severity,
                                   location: Location(file: file, byteOffset: offset))
                )
            }

            // If dictionary did not represent an Text, recursively check substructure.
            else if dictionary.substructure.isNotEmpty {
                violations.append(contentsOf: findTextViolations(file: file, substructure: dictionary.substructure))
            }
        }

        return violations
    }
}

// MARK: SourceKittenDictionary extensions

private extension SourceKittenDictionary {
    /// Whether or not the dictionary represents a SwiftUI Text.
    /// Currently only accounts for SwiftUI text literals and not instance variables.
    var isText: Bool {
        // Text literals will be reported as calls to the initializer.
        guard expressionKind == .call else {
            return false
        }

        if name == "Text" || name == "SwiftUI.Text" {
            return true
        }

        return substructure.contains(where: { $0.isText })
    }

    /// Whether or not the dictionary represents a SwiftUI View with an `font(.system())` modifier.
    func hasStrictFontModifier(in file: SwiftLintFile) -> Bool {
        return hasModifier(
            anyOf: [
                SwiftUIModifier(
                    name: "font",
                    arguments: [
                        .init(
                            name: "",
                            values: [".system"],
                            matchType: .prefix)
                    ]
                )
            ],
            in: file
        )
    }
}
