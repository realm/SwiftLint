enum FileType: String {
    case supportingType = "supporting_type"
    case mainType = "main_type"
    case `extension` = "extension"
}

public struct FileTypesOrderConfiguration: RuleConfiguration {
    private(set) var severityConfiguration = SeverityConfiguration(.warning)
    private(set) var order: [[FileType]] = [
        [.supportingType],
        [.mainType],
        [.extension]
    ]

    public var consoleDescription: String {
        return severityConfiguration.consoleDescription +
            ", order: \(String(describing: order))"
    }

    public mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw ConfigurationError.unknownConfiguration
        }

        var customOrder = [[FileType]]()
        if let custom = configuration["order"] as? [Any] {
            for entry in custom {
                if let singleEntry = entry as? String {
                    if let fileType = FileType(rawValue: singleEntry) {
                        customOrder.append([fileType])
                    }
                } else if let arrayEntry = entry as? [String] {
                    let fileTypes = arrayEntry.compactMap { FileType(rawValue: $0) }
                    customOrder.append(fileTypes)
                }
            }
        }

        if !customOrder.isEmpty {
            self.order = customOrder
        }
    }
}

extension FileTypesOrderConfiguration: Equatable {
    public static func == (lhs: FileTypesOrderConfiguration, rhs: FileTypesOrderConfiguration) -> Bool {
        guard lhs.order.count == rhs.order.count else { return false }

        for (leftIndex, leftOrderEntry) in lhs.order.enumerated() {
            guard rhs.order[leftIndex] == leftOrderEntry else { return false }
        }

        return lhs.severityConfiguration == rhs.severityConfiguration
    }
}
