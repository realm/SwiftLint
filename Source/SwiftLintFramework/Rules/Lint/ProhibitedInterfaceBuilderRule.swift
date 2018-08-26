import SourceKittenFramework

public struct ProhibitedInterfaceBuilderRule: ConfigurationProviderRule, ASTRule, OptInRule, AutomaticTestableRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "prohibited_interface_builder",
        name: "Prohibited Interface Builder",
        description: "Creating views using Interface Builder should be avoided.",
        kind: .lint,
        nonTriggeringExamples: [
            "var label: UILabel!",
            "@objc func buttonTapped(_ sender: UIButton) {}"
        ].map(wrapExample),
        triggeringExamples: [
            "@IBOutlet ↓var label: UILabel!",
            "@IBAction ↓func buttonTapped(_ sender: UIButton) {}"
        ].map(wrapExample)
    )

    public func validate(file: File, kind: SwiftDeclarationKind,
                         dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        guard let offset = dictionary.offset else {
            return []
        }

        func makeViolation() -> StyleViolation {
            return StyleViolation(ruleDescription: type(of: self).description,
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

private func wrapExample(_ text: String) -> String {
    return """
    class ViewController: UIViewController {
        \(text)
    }
    """
}
