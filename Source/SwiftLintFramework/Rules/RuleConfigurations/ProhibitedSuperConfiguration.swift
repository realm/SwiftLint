//
//  ProhibitedSuperConfiguration.swift
//  SwiftLint
//
//  Created by Aaron McTavish on 12/12/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation

public struct ProhibitedSuperConfiguration: RuleConfiguration, Equatable {
    public let parameters: [ParameterDefinition]
    private var severityParameter = SeverityConfiguration(.warning).severityParameter
    private var excludedParameter: ArrayParameter<String>
    private var includedParameter: ArrayParameter<String>

    var severity: ViolationSeverity {
        return severityParameter.value
    }

    var excluded: [String] {
        return excludedParameter.value
    }

    var included: [String] {
        return includedParameter.value
    }

    public init(excluded: [String] = [], included: [String] = ["*"]) {
        excludedParameter = ArrayParameter(key: "excluded",
                                           default: excluded,
                                           description: "How serious")
        includedParameter = ArrayParameter(key: "apply_to_dictionaries",
                                           default: included,
                                           description: "How serious")
        parameters = [excludedParameter, includedParameter, severityParameter]
    }

    public mutating func apply(configuration: [String: Any]) throws {
        try severityParameter.parse(from: configuration)
        try excludedParameter.parse(from: configuration)
        try includedParameter.parse(from: configuration)

        resolvedMethodNames = calculateResolvedMethodNames()
    }

    private(set) var resolvedMethodNames = [
        // NSFileProviderExtension
        "providePlaceholder(at:completionHandler:)",
        // NSTextInput
        "doCommand(by:)",
        // NSView
        "updateLayer()",
        // UIViewController
        "loadView()"
    ]

    private func calculateResolvedMethodNames() -> [String] {
        var names = [String]()
        if included.contains("*") && !excluded.contains("*") {
            names += resolvedMethodNames
        }
        names += included.filter { $0 != "*" }
        names = names.filter { !excluded.contains($0) }
        return names
    }

    public static func == (lhs: ProhibitedSuperConfiguration,
                           rhs: ProhibitedSuperConfiguration) -> Bool {
        return lhs.excluded == rhs.excluded &&
            lhs.included == rhs.included &&
            lhs.severity == rhs.severity
    }

}
