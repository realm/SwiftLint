import SwiftLintCore

@AutoConfigParser
struct FileTypesOrderConfiguration: SeverityBasedRuleConfiguration {
    typealias Parent = FileTypesOrderRule

    @AcceptableByConfigurationElement
    enum FileType: String {
        case supportingType = "supporting_type"
        case mainType = "main_type"
        case `extension` = "extension"
        case previewProvider = "preview_provider"
        case libraryContentProvider = "library_content_provider"
    }

    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "order")
    private(set) var order: [[FileType]] = [
        [.supportingType],
        [.mainType],
        [.extension],
        [.previewProvider],
        [.libraryContentProvider],
    ]
}
