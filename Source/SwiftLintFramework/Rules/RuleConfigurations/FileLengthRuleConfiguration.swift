//
//  FileLengthRuleConfiguration.swift
//  SwiftLint
//
//  Created by Samuel Susla on 11/07/17.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation

public struct FileLengthRuleConfiguration: RuleConfiguration, Equatable {
    public let parameters: [ParameterDefinition]
    private(set) var warningLengthParameter: Parameter<Int>
    private var errorLengthParameter: OptionalParameter<Int>
    private var ignoreCommentOnlyLinesParameter: Parameter<Bool>

    var ignoreCommentOnlyLines: Bool {
        return ignoreCommentOnlyLinesParameter.value
    }

    public init(warning: Int, error: Int?, ignoreCommentOnlyLines: Bool = false) {
        let levelsConfiguration = SeverityLevelsConfiguration(warning: warning, error: error)
        warningLengthParameter = levelsConfiguration.warningParameter
        errorLengthParameter = levelsConfiguration.errorParameter
        ignoreCommentOnlyLinesParameter = Parameter(key: "ignore_comment_only_lines",
                                                    default: ignoreCommentOnlyLines,
                                                    description: "")

        parameters = [warningLengthParameter, errorLengthParameter, ignoreCommentOnlyLinesParameter]
    }

    public mutating func apply(configuration: [String: Any]) throws {
        try warningLengthParameter.parse(from: configuration)
        try errorLengthParameter.parse(from: configuration)
        try ignoreCommentOnlyLinesParameter.parse(from: configuration)
    }

    var params: [RuleParameter<Int>] {
        return SeverityLevelsConfiguration(warning: warningLengthParameter.value,
                                           error: errorLengthParameter.value).params
    }

    public static func == (lhs: FileLengthRuleConfiguration,
                           rhs: FileLengthRuleConfiguration) -> Bool {
        return lhs.ignoreCommentOnlyLines == rhs.ignoreCommentOnlyLines &&
            lhs.params == rhs.params
    }
}
