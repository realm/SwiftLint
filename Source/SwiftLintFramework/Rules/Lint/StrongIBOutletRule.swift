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
            wrapExample("@IBOutlet var label: UILabel?"),
            wrapExample("weak var label: UILabel?")
        ],
        triggeringExamples: [
            wrapExample("@IBOutlet weak ↓var label: UILabel?"),
            wrapExample("@IBOutlet unowned ↓var label: UILabel!"),
            wrapExample("@IBOutlet weak ↓var textField: UITextField?")
        ]
    )

    public func validate(file: SwiftLintFile, kind: SwiftDeclarationKind,
                         dictionary: SourceKittenDictionary) -> [StyleViolation] {
        guard kind == .varInstance,
            case let attributes = dictionary.enclosedSwiftAttributes,
            attributes.contains(.iboutlet),
            attributes.contains(.weak),
            let offset = dictionary.offset
        else {
            return []
        }

        return [
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severity,
                           location: Location(file: file, byteOffset: offset))
        ]
    }
}

private func wrapExample(_ text: String, file: StaticString = #file, line: UInt = #line) -> Example {
    return Example("""
    class ViewController: UIViewController {
        \(text)
    }
    """, file: file, line: line)
}
