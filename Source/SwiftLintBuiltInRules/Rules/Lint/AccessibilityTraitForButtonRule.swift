import SourceKittenFramework

/// The accessibility button and link traits are used to tell assistive technologies that an element is tappable. When
/// an element has one of these traits, VoiceOver will automatically read "button" or "link" after the element's label
/// to let the user know that they can activate it. When using a UIKit `UIButton` or SwiftUI `Button` or
/// `Link`, the button trait is added by default, but when you manually add a tap gesture recognizer to an
/// element, you need to explicitly add the button or link trait. In most cases the button trait should be used, but for
/// buttons that open a URL in an external browser we use the link trait instead. This rule attempts to catch uses of
/// the SwiftUI `.onTapGesture` modifier where the `.isButton` or `.isLink` trait is not explicitly applied.
struct AccessibilityTraitForButtonRule: ASTRule, OptInRule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "accessibility_trait_for_button",
        name: "Accessibility Trait for Button",
        description: "All views with tap gestures added should include the .isButton or the .isLink accessibility " +
                     "traits",
        kind: .lint,
        minSwiftVersion: .fiveDotOne,
        nonTriggeringExamples: AccessibilityTraitForButtonRuleExamples.nonTriggeringExamples,
        triggeringExamples: AccessibilityTraitForButtonRuleExamples.triggeringExamples
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

        return findButtonTraitViolations(file: file, substructure: dictionary.substructure)
    }

    /// Recursively check a file for image violations, and return all such violations.
    private func findButtonTraitViolations(
        file: SwiftLintFile,
        substructure: [SourceKittenDictionary]
    ) -> [StyleViolation] {
        var violations = [StyleViolation]()
        for dictionary in substructure {
            guard let offset: ByteCount = dictionary.offset else {
                continue
            }

            // If it has a tap gesture and does not have a button or link trait, it's a violation.
            // Also allowing ones that are hidden from accessibility, though that's not recommended.
            if dictionary.hasOnSingleTapModifier(in: file) {
                if dictionary.hasAccessibilityTrait(".isButton", in: file) ||
                    dictionary.hasAccessibilityTrait(".isLink", in: file) ||
                    dictionary.hasAccessibilityHiddenModifier(in: file) {
                    continue
                }

                violations.append(
                    StyleViolation(ruleDescription: Self.description,
                                   severity: configuration.severity,
                                   location: Location(file: file, byteOffset: offset))
                )
            } else if dictionary.substructure.isNotEmpty {
                // If dictionary did not represent a View with a tap gesture, recursively check substructure,
                // unless it's a container that hides its children from accessibility.
                if dictionary.hasAccessibilityHiddenModifier(in: file) ||
                    dictionary.hasAccessibilityElementChildrenIgnoreModifier(in: file) {
                    continue
                }

                violations.append(
                    contentsOf: findButtonTraitViolations(file: file, substructure: dictionary.substructure)
                )
            }
        }

        return violations
    }
}

// MARK: SourceKittenDictionary extensions

private extension SourceKittenDictionary {
    /// Whether or not the dictionary represents a SwiftUI View with a tap gesture where the `count` argument is 1.
    /// A single tap can be represented by an `onTapGesture` modifier with a count of 1 (default value is 1),
    /// or by a `gesture`, `simultaneousGesture`, or `highPriorityGesture` modifier with an argument
    /// starting with a `TapGesture` object with a count of 1 (default value is 1).
    func hasOnSingleTapModifier(in file: SwiftLintFile) -> Bool {
        return hasModifier(
            anyOf: [
                SwiftUIModifier(
                    name: "onTapGesture",
                    arguments: [.init(name: "count", required: false, values: ["1"])]
                ),
                SwiftUIModifier(
                    name: "gesture",
                    arguments: [
                        .init(name: "", values: ["TapGesture()", "TapGesture(count: 1)"], matchType: .prefix)
                    ]
                ),
                SwiftUIModifier(
                    name: "simultaneousGesture",
                    arguments: [
                        .init(name: "", values: ["TapGesture()", "TapGesture(count: 1)"], matchType: .prefix)
                    ]
                ),
                SwiftUIModifier(
                    name: "highPriorityGesture",
                    arguments: [
                        .init(name: "", values: ["TapGesture()", "TapGesture(count: 1)"], matchType: .prefix)
                    ]
                )
            ],
            in: file
        )
    }

    /// Whether or not the dictionary represents a SwiftUI View with an `accessibilityAddTraits()` or
    /// `accessibility(addTraits:)` modifier with the specified trait (specify trait as a String).
    func hasAccessibilityTrait(_ trait: String, in file: SwiftLintFile) -> Bool {
        return hasModifier(
            anyOf: [
                SwiftUIModifier(
                    name: "accessibilityAddTraits",
                    arguments: [.init(name: "", values: [trait], matchType: .substring)]
                ),
                SwiftUIModifier(
                    name: "accessibility",
                    arguments: [.init(name: "addTraits", values: [trait], matchType: .substring)]
                )
            ],
            in: file
        )
    }
}
