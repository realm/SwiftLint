import SourceKittenFramework

/// In UIKit, a `UIImageView` was by default not an accessibility element, and would only be visible to VoiceOver
/// and other assistive technologies if the developer explicitly made them an accessibility element. In SwiftUI,
/// however, an `Image` is an accessibility element by default. If the developer does not explicitly hide them from
/// accessibility or give them an accessibility label, they will inherit the name of the image file, which often creates
/// a poor experience when VoiceOver reads things like "close icon white".
///
/// Known false negatives for Images declared as instance variables and containers that provide a label but are
/// not accessibility elements. Known false positives for Images created in a separate function from where they
/// have accessibility properties applied.
struct AccessibilityLabelForImageRule: ASTRule, OptInRule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "accessibility_label_for_image",
        name: "Accessibility Label for Image",
        description: "Images that provide context should have an accessibility label or should be explicitly hidden " +
                     "from accessibility",
        kind: .lint,
        minSwiftVersion: .fiveDotOne,
        nonTriggeringExamples: AccessibilityLabelForImageRuleExamples.nonTriggeringExamples,
        triggeringExamples: AccessibilityLabelForImageRuleExamples.triggeringExamples
    )

    // MARK: AST Rule

    func validate(file: SwiftLintFile, kind: SwiftDeclarationKind,
                  dictionary: SourceKittenDictionary) -> [StyleViolation] {
        // Only proceed to check View structs.
        guard kind == .struct,
            dictionary.inheritedTypes.contains("View"),
            dictionary.substructure.isNotEmpty else {
                return []
        }

        return findImageViolations(file: file, substructure: dictionary.substructure)
    }

    /// Recursively check a file for image violations, and return all such violations.
    private func findImageViolations(file: SwiftLintFile, substructure: [SourceKittenDictionary]) -> [StyleViolation] {
        var violations = [StyleViolation]()
        for dictionary in substructure {
            guard let offset: ByteCount = dictionary.offset else {
                continue
            }

            // If it's image, and does not hide from accessibility or provide a label, it's a violation.
            if dictionary.isImage {
                if dictionary.isDecorativeOrLabeledImage ||
                  dictionary.hasAccessibilityHiddenModifier(in: file) ||
                    dictionary.hasAccessibilityLabelModifier(in: file) {
                    continue
                }

                violations.append(
                    StyleViolation(ruleDescription: Self.description,
                                   severity: configuration.severity,
                                   location: Location(file: file, byteOffset: offset))
                )
            } else if dictionary.substructure.isNotEmpty {
                // If dictionary did not represent an Image, recursively check substructure,
                // unless it's a container that hides its children from accessibility or is labeled.
                if dictionary.hasAccessibilityHiddenModifier(in: file) ||
                    dictionary.hasAccessibilityElementChildrenIgnoreModifier(in: file) ||
                    dictionary.hasAccessibilityLabelModifier(in: file) {
                    continue
                }

                violations.append(contentsOf: findImageViolations(file: file, substructure: dictionary.substructure))
            }
        }

        return violations
    }
}

// MARK: SourceKittenDictionary extensions

private extension SourceKittenDictionary {
    /// Whether or not the dictionary represents a SwiftUI Image.
    /// Currently only accounts for SwiftUI image literals and not instance variables.
    var isImage: Bool {
        // Image literals will be reported as calls to the initializer.
        guard expressionKind == .call else {
            return false
        }

        if name == "Image" || name == "SwiftUI.Image" {
            return true
        }

        // Recursively check substructure.
        // SwiftUI literal Views with modifiers will have a SourceKittenDictionary structure like:
        // Image(decorative: "myImage").resizable().frame
        //     --> Image(decorative: "myImage").resizable
        //         --> Image
        return substructure.contains(where: { $0.isImage })
    }

    /// Whether or not the dictionary represents a SwiftUI Image using the `Image(decorative:)` constructor (hides
    /// from a11y), or the `Image(_:label:)` constructors (which provide labels).
    var isDecorativeOrLabeledImage: Bool {
        guard isImage else {
            return false
        }

        // Check for Image(decorative:) or Image(_:label:) constructor.
        if expressionKind == .call &&
            enclosedArguments.contains(where: { ["decorative", "label"].contains($0.name) }) {
            return true
        }

        // Recursively check substructure.
        // SwiftUI literal Views with modifiers will have a SourceKittenDictionary structure like:
        // Image(decorative: "myImage").resizable().frame
        //     --> Image(decorative: "myImage").resizable
        //         --> Image
        return substructure.contains(where: { $0.isDecorativeOrLabeledImage })
    }

    /// Whether or not the dictionary represents a SwiftUI View with an `accesibilityLabel(_:)`
    /// or `accessibility(label:)` modifier.
    func hasAccessibilityLabelModifier(in file: SwiftLintFile) -> Bool {
        return hasModifier(
            anyOf: [
                SwiftUIModifier(
                    name: "accessibilityLabel",
                    arguments: [.init(name: "", values: [])]
                ),
                SwiftUIModifier(
                    name: "accessibility",
                    arguments: [.init(name: "label", values: [])]
                )
            ],
            in: file
        )
    }
}
