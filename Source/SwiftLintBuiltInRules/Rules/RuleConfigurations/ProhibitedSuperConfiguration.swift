import SwiftLintCore

@AutoConfigParser
struct ProhibitedSuperConfiguration: SeverityBasedRuleConfiguration {
    typealias Parent = ProhibitedSuperRule

    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "excluded")
    private(set) var excluded = [String]()
    @ConfigurationElement(key: "included")
    private(set) var included = ["*"]

    private static let methodNames = [
        // NSFileProviderExtension
        "providePlaceholder(at:completionHandler:)",
        // NSTextInput
        "doCommand(by:)",
        // NSView
        "updateLayer()",
        // UIViewController
        "loadView()",
    ]

    var resolvedMethodNames: [String] {
        var names = [String]()
        if included.contains("*") && !excluded.contains("*") {
            names += Self.methodNames
        }
        names += included.filter { $0 != "*" }
        names = names.filter { !excluded.contains($0) }
        return names
    }
}
