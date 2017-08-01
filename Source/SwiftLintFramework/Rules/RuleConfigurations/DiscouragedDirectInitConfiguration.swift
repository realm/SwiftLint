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
    public var severityConfiguration = SeverityConfiguration(.warning)

    public var consoleDescription: String {
        return severityConfiguration.consoleDescription + ", types: \(discouragedInits)"
    }

    public var severity: ViolationSeverity {
        return severityConfiguration.severity
    }

    private(set) public var discouragedInits: Set<String>

    private let defaultDiscouragedInits = [
        "Bundle",
        "UIDevice"
    ]

    init() {
        discouragedInits = Set(defaultDiscouragedInits + defaultDiscouragedInits.map(toExplicitInitMethod))
    }

    // MARK: - RuleConfiguration

    public mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw ConfigurationError.unknownConfiguration
        }

        if let severityString = configuration["severity"] as? String {
            try severityConfiguration.apply(configuration: severityString)
        }

        if let types = [String].array(of: configuration["types"]) {
            discouragedInits = Set(types + types.map(toExplicitInitMethod))
        }
    }

    // MARK: - Equatable

    public static func == (lhs: DiscouragedDirectInitConfiguration, rhs: DiscouragedDirectInitConfiguration) -> Bool {
        return lhs.discouragedInits == rhs.discouragedInits && lhs.severityConfiguration == rhs.severityConfiguration
    }
}
