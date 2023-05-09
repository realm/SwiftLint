struct SortedImportsConfiguration: RuleConfiguration, Equatable {
    typealias Parent = SortedImportsRule

    enum SortedImportsGroupingConfiguration: String {
        /// Sorts import lines based on any import attributes (e.g. `@testable`, `@_exported`, etc.), followed by a case
        /// insensitive comparison of the imported module name.
        case attributes
        /// Sorts import lines based on a case insensitive comparison of the imported module name.
        case names

        init(value: Any) throws {
            if let string = value as? String,
               let value = Self(rawValue: string) {
               self = value
            } else {
                throw Issue.unknownConfiguration(ruleID: Parent.identifier)
            }
        }
    }

    private(set) var severity = SeverityConfiguration<Parent>(.warning)
    private(set) var grouping = SortedImportsGroupingConfiguration.names

    var consoleDescription: String {
        return "severity: \(severity.consoleDescription)"
            + ", grouping: \(grouping)"
    }

    mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw Issue.unknownConfiguration(ruleID: Parent.identifier)
        }

        if let grouping = configuration["grouping"] as? String {
            self.grouping = try SortedImportsGroupingConfiguration(value: grouping)
        }
        if let severityString = configuration["severity"] as? String {
            try severity.apply(configuration: severityString)
        }
    }
}
