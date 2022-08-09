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
public struct AccessibilityLabelForImageRule: ASTRule, ConfigurationProviderRule, OptInRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "accessibility_label_for_image",
        name: "Accessibility Label for Image",
        description: "All Images that provide context should have an accessibility label. " +
                    "Purely decorative images can be hidden from accessibility.",
        kind: .lint,
        minSwiftVersion: .fiveDotOne,
        nonTriggeringExamples: AccessibilityLabelForImageRuleExamples.nonTriggeringExamples,
        triggeringExamples: AccessibilityLabelForImageRuleExamples.triggeringExamples
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
                if dictionary.isDecorativeOrLabeledOrSystemImage ||
                  dictionary.hasAccessibilityHiddenModifier(in: file) ||
                  dictionary.hasAccessibilityLabelModifier {
                    continue
                }

                violations.append(
                    StyleViolation(ruleDescription: Self.description,
                                   severity: configuration.severity,
                                   location: Location(file: file, byteOffset: offset))
                )
            }

            // If dictionary did not represent an Image, recursively check substructure,
            // unless it's a container that hides its children from accessibility or is labeled.
            else if dictionary.substructure.isNotEmpty {
                if dictionary.hasAccessibilityHiddenModifier(in: file) ||
                    dictionary.hasAccessibilityElementChildrenIgnoreModifier(in: file) ||
                    dictionary.hasAccessibilityLabelModifier {
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
        //     '--> Image(decorative: "myImage").resizable
        //         '--> Image
        return substructure.contains(where: { $0.isImage })
    }

    /// Whether or not the dictionary represents a SwiftUI Image using the `Image(decorative:)` constructor (hides
    /// from a11y), or one of the `Image(_:label:)` or `Image(systemName:)` constructors (provides label).
    var isDecorativeOrLabeledOrSystemImage: Bool {
        guard isImage else {
            return false
        }

        // Check for Image(decorative:), Image(_:label:), or Image(systemName:) constructor.
        if expressionKind == .call &&
            enclosedArguments.contains(where: { ["decorative", "label", "systemName"].contains($0.name) }) {
            return true
        }

        // Recursively check substructure.
        // SwiftUI literal Views with modifiers will have a SourceKittenDictionary structure like:
        // Image(decorative: "myImage").resizable().frame
        //     '--> Image(decorative: "myImage").resizable
        //         '--> Image
        return substructure.contains(where: { $0.isDecorativeOrLabeledOrSystemImage })
    }

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

    /// Whether or not the dictionary represents a SwiftUI View with an `accesibilityLabel(_:)`
    /// or `accessibility(label:)` modifier.
    var hasAccessibilityLabelModifier: Bool {
        guard expressionKind == .call, let name = name else {
            return false
        }

        // Check for iOS 14+ version of modifier.
        if name.hasSuffix("accessibilityLabel") {
            return true
        }

        // Check for iOS 13 version of modifier.
        if name.hasSuffix("accessibility"), enclosedArguments.contains(where: { $0.name == "label" }) {
            return true
        }

        // Recursively check substructure.
        // SwiftUI literal Views with modifiers will have a SourceKittenDictionary structure like:
        // Image("myImage").resizable().accessibilityLabel(Text("Label")).frame
        //     '--> Image("myImage").resizable().accessibilityLabel
        return substructure.contains(where: { $0.hasAccessibilityLabelModifier })
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
