//
//  SubClassRule.swift
//  SwiftLint
//
//  Created by Mikhail Yakushin on 03/02/18.
//  Copyright © 2018 Realm. All rights reserved.
//

import SourceKittenFramework

public struct SubClassRule: ASTRule, ConfigurationProviderRule, OptInRule {
    public var configuration = SeverityLevelsConfiguration(warning: 0, error: 0)

    public init() {}

    public static let description = RuleDescription(
        identifier: "subclass",
        name: "Subclass",
        description: "Subclassing is prohibited.",
        kind: .style
    )

    public func validate(file: File, kind: SwiftDeclarationKind,
                         dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        guard SwiftDeclarationKind.functionKinds.contains(kind),
              let offset = dictionary.offset,
              case let contentsNSString = file.contents.bridge()
            else {
            return []
        }

        if contentsNSString.contains("super.") || contentsNSString.contains("super()") {
            return [
                StyleViolation(
                    ruleDescription: type(of: self).description,
                    severity: configuration.params.first!.severity,
                    location: Location(file: file, byteOffset: offset),
                    reason: "Subclassing is prohibited."
                )
            ]
        } else {
            return []
        }

    }

}
