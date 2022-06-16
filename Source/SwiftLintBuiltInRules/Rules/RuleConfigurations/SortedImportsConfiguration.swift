struct SortedImportsConfiguration: RuleConfiguration, Equatable {
    typealias Parent = SortedImportsRule

    enum SortedImportsGroupingConfiguration: String {
        /// Sorts import lines based on any import attributes (e.g. `@testable`, `@_exported`, etc.), followed by a case
        /// insensitive comparison of the imported module name.
        case attributes
        /// Sorts import lines based on a case insensitive comparison of the imported module name.
        case names
    }

    private(set) var severity = SeverityConfiguration<Parent>(.warning)
    private(set) var grouping = SortedImportsGroupingConfiguration.names

    var parameterDescription: RuleConfigurationDescription? {
        severity
        "grouping" => .symbol(grouping.rawValue)
    }

    mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw Issue.unknownConfiguration(ruleID: Parent.identifier)
        }

        if let rawGrouping = configuration["grouping"] {
            guard let rawGrouping = rawGrouping as? String,
                  let grouping = SortedImportsGroupingConfiguration(rawValue: rawGrouping) else {
                throw Issue.unknownConfiguration(ruleID: Parent.identifier)
            }
            self.grouping = grouping
        }

        if let severityString = configuration["severity"] as? String {
            try severity.apply(configuration: severityString)
        }
    }
}
