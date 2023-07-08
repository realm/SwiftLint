import SwiftLintCore

enum TypeContent: String, AcceptableByConfigurationElement {
    case `case` = "case"
    case typeAlias = "type_alias"
    case associatedType = "associated_type"
    case subtype = "subtype"
    case typeProperty = "type_property"
    case instanceProperty = "instance_property"
    case ibOutlet = "ib_outlet"
    case ibInspectable = "ib_inspectable"
    case initializer = "initializer"
    case typeMethod = "type_method"
    case viewLifeCycleMethod = "view_life_cycle_method"
    case ibAction = "ib_action"
    case otherMethod = "other_method"
    case `subscript` = "subscript"
    case deinitializer = "deinitializer"

    func asOption() -> OptionType { .symbol(rawValue) }
}

struct TypeContentsOrderConfiguration: SeverityBasedRuleConfiguration, Equatable {
    typealias Parent = TypeContentsOrderRule

    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "order")
    private(set) var order: [[TypeContent]] = [
        [.case],
        [.typeAlias, .associatedType],
        [.subtype],
        [.typeProperty],
        [.instanceProperty],
        [.ibInspectable],
        [.ibOutlet],
        [.initializer],
        [.typeMethod],
        [.viewLifeCycleMethod],
        [.ibAction],
        [.otherMethod],
        [.subscript],
        [.deinitializer]
    ]

    mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw Issue.unknownConfiguration(ruleID: Parent.identifier)
        }

        if let severityValue = configuration[$severityConfiguration] as? String {
            try severityConfiguration.apply(configuration: severityValue)
        }

        if let custom = configuration[$order] as? [Any] {
            order.removeAll()
            for entry in custom {
                if let singleEntry = entry as? String {
                    if let typeContent = TypeContent(rawValue: singleEntry) {
                        order.append([typeContent])
                    }
                } else if let arrayEntry = entry as? [String] {
                    let typeContents = arrayEntry.compactMap { TypeContent(rawValue: $0) }
                    order.append(typeContents)
                }
            }
        }
    }
}
