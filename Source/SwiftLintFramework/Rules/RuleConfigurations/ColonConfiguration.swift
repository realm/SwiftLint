//
//  ColonConfiguration.swift
//  SwiftLint
//
//  Created by Marcelo Fabri on 12/18/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation

public struct ColonConfiguration: RuleConfiguration, Equatable {
    private(set) var severityParameter = SeverityConfiguration(.warning).severityParameter
    private(set) var flexibleRightSpacingParameter: Parameter<Bool>
    private(set) var applyToDictionariesParameter: Parameter<Bool>

    public var severity: ViolationSeverity {
        return severityParameter.value
    }

    public var flexibleRightSpacing: Bool {
        return flexibleRightSpacingParameter.value
    }

    public var applyToDictionaries: Bool {
        return applyToDictionariesParameter.value
    }

    public init(flexibleRightSpacing: Bool = false, applyToDictionaries: Bool = true) {
        flexibleRightSpacingParameter = Parameter(key: "flexible_right_spacing",
                                                  default: flexibleRightSpacing,
                                                  description: "How serious")
        applyToDictionariesParameter = Parameter(key: "apply_to_dictionaries",
                                                 default: applyToDictionaries,
                                                 description: "How serious")
    }

    public mutating func apply(configuration: [String: Any]) throws {
        try severityParameter.parse(from: configuration)
        try flexibleRightSpacingParameter.parse(from: configuration)
        try applyToDictionariesParameter.parse(from: configuration)
    }

    public static func == (lhs: ColonConfiguration,
                           rhs: ColonConfiguration) -> Bool {
        return lhs.severity == rhs.severity &&
            lhs.flexibleRightSpacing == rhs.flexibleRightSpacing &&
            lhs.applyToDictionaries == rhs.applyToDictionaries
    }
}
