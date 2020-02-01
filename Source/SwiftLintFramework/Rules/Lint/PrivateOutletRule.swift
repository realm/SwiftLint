import SourceKittenFramework

public struct PrivateOutletRule: ASTRule, OptInRule, ConfigurationProviderRule {
    public var configuration = PrivateOutletRuleConfiguration(allowPrivateSet: false)

    public init() {}

    public static let description = RuleDescription(
        identifier: "private_outlet",
        name: "Private Outlets",
        description: "IBOutlets should be private to avoid leaking UIKit to higher layers.",
        kind: .lint,
        nonTriggeringExamples: [
            Example("class Foo {\n  @IBOutlet private var label: UILabel?\n}\n"),
            Example("class Foo {\n  @IBOutlet private var label: UILabel!\n}\n"),
            Example("class Foo {\n  var notAnOutlet: UILabel\n}\n"),
            Example("class Foo {\n  @IBOutlet weak private var label: UILabel?\n}\n"),
            Example("class Foo {\n  @IBOutlet private weak var label: UILabel?\n}\n")
        ],
        triggeringExamples: [
            Example("class Foo {\n  @IBOutlet ↓var label: UILabel?\n}\n"),
            Example("class Foo {\n  @IBOutlet ↓var label: UILabel!\n}\n")
        ]
    )

    public func validate(file: SwiftLintFile, kind: SwiftDeclarationKind,
                         dictionary: SourceKittenDictionary) -> [StyleViolation] {
        guard kind == .varInstance else {
            return []
        }

        // Check if IBOutlet
        let isOutlet = dictionary.enclosedSwiftAttributes.contains(.iboutlet)
        guard isOutlet else { return [] }

        // Check if private
        let isPrivate = dictionary.accessibility?.isPrivate ?? false
        let isPrivateSet = isPrivateLevel(identifier: dictionary.setterAccessibility)

        if isPrivate || (configuration.allowPrivateSet && isPrivateSet) {
            return []
        }

        // Violation found!
        let location: Location
        if let offset = dictionary.offset {
            location = Location(file: file, byteOffset: offset)
        } else {
            location = Location(file: file.path)
        }

        return [
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severityConfiguration.severity,
                           location: location)
        ]
    }

    private func isPrivateLevel(identifier: String?) -> Bool {
        return identifier.flatMap(AccessControlLevel.init(identifier:))?.isPrivate ?? false
    }
}
