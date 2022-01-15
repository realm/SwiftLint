import Foundation
import SourceKittenFramework

/// In UIKit, a `UIImageView` was by default not an accessibility element, and would only be visible to VoiceOver and other assistive
/// technologies if the developer explicitly made them an accessibility element. In SwiftUI, however, an `Image` is an accessibility
/// element by default. If the developer does not explicitly hide them from accessibility or give them an accessibility label, they will
/// inherit the name of the image file, which often creates a poor experience when VoiceOver reads things like "close icon white".
public struct AccessibilityLabelForImageRule: ConfigurationProviderRule, AutomaticTestableRule {
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
            Image(decorative: "my-image")
            """),
            Example("""
            Image("my-image")
                .accessibility(hidden: true)
            """),
            Example("""
            Image("my-image")
                .accessibilityHidden(true)
            """),
            Example("""
            Image("my-image")
                .accessibility(label: Text("Alt text for my image")
            """),
            Example("""
            Image("my-image")
                .accessibilityLabel(Text("Alt text for my image"))
            """),
            Example("""
            Image(uiImage: myUiImage)
                .renderingMode(.template)
                .foregroundColor(.blue)
                .accessibilityHidden(true)
            """),
            Example("""
            Image(uiImage: myUiImage)
                .accessibilityLabel(Text("Alt text for my image"))
            """),
            Example("""
            SwiftUI.Image(uiImage: "my-image").resizable().accessibilityHidden(true)
            """)
        ],
        triggeringExamples: [
            Example("""
            ↓Image("my-image")
                .resizable(true)
                .frame(width: 48, height: 48)
            """),
            Example("""
            ↓Image(uiImage: myUiImage)
            """),
            Example("""
            SwiftUI.↓Image(uiImage: "my-image").resizable().accessibilityHidden(false)
            """),
            Example("""
            Image(uiImage: myUiImage)
                .resizable()
                .frame(width: 48, height: 48)
                .accessibilityLabel(Text("Alt text for my image"))
            ↓Image("other image")
            """),
            Example("""
            Image(decorative: "image1")
            ↓Image("image2")
            Image(uiImage: "image3")
                .accessibility(label: Text("a pretty picture"))
            """)
        ]
    )
    
    private var pattern: String {
        "\\bImage\\(" +                         // SwiftUI Image literal
        "(?!" +                                 // start negative lookahead
        "decorative:|" +                        // decorative constructor hides from accessibility, OR
        "[^\\n]*" +                             // any more other characters before a newline
        "(\\s*\\.[^\\n]*)*" +                 // any number of other modifiers
        "(" +                                   // options for modifiers to hide from accessibility or provide label
        "accessibility\\(hidden: true\\)|" +    // iOS 13 way of hiding, OR
        "accessibilityHidden\\(true\\)|" +      // iOS 14+ way of hiding, OR
        "accessibility\\(label:|" +             // iOS 13 way of setting label, OR
        "accessibilityLabel\\(" +               // iOS 14+ way of setting label
        "))"                                    // end groups
    }
    
    public func validate(file: SwiftLintFile) -> [StyleViolation] {
        return file.match(pattern: pattern, excludingSyntaxKinds: SyntaxKind.commentAndStringKinds).map {
            StyleViolation(ruleDescription: Self.description,
                           severity: configuration.severity,
                           location: Location(file: file, characterOffset: $0.location))
        }
    }
}
