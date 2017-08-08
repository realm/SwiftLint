//
//  DiscouragedInitConfiguration.swift
//  SwiftLint
//
//  Created by Ornithologist Coder on 8/1/17.
//  Copyright © 2017 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

private func toExplicitInitMethod(typeName: String) -> String {
    return "\(typeName).init"
}

public struct DiscouragedDirectInitConfiguration: RuleConfiguration, Equatable {
    public let parameters: [ParameterDefinition]
    private var typesParameter: ArrayParameter<String>
    private var severityParameter = SeverityConfiguration(.warning).severityParameter

    var severity: ViolationSeverity {
        return severityParameter.value
    }

    private(set) public var discouragedInits: Set<String>

    public init(types: [String] = ["Bundle", "UIDevice"]) {
        typesParameter = ArrayParameter(key: "types", default: types,
                                        description: "")
        parameters = [typesParameter, severityParameter]
        discouragedInits = Set(types + types.map(toExplicitInitMethod))
    }

    public mutating func apply(configuration: [String: Any]) throws {
        try typesParameter.parse(from: configuration)
        try severityParameter.parse(from: configuration)
        let types = typesParameter.value
        discouragedInits = Set(types + types.map(toExplicitInitMethod))
    }

    // MARK: - Equatable

    public static func == (lhs: DiscouragedDirectInitConfiguration,
                           rhs: DiscouragedDirectInitConfiguration) -> Bool {
        return lhs.discouragedInits == rhs.discouragedInits && lhs.severity == rhs.severity
    }
}
