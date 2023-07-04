import SwiftLintCore

enum FileType: String, AcceptableByConfigurationElement {
    case supportingType = "supporting_type"
    case mainType = "main_type"
    case `extension` = "extension"
    case previewProvider = "preview_provider"
    case libraryContentProvider = "library_content_provider"

    func asOption() -> OptionType { .symbol(rawValue) }
}

struct FileTypesOrderConfiguration: SeverityBasedRuleConfiguration, Equatable {
    typealias Parent = FileTypesOrderRule

    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "order")
    private(set) var order: [[FileType]] = [
        [.supportingType],
        [.mainType],
        [.extension],
        [.previewProvider],
        [.libraryContentProvider]
    ]

    mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw Issue.unknownConfiguration(ruleID: Parent.identifier)
        }

        var customOrder = [[FileType]]()
        if let custom = configuration[$order] as? [Any] {
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
