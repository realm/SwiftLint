import SwiftLintCore

@AcceptableByConfigurationElement
enum TypeContent: String {
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
    case ibSegueAction = "ib_segue_action"
}

@AutoConfigParser
struct TypeContentsOrderConfiguration: SeverityBasedRuleConfiguration {
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
        [.deinitializer],
    ]
}
