import SwiftLintCore

private func toExplicitInitMethod(typeName: String) -> String {
    return "\(typeName).init"
}

struct DiscouragedDirectInitConfiguration: SeverityBasedRuleConfiguration, Equatable {
    typealias Parent = DiscouragedDirectInitRule

    @ConfigurationElement
    var severityConfiguration = SeverityConfiguration<Parent>(.warning)

    private static let defaultDiscouragedInits = [
        "Bundle",
        "NSError",
        "UIDevice"
    ]

    @ConfigurationElement(key: "types")
    private(set) var discouragedInits = Set(
        Self.defaultDiscouragedInits + Self.defaultDiscouragedInits.map(toExplicitInitMethod)
    )

    mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw Issue.unknownConfiguration(ruleID: Parent.identifier)
        }

        if let severityString = configuration["severity"] as? String {
            try severityConfiguration.apply(configuration: severityString)
        }

        if let types = [String].array(of: configuration["types"]) {
            discouragedInits = Set(types + types.map(toExplicitInitMethod))
        }
    }
}
