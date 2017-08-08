//
//  NumberSeparatorConfiguration.swift
//  SwiftLint
//
//  Created by Marcelo Fabri on 01/02/17.
//  Copyright © 2017 Realm. All rights reserved.
//

public struct NumberSeparatorConfiguration: RuleConfiguration, Equatable {
    public let parameters: [ParameterDefinition]
    private var minimumLengthParameter: Parameter<Int>
    private var minimumFractionLengthParameter: OptionalParameter<Int>
    private var severityParameter = SeverityConfiguration(.warning).severityParameter

    var severity: ViolationSeverity {
        return severityParameter.value
    }

    var minimumLength: Int {
        return minimumLengthParameter.value
    }

    var minimumFractionLength: Int? {
        return minimumFractionLengthParameter.value
    }

    public init(minimumLength: Int, minimumFractionLength: Int?) {
        minimumLengthParameter = Parameter(key: "minimum_length",
                                           default: minimumLength,
                                           description: "How serious")
        minimumFractionLengthParameter = OptionalParameter(key: "minimum_fraction_length",
                                                           default: minimumFractionLength,
                                                           description: "How serious")

        parameters = [minimumLengthParameter, minimumFractionLengthParameter, severityParameter]
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
