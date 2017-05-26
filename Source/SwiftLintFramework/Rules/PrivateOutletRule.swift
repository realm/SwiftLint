//
//  PrivateOutletRule.swift
//  SwiftLint
//
//  Created by Olivier Halligon on 12/8/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct PrivateOutletRule: ASTRule, OptInRule, ConfigurationProviderRule {
    public var configuration = PrivateOutletRuleConfiguration(allowPrivateSet: false)

    public init() {}

    public static let description = RuleDescription(
        identifier: "private_outlet",
        name: "Private Outlets",
        description: "IBOutlets should be private to avoid leaking UIKit to higher layers.",
        kind: .lint,
        nonTriggeringExamples: [
            "class Foo {\n  @IBOutlet private var label: UILabel?\n}\n",
            "class Foo {\n  @IBOutlet private var label: UILabel!\n}\n",
            "class Foo {\n  var notAnOutlet: UILabel\n}\n",
            "class Foo {\n  @IBOutlet weak private var label: UILabel?\n}\n",
            "class Foo {\n  @IBOutlet private weak var label: UILabel?\n}\n"
        ],
        triggeringExamples: [
            "class Foo {\n  @IBOutlet ↓var label: UILabel?\n}\n",
            "class Foo {\n  @IBOutlet ↓var label: UILabel!\n}\n"
        ]
    )

    public func validate(file: File, kind: SwiftDeclarationKind,
                         dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        guard kind == .varInstance else {
            return []
        }

        // Check if IBOutlet
        let isOutlet = dictionary.enclosedSwiftAttributes.contains("source.decl.attribute.iboutlet")
        guard isOutlet else { return [] }

        // Check if private
        let isPrivate = isPrivateLevel(identifier: dictionary.accessibility)
        let isPrivateSet = isPrivateLevel(identifier: dictionary.setterAccessibility)

        if isPrivate || (configuration.allowPrivateSet && isPrivateSet) {
            return []
        }

        // Violation found!
        let location: Location
        if let offset = dictionary.offset {
            location = Location(file: file, byteOffset: offset)
        } else {
            location = Location(file: file.path)
        }

        return [
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severityConfiguration.severity,
                           location: location)
        ]
    }

    private func isPrivateLevel(identifier: String?) -> Bool {
        return identifier.flatMap(AccessControlLevel.init(identifier:))?.isPrivate ?? false
    }
}
