//
//  NumberSeparatorConfiguration.swift
//  SwiftLint
//
//  Created by Marcelo Fabri on 01/02/17.
//  Copyright © 2017 Realm. All rights reserved.
//

public struct NumberSeparatorConfiguration: RuleConfiguration, Equatable {
    private(set) var severityConfiguration = SeverityConfiguration(.warning)
    private(set) var minimumLength: Int
    private(set) var minimumFractionLength: Int?

    public var consoleDescription: String {
        let minimumFractionLengthDescription: String
        if let minimumFractionLength = minimumFractionLength {
            minimumFractionLengthDescription = ", minimum_fraction_length: \(minimumFractionLength)"
        } else {
            minimumFractionLengthDescription = ""
        }
        return severityConfiguration.consoleDescription
            + ", minimum_length: \(minimumLength)"
            + minimumFractionLengthDescription
    }

    public init(minimumLength: Int, minimumFractionLength: Int?) {
        self.minimumLength = minimumLength
        self.minimumFractionLength = minimumFractionLength
    }

    public mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw ConfigurationError.unknownConfiguration
        }

        if let minimumLength = configuration["minimum_length"] as? Int {
            self.minimumLength = minimumLength
        }

        if let minimumFractionLength = configuration["minimum_fraction_length"] as? Int {
            self.minimumFractionLength = minimumFractionLength
        }

        if let severityString = configuration["severity"] as? String {
            try severityConfiguration.apply(configuration: severityString)
        }
    }

    public static func == (lhs: NumberSeparatorConfiguration,
                           rhs: NumberSeparatorConfiguration) -> Bool {
        return lhs.minimumLength == rhs.minimumLength &&
            lhs.minimumFractionLength == rhs.minimumFractionLength &&
            lhs.severityConfiguration == rhs.severityConfiguration
    }
}
