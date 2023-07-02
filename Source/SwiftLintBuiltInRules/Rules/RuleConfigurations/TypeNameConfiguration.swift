import SwiftLintCore

struct TypeNameConfiguration: RuleConfiguration, Equatable {
    typealias Parent = TypeNameRule

    @ConfigurationElement
    private(set) var nameConfiguration = NameConfiguration<Parent>(minLengthWarning: 3,
                                                                   minLengthError: 0,
                                                                   maxLengthWarning: 40,
                                                                   maxLengthError: 1000)
    @ConfigurationElement(key: "validate_protocols")
    private(set) var validateProtocols = true

    mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw Issue.unknownConfiguration(ruleID: Parent.identifier)
        }
        try nameConfiguration.apply(configuration: configuration)

        if let validateProtocols = configuration["validate_protocols"] as? Bool {
            self.validateProtocols = validateProtocols
        }
    }
}
