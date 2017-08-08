//
//  LineLengthConfiguration.swift
//  SwiftLint
//
//  Created by Javier Hernández on 21/12/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation

public struct LineLengthRuleOptions: OptionSet {
    public let rawValue: Int

    public init(rawValue: Int = 0) {
        self.rawValue = rawValue
    }

    public static let ignoreURLs = LineLengthRuleOptions(rawValue: 1 << 0)
    public static let ignoreFunctionDeclarations = LineLengthRuleOptions(rawValue: 1 << 1)
    public static let ignoreComments = LineLengthRuleOptions(rawValue: 1 << 2)

    public static let all: LineLengthRuleOptions = [.ignoreURLs, .ignoreFunctionDeclarations, .ignoreComments]
}

public struct LineLengthConfiguration: RuleConfiguration, Equatable {
    public let parameters: [ParameterDefinition]
    private(set) var warningLengthParameter: Parameter<Int>
    private(set) var errorLengthParameter: OptionalParameter<Int>
    private var ignoresURLsParameter: Parameter<Bool>
    private var ignoresFunctionDeclarationsParameter: Parameter<Bool>
    private var ignoresCommentsParameter: Parameter<Bool>

    var ignoresURLs: Bool {
        return ignoresURLsParameter.value
    }

    var ignoresFunctionDeclarations: Bool {
        return ignoresFunctionDeclarationsParameter.value
    }

    var ignoresComments: Bool {
        return ignoresCommentsParameter.value
    }

    public init(warning: Int, error: Int?, options: LineLengthRuleOptions = []) {
        let levelsConfiguration = SeverityLevelsConfiguration(warning: warning, error: error)
        warningLengthParameter = levelsConfiguration.warningParameter
        errorLengthParameter = levelsConfiguration.errorParameter
        ignoresURLsParameter = Parameter(key: "ignores_urls",
                                         default: options.contains(.ignoreURLs),
                                         description: "")
        ignoresFunctionDeclarationsParameter = Parameter(key: "ignores_function_declarations",
                                                         default: options.contains(.ignoreFunctionDeclarations),
                                                         description: "")

        ignoresCommentsParameter = Parameter(key: "ignores_comments",
                                             default: options.contains(.ignoreComments),
                                             description: "")

        parameters = [warningLengthParameter, errorLengthParameter, ignoresURLsParameter,
                      ignoresFunctionDeclarationsParameter, ignoresCommentsParameter]
    }

    public mutating func apply(configuration: [String: Any]) throws {
        try warningLengthParameter.parse(from: configuration)
        try errorLengthParameter.parse(from: configuration)
        try ignoresURLsParameter.parse(from: configuration)
        try ignoresFunctionDeclarationsParameter.parse(from: configuration)
        try ignoresCommentsParameter.parse(from: configuration)
    }

    var params: [RuleParameter<Int>] {
        return SeverityLevelsConfiguration(warning: warningLengthParameter.value,
                                           error: errorLengthParameter.value).params
    }

    public static func == (lhs: LineLengthConfiguration, rhs: LineLengthConfiguration) -> Bool {
        return lhs.params == rhs.params &&
            lhs.ignoresURLs == rhs.ignoresURLs &&
            lhs.ignoresComments == rhs.ignoresComments &&
            lhs.ignoresFunctionDeclarations == rhs.ignoresFunctionDeclarations
    }
}
