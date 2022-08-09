import SourceKittenFramework

public struct ProhibitedInterfaceBuilderRule: ConfigurationProviderRule, ASTRule, OptInRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "prohibited_interface_builder",
        name: "Prohibited Interface Builder",
        description: "Creating views using Interface Builder should be avoided.",
        kind: .lint,
        nonTriggeringExamples: [
            wrapExample("var label: UILabel!"),
            wrapExample("@objc func buttonTapped(_ sender: UIButton) {}")
        ],
        triggeringExamples: [
            wrapExample("@IBOutlet ↓var label: UILabel!"),
            wrapExample("@IBAction ↓func buttonTapped(_ sender: UIButton) {}")
        ]
    )

    public func validate(file: SwiftLintFile, kind: SwiftDeclarationKind,
                         dictionary: SourceKittenDictionary) -> [StyleViolation] {
        guard let offset = dictionary.offset else {
            return []
        }

        func makeViolation() -> StyleViolation {
            return StyleViolation(ruleDescription: Self.description,
                                  severity: configuration.severity,
                                  location: Location(file: file, byteOffset: offset))
        }

        if kind == .varInstance && dictionary.enclosedSwiftAttributes.contains(.iboutlet) {
            return [makeViolation()]
        }

        if kind == .functionMethodInstance && dictionary.enclosedSwiftAttributes.contains(.ibaction) {
            return [makeViolation()]
        }

        return []
    }
}

private func wrapExample(_ text: String, file: StaticString = #file, line: UInt = #line) -> Example {
    return Example("""
    class ViewController: UIViewController {
        \(text)
    }
    """, file: file, line: line)
}
