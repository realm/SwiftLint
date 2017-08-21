//
//  SuperfluousDisableCommandRule.swift
//  SwiftLint
//
//  Created by Marcelo Fabri on 08/18/17.
//  Copyright © 2017 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct SuperfluousDisableCommandRule: ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.error)

    public init() {}

    public static let description = RuleDescription(
        identifier: "superfluous_disable_command",
        name: "Superfluous Disable Command",
        description: "SwiftLint 'disable' commands are superfluous when the disabled rule would not have " +
                     "triggered a violation in the disabled region.",
        kind: .lint
    )

    public func validate(file: File) -> [StyleViolation] {
        // This rule is implemented in Linter.swift
        return []
    }

    public func reason(for rule: Rule.Type) -> String {
        return "SwiftLint rule '\(rule.description.identifier)' did not trigger a violation " +
               "in the disabled region. Please remove the disable command."
    }
}
