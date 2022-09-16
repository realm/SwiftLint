import SourceKittenFramework

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

    // swiftlint:disable:next cyclomatic_complexity function_body_length
    init?(structure: SourceKittenDictionary) {
        guard let typeContentKind = structure.declarationKind else { return nil }

        switch typeContentKind {
        case .enumcase, .enumelement:
            self = .case

        case .typealias:
            self = .typeAlias

        case .associatedtype:
            self = .associatedType

        case .class, .enum, .extension, .protocol, .struct:
            self = .subtype

        case .varClass, .varStatic:
            self = .typeProperty

        case .varInstance:
            if structure.enclosedSwiftAttributes.contains(.iboutlet) {
                self = .ibOutlet
            } else if structure.enclosedSwiftAttributes.contains(.ibinspectable) {
                self = .ibInspectable
            } else {
                self = .instanceProperty
            }

        case .functionMethodClass, .functionMethodStatic:
            self = .typeMethod

        case .functionMethodInstance:
            let viewLifecycleMethodNames = [
                "loadView(",
                "loadViewIfNeeded(",
                "viewDidLoad(",
                "viewWillAppear(",
                "viewWillLayoutSubviews(",
                "viewDidLayoutSubviews(",
                "viewDidAppear(",
                "viewWillDisappear(",
                "viewDidDisappear("
            ]

            if structure.name!.starts(with: "init(") {
                self = .initializer
            } else if structure.name!.starts(with: "deinit") {
                self = .deinitializer
            } else if viewLifecycleMethodNames.contains(where: { structure.name!.starts(with: $0) }) {
                self = .viewLifeCycleMethod
            } else if structure.enclosedSwiftAttributes.contains(SwiftDeclarationAttributeKind.ibaction) {
                self = .ibAction
            } else {
                self = .otherMethod
            }

        case .functionSubscript:
            self = .subscript

        default:
            return nil
        }
    }
}

public struct TypeContentsOrderConfiguration: RuleConfiguration, Equatable {
    private(set) var severityConfiguration = SeverityConfiguration(.warning)
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

    public var consoleDescription: String {
        return severityConfiguration.consoleDescription +
            ", order: \(String(describing: order))"
    }

    public mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw ConfigurationError.unknownConfiguration
        }

        var customOrder = [[TypeContent]]()
        if let custom = configuration["order"] as? [Any] {
            for entry in custom {
                if let singleEntry = entry as? String {
                    if let typeContent = TypeContent(rawValue: singleEntry) {
                        customOrder.append([typeContent])
                    }
                } else if let arrayEntry = entry as? [String] {
                    let typeContents = arrayEntry.compactMap { TypeContent(rawValue: $0) }
                    customOrder.append(typeContents)
                }
            }
        }

        if customOrder.isNotEmpty {
            self.order = customOrder
        }
    }
}
