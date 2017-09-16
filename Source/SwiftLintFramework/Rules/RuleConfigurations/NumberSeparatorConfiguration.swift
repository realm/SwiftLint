//
//  NumberSeparatorConfiguration.swift
//  SwiftLint
//
//  Created by Marcelo Fabri on 01/02/17.
//  Copyright © 2017 Realm. All rights reserved.
//

public struct NumberSeparatorConfiguration: RuleConfiguration, Equatable {
    private(set) var minimumLengthParameter: Parameter<Int>
    private(set) var minimumFractionLengthParameter: OptionalParameter<Int>
    private(set) var severityParameter = SeverityConfiguration(.warning).severityParameter

    public var severity: ViolationSeverity {
        return severityParameter.value
    }

    public var minimumLength: Int {
        return minimumLengthParameter.value
    }

    public var minimumFractionLength: Int? {
        return minimumFractionLengthParameter.value
    }

    public init(minimumLength: Int, minimumFractionLength: Int?) {
        minimumLengthParameter = Parameter(key: "minimum_length",
                                           default: minimumLength,
                                           description: "How serious")
        minimumFractionLengthParameter = OptionalParameter(key: "minimum_fraction_length",
                                                           default: minimumFractionLength,
                                                           description: "How serious")
    }

    public mutating func apply(configuration: [String: Any]) throws {
        try minimumLengthParameter.parse(from: configuration)
        try minimumFractionLengthParameter.parse(from: configuration)
        try severityParameter.parse(from: configuration)
    }

    public static func == (lhs: NumberSeparatorConfiguration,
                           rhs: NumberSeparatorConfiguration) -> Bool {
        return lhs.minimumLength == rhs.minimumLength &&
            lhs.minimumFractionLength == rhs.minimumFractionLength &&
            lhs.severity == rhs.severity
    }
}
