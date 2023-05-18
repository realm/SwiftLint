enum FileType: String {
    case supportingType = "supporting_type"
    case mainType = "main_type"
    case `extension` = "extension"
    case previewProvider = "preview_provider"
    case libraryContentProvider = "library_content_provider"
}

struct FileTypesOrderConfiguration: SeverityBasedRuleConfiguration, Equatable {
    typealias Parent = FileTypesOrderRule

    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    private(set) var order: [[FileType]] = [
        [.supportingType],
        [.mainType],
        [.extension],
        [.previewProvider],
        [.libraryContentProvider]
    ]

    var consoleDescription: String {
        return "severity: \(severityConfiguration.consoleDescription)" +
            ", order: \(String(describing: order))"
    }

    mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw Issue.unknownConfiguration(ruleID: Parent.identifier)
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

        if customOrder.isNotEmpty {
            self.order = customOrder
        }
    }
}
