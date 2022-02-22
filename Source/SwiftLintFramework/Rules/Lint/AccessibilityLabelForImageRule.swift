import Foundation
import SourceKittenFramework

/// In UIKit, a `UIImageView` was by default not an accessibility element, and would only be visible to VoiceOver
/// and other assistive technologies if the developer explicitly made them an accessibility element. In SwiftUI,
/// however, an `Image` is an accessibility element by default. If the developer does not explicitly hide them from
/// accessibility or give them an accessibility label, they will inherit the name of the image file, which often creates
/// a poor experience when VoiceOver reads things like "close icon white".
///
/// Known false negatives for Images declared as instance variables and containers that provide a label but are not accessibility elements.
public struct AccessibilityLabelForImageRule: ASTRule, ConfigurationProviderRule, AutomaticTestableRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "accessibility_label_for_image",
        name: "Accessibility Label for Image",
        description: "All Images should either be hidden from accessibility or provide an accessibility label.",
        kind: .lint,
        minSwiftVersion: .fiveDotOne,
        nonTriggeringExamples: [
            Example("""
            struct MyView: View {
                var body: some View {
                    Image(decorative: "my-image")
                }
            }
            """),
            Example("""
            struct MyView: View {
                var body: some View {
                    Image("my-image")
                        .accessibility(hidden: true)
                }
            }
            """),
            Example("""
            struct MyView: View {
                var body: some View {
                    Image("my-image")
                        .accessibilityHidden(true)
                }
            }
            """),
            Example("""
            struct MyView: View {
                var body: some View {
                    Image("my-image")
                        .accessibility(label: Text("Alt text for my image")
                }
            }
            """),
            Example("""
            struct MyView: View {
                var body: some View {
                    Image("my-image")
                        .accessibilityLabel(Text("Alt text for my image"))
                }
            }
            """),
            Example("""
            struct MyView: View {
                var body: some View {
                    Image(uiImage: myUiImage)
                        .renderingMode(.template)
                        .foregroundColor(.blue)
                        .accessibilityHidden(true)
                }
            }
            """),
            Example("""
            struct MyView: View {
                var body: some View {
                    Image(uiImage: myUiImage)
                        .accessibilityLabel(Text("Alt text for my image"))
                }
            }
            """),
            Example("""
            struct MyView: View {
                var body: some View {
                    SwiftUI.Image(uiImage: "my-image").resizable().accessibilityHidden(true)
                }
            }
            """),
            Example("""
            struct MyView: View {
                var body: some View {
                    VStack {
                        Image(decorative: "my-image")
                            .renderingMode(.template)
                            .foregroundColor(.blue)
                        Image("my-image")
                            .accessibility(label: Text("Alt text for my image"))
                    }
                }
            }
            """),
            Example("""
            struct MyView: View {
                var body: some View {
                    VStack {
                        Image("my-image")
                            .renderingMode(.template)
                            .foregroundColor(.blue)
                        Image("my-image")
                            .accessibility(label: Text("Alt text for my image"))
                    }.accessibilityElement()
                }
            }
            """),
            Example("""
            struct MyView: View {
                var body: some View {
                    VStack {
                        Image("my-image")
                            .renderingMode(.template)
                            .foregroundColor(.blue)
                        Image("my-image")
                            .accessibility(label: Text("Alt text for my image"))
                    }.accessibilityHidden(true)
                }
            }
            """),
            Example("""
            struct MyView: View {
                var body: some View {
                    HStack(spacing: 8) {
                        Image(decorative: "my-image")
                            .renderingMode(.template)
                            .foregroundColor(.blue)
                        Text("Text to accompany my image")
                    }.accessibilityElement(children: .combine)
                    .padding(16)
                }
            }
            """),
            Example("""
            struct MyView: View {
                var body: some View {
                    HStack(spacing: 8) {
                        Image("my-image")
                            .renderingMode(.template)
                            .foregroundColor(.blue)
                        Text("Text to accompany my image")
                    }.accessibilityElement(children: .ignore)
                    .padding(16)
                    .accessibilityLabel(Text("Label for my image and text"))
                }
            }
            """),
            Example("""
            struct MyView: View {
                var body: some View {
                    Button(action: { doAction() }) {
                        Image("my-image")
                            .renderingMode(.template)
                            .foregroundColor(.blue)
                    }
                    .accessibilityLabel(Text("Label for my image"))
                }
            }
            """)
        ],
        triggeringExamples: [
            Example("""
            struct MyView: View {
                var body: some View {
                    ↓Image("my-image")
                        .resizable(true)
                        .frame(width: 48, height: 48)
                }
            }
            """),
            Example("""
            struct MyView: View {
                var body: some View {
                    ↓Image(uiImage: myUiImage)
                }
            }
            """),
            Example("""
            struct MyView: View {
                var body: some View {
                    ↓SwiftUI.Image(uiImage: "my-image").resizable().accessibilityHidden(false)
                }
            }
            """),
            Example("""
            struct MyView: View {
                var body: some View {
                    Image(uiImage: myUiImage)
                        .resizable()
                        .frame(width: 48, height: 48)
                        .accessibilityLabel(Text("Alt text for my image"))
                    ↓Image("other image")
                }
            }
            """),
            Example("""
            struct MyView: View {
                var body: some View {
                    Image(decorative: "image1")
                    ↓Image("image2")
                    Image(uiImage: "image3")
                        .accessibility(label: Text("a pretty picture"))
                }
            }
            """),
            Example("""
            struct MyView: View {
                var body: some View {
                    VStack {
                        Image(decorative: "my-image")
                            .renderingMode(.template)
                            .foregroundColor(.blue)
                        ↓Image("my-image")
                    }
                }
            }
            """),
            Example("""
            struct MyView: View {
                var body: some View {
                    VStack {
                        ↓Image("my-image")
                            .renderingMode(.template)
                            .foregroundColor(.blue)
                        Image("my-image")
                            .accessibility(label: Text("Alt text for my image"))
                    }.accessibilityElement(children: .contain)
                }
            }
            """),
            Example("""
            struct MyView: View {
                var body: some View {
                    VStack {
                        ↓Image("my-image")
                            .renderingMode(.template)
                            .foregroundColor(.blue)
                        Image("my-image")
                            .accessibility(label: Text("Alt text for my image"))
                    }.accessibilityHidden(false)
                }
            }
            """),
            Example("""
            struct MyView: View {
                var body: some View {
                    HStack(spacing: 8) {
                        ↓Image("my-image")
                            .renderingMode(.template)
                            .foregroundColor(.blue)
                        Text("Text to accompany my image")
                    }.accessibilityElement(children: .combine)
                    .padding(16)
                }
            }
            """),
            Example("""
            struct MyView: View {
                var body: some View {
                    Button(action: { doAction() }) {
                        ↓Image("my-image")
                            .renderingMode(.template)
                            .foregroundColor(.blue)
                    }
                }
            }
            """)
        ]
    )

    // MARK: AST Rule
    
    public func validate(file: SwiftLintFile, kind: SwiftDeclarationKind, dictionary: SourceKittenDictionary) -> [StyleViolation] {
        // only proceed to check View structs
        guard kind == .struct,
            dictionary.inheritedTypes.contains("View"),
            dictionary.substructure.isNotEmpty else {
                return []
        }

        return findImageViolations(file: file, substructure: dictionary.substructure)
    }
    
    /// recursively check a file for image violations, and return all such violations
    private func findImageViolations(file: SwiftLintFile, substructure: [SourceKittenDictionary]) -> [StyleViolation] {
        var violations: [StyleViolation] = []
        for dictionary in substructure {
            guard let offset: ByteCount = dictionary.offset else {
                continue
            }
                        
            // if it's image, and does not hide from accessibility or provide a label, it's a violation
            if dictionary.isImage {
                if !(dictionary.isDecorativeImage ||
                  dictionary.hasAccessibilityHiddenModifier(in: file) ||
                  dictionary.hasAccessibilityLabelModifier) {
                    violations.append(StyleViolation(ruleDescription: Self.description, severity: configuration.severity, location: Location(file: file, byteOffset: offset)))
                }
            }
            
            // if dictionary did not represent an Image, recursively check substructure unless it's a container that hides its children from accessibility or is labeled
            else if dictionary.substructure.isNotEmpty,
                        !(dictionary.hasAccessibilityHiddenModifier(in: file) ||
                          dictionary.hasAccessibilityElementChildrenIgnoreModifier(in: file) ||
                          dictionary.hasAccessibilityLabelModifier) {
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
        // image literals will be reported as calls to the initializer
        guard expressionKind == .call else {
            return false
        }
        
        if name == "Image" || name == "SwiftUI.Image" {
            return true
        }
        
        // recursively check substructure
        // SwiftUI literal Views with modifiers will have a SourceKittenDictionary structure like:
        // Image(decorative: "myImage").resizable().frame
        //     '--> Image(decorative: "myImage").resizable
        //         '--> Image
        for dict in substructure {
            if dict.isImage {
                return true
            }
        }
        
        return false
    }
    
    /// Whether or not the dictionary represents a SwiftUI Image using the `Image(decorative:)` constructor
    var isDecorativeImage: Bool {
        guard isImage else {
            return false
        }
        
        // check for Image(decorative:) constructor
        if expressionKind == .call && enclosedArguments.contains(where: { $0.name == "decorative" }) {
            return true
        }
        
        // recursively check substructure
        // SwiftUI literal Views with modifiers will have a SourceKittenDictionary structure like:
        // Image(decorative: "myImage").resizable().frame
        //     '--> Image(decorative: "myImage").resizable
        //         '--> Image
        for dict in substructure {
            if dict.isDecorativeImage {
                return true
            }
        }
        
        return false
    }
    
    /// Whether or not the dictionary represents a SwiftUI View with an `accesibilityHidden(true)` or `accessibility(hidden: true)` modifier.
    func hasAccessibilityHiddenModifier(in file: SwiftLintFile) -> Bool {
        guard expressionKind == .call, let name: String = name else {
            return false
        }
        
        // check for iOS 14+ version of modifier
        if name.hasSuffix("accessibilityHidden") && getSingleUnnamedArgumentValue(in: file) == "true" {
            return true
        }
        
        // check for iOS 13 version of modifier
        if name.hasSuffix("accessibility"), let hiddenArg: SourceKittenDictionary = enclosedArguments.first(where: { $0.name == "hidden" }), hiddenArg.getArgumentValue(in: file) == "true" {
            return true
        }
        
        // recursively check substructure
        // SwiftUI literal Views with modifiers will have a SourceKittenDictionary structure like:
        // Image("myImage").resizable().accessibility(hidden: true).frame
        //     '--> Image("myImage").resizable().accessibility
        for dict in substructure {
            if dict.hasAccessibilityHiddenModifier(in: file) {
                return true
            }
        }
        
        return false
    }
    
    /// Whether or not the dictionary represents a SwiftUI View with an `accesibilityLabel(_:)` or `accessibility(label:)` modifier.
    var hasAccessibilityLabelModifier: Bool {
        guard expressionKind == .call, let name: String = name else {
            return false
        }
        
        // check for iOS 14+ version of modifier
        if name.hasSuffix("accessibilityLabel") {
            return true
        }
        
        // check for iOS 13 version of modifier
        if name.hasSuffix("accessibility"), enclosedArguments.contains(where: { $0.name == "label" }) {
            return true
        }
        
        // recursively check substructure
        // SwiftUI literal Views with modifiers will have a SourceKittenDictionary structure like:
        // Image("myImage").resizable().accessibilityLabel(Text("Label")).frame
        //     '--> Image("myImage").resizable().accessibilityLabel
        for dict in substructure {
            if dict.hasAccessibilityLabelModifier {
                return true
            }
        }
        
        return false
    }
    
    /// Whether or not the dictionary represents a SwiftUI View with an `accessibilityElement()` or `accessibilityElement(children: .ignore)` modifier (`.ignore` is the default parameter value).
    func hasAccessibilityElementChildrenIgnoreModifier(in file: SwiftLintFile) -> Bool {
        guard expressionKind == .call, let name: String = name else {
            return false
        }
        
        // check for modifier
        if name.hasSuffix("accessibilityElement") {
            if enclosedArguments.isEmpty {
                return true
            }
            
            if let childrenArg: SourceKittenDictionary = enclosedArguments.first(where: { $0.name == "children" }), childrenArg.getArgumentValue(in: file) == ".ignore" {
                return true
            }
        }
        
        // recursively check substructure
        // SwiftUI literal Views with modifiers will have a SourceKittenDictionary structure like:
        // VStack { ... }.accessibilityElement().padding
        //     '--> VStack { ... }.accessibilityElement
        for dict in substructure {
            if dict.hasAccessibilityElementChildrenIgnoreModifier(in: file) {
                return true
            }
        }
        
        return false
    }
    
    /// Helper to get the value of an argument
    func getArgumentValue(in file: SwiftLintFile) -> String? {
        guard expressionKind == .argument, let bodyByteRange: ByteRange = bodyByteRange else {
            return nil
        }
        
        return file.stringView.substringWithByteRange(bodyByteRange)
    }
    
    /// Helper to get the value of a single unnamed argument to a function call
    func getSingleUnnamedArgumentValue(in file: SwiftLintFile) -> String? {
        guard expressionKind == .call, let bodyByteRange: ByteRange = bodyByteRange else {
            return nil
        }
        
        return file.stringView.substringWithByteRange(bodyByteRange)
    }
}
