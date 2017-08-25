//
//  VerticalWhitespaceConfiguration.swift
//  SwiftLint
//
//  Created by Aaron McTavish on 01/05/17.
//  Copyright © 2017 Realm. All rights reserved.
//

public struct VerticalWhitespaceConfiguration: RuleConfiguration, Equatable {
    public let parameters: [ParameterDefinition]
    private var maxEmptyLinesParameter: Parameter<Int>
    private var severityParameter = SeverityConfiguration(.warning).severityParameter

    var severity: ViolationSeverity {
        return severityParameter.value
    }

    var maxEmptyLines: Int {
        return maxEmptyLinesParameter.value
    }

    public init(maxEmptyLines: Int) {
        maxEmptyLinesParameter = Parameter(key: "max_empty_lines",
                                           default: maxEmptyLines,
                                           description: "How serious")
        parameters = [maxEmptyLinesParameter, severityParameter]
    }

    public mutating func apply(configuration: [String: Any]) throws {
        try maxEmptyLinesParameter.parse(from: configuration)
        try severityParameter.parse(from: configuration)
    }

    public static func == (lhs: VerticalWhitespaceConfiguration,
                           rhs: VerticalWhitespaceConfiguration) -> Bool {
        return lhs.maxEmptyLines == rhs.maxEmptyLines &&
            lhs.severity == rhs.severity
    }
}
