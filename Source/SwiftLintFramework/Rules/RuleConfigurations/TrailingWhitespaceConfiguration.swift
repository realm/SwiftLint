//
//  TrailingWhitespaceConfiguration.swift
//  SwiftLint
//
//  Created by Reimar Twelker on 12/4/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation

public struct TrailingWhitespaceConfiguration: RuleConfiguration, Equatable {
    public let parameters: [ParameterDefinition]
    private var ignoresEmptyLinesParameter: Parameter<Bool>
    private var ignoresCommentsParameter: Parameter<Bool>
    private var severityParameter = SeverityConfiguration(.warning).severityParameter

    var ignoresEmptyLines: Bool {
        return ignoresEmptyLinesParameter.value
    }

    var ignoresComments: Bool {
        return ignoresCommentsParameter.value
    }

    var severity: ViolationSeverity {
        return severityParameter.value
    }

    public init(ignoresEmptyLines: Bool, ignoresComments: Bool) {
        ignoresEmptyLinesParameter = Parameter(key: "ignores_empty_lines", default: ignoresEmptyLines,
                                               description: "")
        ignoresCommentsParameter = Parameter(key: "ignores_comments", default: ignoresComments,
                                             description: "")
        parameters = [ignoresEmptyLinesParameter, ignoresCommentsParameter, severityParameter]
    }

    public mutating func apply(configuration: [String: Any]) throws {
        try ignoresEmptyLinesParameter.parse(from: configuration)
        try ignoresCommentsParameter.parse(from: configuration)
        try severityParameter.parse(from: configuration)
    }

    static public func == (lhs: TrailingWhitespaceConfiguration,
                           rhs: TrailingWhitespaceConfiguration) -> Bool {
        return lhs.ignoresEmptyLines == rhs.ignoresEmptyLines &&
            lhs.ignoresComments == rhs.ignoresComments &&
            lhs.severityParameter == rhs.severityParameter
    }
}
