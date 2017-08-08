//
//  AttributesConfiguration.swift
//  SwiftLint
//
//  Created by Marcelo Fabri on 11/26/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation

public struct AttributesConfiguration: RuleConfiguration, Equatable {
    public let parameters: [ParameterDefinition]
    private var alwaysOnSameLineParameter: ArrayParameter<String>
    private var alwaysOnNewLineParameter: ArrayParameter<String>
    private var severityParameter = SeverityConfiguration(.warning).severityParameter

    var severity: ViolationSeverity {
        return severityParameter.value
    }

    private(set) var alwaysOnSameLine = Set<String>()
    private(set) var alwaysOnNewLine = Set<String>()

    public init(alwaysOnSameLine: [String] = ["@IBAction", "@NSManaged"],
                alwaysInNewLine: [String] = []) {
        alwaysOnSameLineParameter = ArrayParameter(key: "always_on_same_line", default: alwaysOnSameLine,
                                                   description: "")
        alwaysOnNewLineParameter = ArrayParameter(key: "always_on_line_above", default: alwaysInNewLine,
                                                  description: "")
        parameters = [alwaysOnSameLineParameter, alwaysOnNewLineParameter, severityParameter]

        self.alwaysOnSameLine = Set(alwaysOnSameLine)
        self.alwaysOnNewLine = Set(alwaysOnNewLine)
    }

    public mutating func apply(configuration: [String: Any]) throws {
        try alwaysOnSameLineParameter.parse(from: configuration)
        try alwaysOnNewLineParameter.parse(from: configuration)
        try severityParameter.parse(from: configuration)

        alwaysOnSameLine = Set(alwaysOnSameLineParameter.value)
        alwaysOnNewLine = Set(alwaysOnNewLineParameter.value)
    }

    public static func == (lhs: AttributesConfiguration,
                           rhs: AttributesConfiguration) -> Bool {
        return lhs.severity == rhs.severity &&
            lhs.alwaysOnSameLine == rhs.alwaysOnSameLine &&
            rhs.alwaysOnNewLine == rhs.alwaysOnNewLine
    }

}
