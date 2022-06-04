import SourceKittenFramework

/// The accessibility button and link traits are used to tell assistive technologies that an element is tappable. When
/// an element has one of these traits, VoiceOver will automatically read "button" or "link" after the element's label
/// to let the user know that they can activate it. When using a UIKit `UIButton` or SwiftUI `Button` or
/// `Link`, the button trait is added by default, but when you manually add a tap gesture recognizer to an
/// element, you need to explicitly add the button or link trait. In most cases the button trait should be used, but for
/// buttons that open a URL in an external browser we use the link trait instead. This rule attempts to catch uses of
/// the SwiftUI `.onTapGesture` modifier where the `.isButton` or `.isLink` trait is not explicitly applied.
public struct AccessibilityTraitForButtonRule: ASTRule, ConfigurationProviderRule, OptInRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "accessibility_trait_for_button",
        name: "Accessibility Trait for Button",
        description: "All views with tap gestures added should include the .isButton " +
                    "accessibility trait. If a tap opens an external link the .isLink " +
                    "trait should be used instead.",
        kind: .lint,
        minSwiftVersion: .fiveDotOne,
        nonTriggeringExamples: AccessibilityTraitForButtonRuleExamples.nonTriggeringExamples,
        triggeringExamples: AccessibilityTraitForButtonRuleExamples.triggeringExamples
    )

    // MARK: AST Rule

    public func validate(file: SwiftLintFile, kind: SwiftDeclarationKind,
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
        substructure: [SourceKittenDictionary]) -> [StyleViolation] {
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
            }

            // If dictionary did not represent a View with a tap gesture, recursively check substructure,
            // unless it's a container that hides its children from accessibility.
            else if dictionary.substructure.isNotEmpty {
                if dictionary.hasAccessibilityHiddenModifier(in: file) ||
                    dictionary.hasAccessibilityElementChildrenIgnoreModifier(in: file) {
                    continue
                }

                violations.append(contentsOf:
                    findButtonTraitViolations(file: file, substructure: dictionary.substructure)
                )
            }
        }

        return violations
    }
}

// MARK: SourceKittenDictionary extensions

private extension SourceKittenDictionary {
    /// Whether or not the dictionary represents a SwiftUI View with a tap gesture
    /// modifier where the `count` argument is 1.
    func hasOnSingleTapModifier(in file: SwiftLintFile) -> Bool {
        guard expressionKind == .call, let name = name else {
            return false
        }

        // Check for onTapGesture modifier.
        if name.hasSuffix("onTapGesture") {
            // If there's a count argument, the value must be 1 for these purposes.
            if let countArg = enclosedArguments.first(where: { $0.name == "count" }) {
                if countArg.getArgumentValue(in: file) == "1" {
                    return true
                }
            } else {
                // If there is no count argument specified, the default value is 1.
                return true
            }
        }

        // Check for gesture, simultaneousGesture, or highPriorityGesture modifiers with TapGesture
        if name.hasSuffix("gesture") ||
            name.hasSuffix("simultaneousGesture") ||
            name.hasSuffix("highPriorityGesture") {
            // Single unnamed argument will start with the gesture literal.
            // We only care about TapGestures that have count 1 (1 is default) if not specified).
            if let gestureArg = getSingleUnnamedArgumentValue(in: file),
               gestureArg.hasPrefix("TapGesture()") || gestureArg.hasPrefix("TapGesture(count: 1)") {
                return true
            }
        }

        // Recursively check substructure.
        // SwiftUI literal Views with modifiers will have a SourceKittenDictionary structure like:
        // Image("myImage").onTapGesture { }.accessibilityAddTraits
        //     '--> Image("myImage").onTapGesture
        return substructure.contains(where: { $0.hasOnSingleTapModifier(in: file) })
    }

    /// Whether or not the dictionary represents a SwiftUI View with an `accessibilityAddTraits()` or
    /// `accessibility(addTraits:)` modifier with the specified trait (specify trait as a String).
    func hasAccessibilityTrait(_ trait: String, in file: SwiftLintFile) -> Bool {
        guard expressionKind == .call, let name = name else {
            return false
        }

        // Check for iOS 14+ version of modifier
        if name.hasSuffix("accessibilityAddTraits") &&
            getSingleUnnamedArgumentValue(in: file)?.contains(trait) == true {
            return true
        }

        // Check for iOS 13 version of modifier
        if name.hasSuffix("accessibility"),
           let addTraitsArg = enclosedArguments.first(where: { $0.name == "addTraits" }),
           addTraitsArg.getArgumentValue(in: file)?.contains(trait) == true {
            return true
        }

        // Recursively check substructure.
        // SwiftUI literal Views with modifiers will have a SourceKittenDictionary structure like:
        // Image("myImage").resizable().accessibility(addTraits: .isButton).frame
        //     '--> Image("myImage").resizable().accessibility
        return substructure.contains(where: { $0.hasAccessibilityTrait(trait, in: file) })
    }

    // MARK: Below four functions are also defined in AccessibilityLabelForImageRule and could be extracted
    // to some common file for extensions to help with parsing SwiftUI AST

    /// Whether or not the dictionary represents a SwiftUI View with an `accesibilityHidden(true)`
    /// or `accessibility(hidden: true)` modifier.
    func hasAccessibilityHiddenModifier(in file: SwiftLintFile) -> Bool {
        guard expressionKind == .call, let name = name else {
            return false
        }

        // Check for iOS 14+ version of modifier
        if name.hasSuffix("accessibilityHidden") && getSingleUnnamedArgumentValue(in: file) == "true" {
            return true
        }

        // Check for iOS 13 version of modifier
        if name.hasSuffix("accessibility"),
            let hiddenArg = enclosedArguments.first(where: { $0.name == "hidden" }),
            hiddenArg.getArgumentValue(in: file) == "true" {
            return true
        }

        // Recursively check substructure.
        // SwiftUI literal Views with modifiers will have a SourceKittenDictionary structure like:
        // Image("myImage").resizable().accessibility(hidden: true).frame
        //     '--> Image("myImage").resizable().accessibility
        return substructure.contains(where: { $0.hasAccessibilityHiddenModifier(in: file) })
    }

    /// Whether or not the dictionary represents a SwiftUI View with an `accessibilityElement()` or
    /// `accessibilityElement(children: .ignore)` modifier (`.ignore` is the default parameter value).
    func hasAccessibilityElementChildrenIgnoreModifier(in file: SwiftLintFile) -> Bool {
        guard expressionKind == .call, let name = name else {
            return false
        }

        // Check for modifier.
        if name.hasSuffix("accessibilityElement") {
            if enclosedArguments.isEmpty {
                return true
            }

            if let childrenArg = enclosedArguments.first(where: { $0.name == "children" }),
                childrenArg.getArgumentValue(in: file) == ".ignore" {
                return true
            }
        }

        // Recursively check substructure.
        // SwiftUI literal Views with modifiers will have a SourceKittenDictionary structure like:
        // VStack { ... }.accessibilityElement().padding
        //     '--> VStack { ... }.accessibilityElement
        return substructure.contains(where: { $0.hasAccessibilityElementChildrenIgnoreModifier(in: file) })
    }

    /// Helper to get the value of an argument.
    func getArgumentValue(in file: SwiftLintFile) -> String? {
        guard expressionKind == .argument, let bodyByteRange = bodyByteRange else {
            return nil
        }

        return file.stringView.substringWithByteRange(bodyByteRange)
    }

    /// Helper to get the value of a single unnamed argument to a function call.
    func getSingleUnnamedArgumentValue(in file: SwiftLintFile) -> String? {
        guard expressionKind == .call, let bodyByteRange = bodyByteRange else {
            return nil
        }

        return file.stringView.substringWithByteRange(bodyByteRange)
    }
}
