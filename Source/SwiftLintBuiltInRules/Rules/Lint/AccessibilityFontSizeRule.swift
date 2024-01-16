import SourceKittenFramework

struct AccessibilityFontSizeRule: ASTRule, OptInRule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "accessibility_font_size",
        name: "Accessibility Font Size",
        description: "Fonts may not have a fixed size",
        kind: .lint,
        minSwiftVersion: .fiveDotOne,
        nonTriggeringExamples: AccessibilityFontSizeRuleExamples.nonTriggeringExamples,
        triggeringExamples: AccessibilityFontSizeRuleExamples.triggeringExamples
    )

    // MARK: AST Rule

    func validate(file: SwiftLintFile, kind: SwiftDeclarationKind,
                  dictionary: SourceKittenDictionary) -> [StyleViolation] {
        // Only proceed to check View structs.
        guard ( kind == .struct && dictionary.inheritedTypes.contains("View")) || kind == .extension,
            dictionary.substructure.isNotEmpty else {
                return []
        }

        return findFontViolations(file: file, substructure: dictionary.substructure)
    }

    /// Recursively check a file for font violations, and return all such violations.
    private func findFontViolations(file: SwiftLintFile, substructure: [SourceKittenDictionary]) -> [StyleViolation] {
        var violations = [StyleViolation]()
        for dictionary in substructure {
            guard let offset: ByteCount = dictionary.offset else {
                continue
            }

            guard dictionary.isFontModifier(in: file) else {
                if dictionary.substructure.isNotEmpty {
                    violations.append(
                        contentsOf: findFontViolations(
                            file: file,
                            substructure: dictionary.substructure
                        )
                    )
                }

                continue
            }

            if checkForViolations(dictionaries: [dictionary], in: file) {
                violations.append(
                    StyleViolation(
                        ruleDescription: Self.description,
                        severity: configuration.severity,
                        location: Location(file: file, byteOffset: offset)
                    )
                )
            }
        }

        return violations
    }

    private func checkForViolations(dictionaries: [SourceKittenDictionary], in file: SwiftLintFile) -> Bool {
        for dictionary in dictionaries {
            if dictionary.hasSystemFontModifier(in: file) || dictionary.hasCustomFontModifierWithFixedSize(in: file) {
                return true
            } else if dictionary.substructure.isNotEmpty {
                if checkForViolations(dictionaries: dictionary.substructure, in: file) {
                    return true
                }
            }
        }

        return false
    }
}

// MARK: SourceKittenDictionary extensions

private extension SourceKittenDictionary {
    /// Whether or not the dictionary represents a SwiftUI Text.
    /// Currently only accounts for SwiftUI text literals and not instance variables.
    func isFontModifier(in file: SwiftLintFile) -> Bool {
        // Text literals will be reported as calls to the initializer.
        guard expressionKind == .call else {
            return false
        }

        if hasModifier(
            anyOf: [
                SwiftUIModifier(
                    name: ".font",
                    arguments: []
                )
            ],
            in: file
        ) {
            return true
        }

        return substructure.contains(where: { $0.isFontModifier(in: file) })
    }

    func hasCustomFontModifierWithFixedSize(in file: SwiftLintFile) -> Bool {
        return hasModifier(
            anyOf: [
                SwiftUIModifier(
                    name: ".custom",
                    arguments: [
                        .init(
                            name: "fixedSize",
                            values: [],
                            matchType: .substring)
                    ]
                )
            ],
            in: file
        )
    }

    /// Whether or not the dictionary represents a SwiftUI View with an `font(.system())` modifier.
    func hasSystemFontModifier(in file: SwiftLintFile) -> Bool {
        return hasModifier(
            anyOf: [
                SwiftUIModifier(
                    name: "system",
                    arguments: [
                        .init(
                            name: "",
                            values: ["size"],
                            matchType: .substring)
                    ]
                )
            ],
            in: file
        )
    }
}
