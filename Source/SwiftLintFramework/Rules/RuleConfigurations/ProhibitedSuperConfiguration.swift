//
//  ProhibitedSuperConfiguration.swift
//  SwiftLint
//
//  Created by Aaron McTavish on 12/12/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation

public struct ProhibitedSuperConfiguration: RuleConfiguration, Equatable {
    var severityConfiguration = SeverityConfiguration(.warning)
    var excluded = [String]()
    var included = ["*"]

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

    init() {}

    public var consoleDescription: String {
        return severityConfiguration.consoleDescription +
            ", excluded: [\(excluded)]" +
            ", included: [\(included)]"
    }

    public mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw ConfigurationError.unknownConfiguration
        }

        if let severityString = configuration["severity"] as? String {
            try severityConfiguration.apply(configuration: severityString)
        }

        if let excluded = [String].array(of: configuration["excluded"]) {
            self.excluded = excluded
        }

        if let included = [String].array(of: configuration["included"]) {
            self.included = included
        }

        resolvedMethodNames = calculateResolvedMethodNames()
    }

    public var severity: ViolationSeverity {
        return severityConfiguration.severity
    }

    private func calculateResolvedMethodNames() -> [String] {
        var names = [String]()
        if included.contains("*") && !excluded.contains("*") {
            names += resolvedMethodNames
        }
        names += included.filter { $0 != "*" }
        names = names.filter { !excluded.contains($0) }
        return names
    }
}

public func == (lhs: ProhibitedSuperConfiguration,
                rhs: ProhibitedSuperConfiguration) -> Bool {
    return lhs.excluded == rhs.excluded &&
        lhs.included == rhs.included &&
        lhs.severityConfiguration == rhs.severityConfiguration
}
