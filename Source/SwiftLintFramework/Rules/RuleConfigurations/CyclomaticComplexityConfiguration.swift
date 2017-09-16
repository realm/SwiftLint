//
//  CyclomaticComplexityConfiguration.swift
//  SwiftLint
//
//  Created by Mike Welles on 2/9/17.
//  Copyright © 2017 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct CyclomaticComplexityConfiguration: RuleConfiguration, Equatable {
    private(set) var warningLengthParameter: Parameter<Int>
    private(set) var errorLengthParameter: OptionalParameter<Int>
    private(set) var ignoresCaseStatementsParameter: Parameter<Bool>

    public init(warning: Int, error: Int?, ignoresCaseStatements: Bool = false) {
        let levelsConfiguration = SeverityLevelsConfiguration(warning: warning, error: error)
        warningLengthParameter = levelsConfiguration.warningParameter
        errorLengthParameter = levelsConfiguration.errorParameter
        ignoresCaseStatementsParameter = Parameter(key: "ignores_case_statements",
                                                   default: ignoresCaseStatements,
                                                   description: "")
        updateComplexityStatements()
    }

    public mutating func apply(configuration: [String: Any]) throws {
        try warningLengthParameter.parse(from: configuration)
        try errorLengthParameter.parse(from: configuration)
        try ignoresCaseStatementsParameter.parse(from: configuration)
        updateComplexityStatements()
    }

    private static let defaultComplexityStatements: Set<StatementKind> = [
        .forEach,
        .if,
        .guard,
        .for,
        .repeatWhile,
        .while,
        .case
    ]

    private(set) public var complexityStatements = CyclomaticComplexityConfiguration.defaultComplexityStatements

    public var ignoresCaseStatements: Bool {
        return ignoresCaseStatementsParameter.value
    }

    var params: [RuleParameter<Int>] {
        return SeverityLevelsConfiguration(warning: warningLengthParameter.value,
                                           error: errorLengthParameter.value).params
    }

    private mutating func updateComplexityStatements() {
        if ignoresCaseStatements {
            complexityStatements.remove(.case)
        } else {
            complexityStatements.insert(.case)
        }
    }

    public static func == (lhs: CyclomaticComplexityConfiguration,
                           rhs: CyclomaticComplexityConfiguration) -> Bool {
        return lhs.params == rhs.params &&
            lhs.ignoresCaseStatements == rhs.ignoresCaseStatements
    }
}
