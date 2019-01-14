import SourceKittenFramework

public struct StrongIBOutletRule: ConfigurationProviderRule, ASTRule, OptInRule, AutomaticTestableRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "strong_iboutlet",
        name: "Strong IBOutlet",
        description: "@IBOutlets shouldn't be declared as weak.",
        kind: .lint,
        nonTriggeringExamples: [
            "@IBOutlet var label: UILabel?",
            "weak var label: UILabel?"
        ].map(wrapExample),
        triggeringExamples: [
            "@IBOutlet weak ↓var label: UILabel?",
            "@IBOutlet unowned ↓var label: UILabel!",
            "@IBOutlet weak ↓var textField: UITextField?"
        ].map(wrapExample)
    )

    public func validate(file: File, kind: SwiftDeclarationKind,
                         dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        guard kind == .varInstance,
            case let attributes = dictionary.enclosedSwiftAttributes,
            attributes.contains(.iboutlet),
            attributes.contains(.weak),
            let offset = dictionary.offset else {
                return []
        }

        return [
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severity,
                           location: Location(file: file, byteOffset: offset))
        ]
    }
}

private func wrapExample(_ text: String) -> String {
    return """
    class ViewController: UIViewController {
        \(text)
    }
    """
}
