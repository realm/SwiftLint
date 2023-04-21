struct TypeMemberOrderConfiguration: RuleConfiguration, SeverityBasedRuleConfiguration, Equatable {
    private(set) var severityConfiguration = SeverityConfiguration(.warning)

    /// Indicates whether members of each type should be considered as separate groups, or if
    /// all members should be alphabetically ordered together. If true, each different type of
    /// member will be considered as a separate group.
    private(set) var separateByMemberTypes = true

    /// Indicates whether MARK: comments should "reset" sorting. If true, a MARK: will delineate
    /// a new group for the purposes of ordering.
    private(set) var separateByMarks = true

    var consoleDescription: String {
        "separateByMemberTypes: \(separateByMemberTypes), separateByMarks: \(separateByMarks)"
    }

    mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw ConfigurationError.unknownConfiguration
        }

        if let separateByMemberTypes = configuration["separate_by_member_types"] as? Bool {
            self.separateByMemberTypes = separateByMemberTypes
        }
        if let separateByMarks = configuration["separate_by_marks"] as? Bool {
            self.separateByMarks = separateByMarks
        }
    }
}
