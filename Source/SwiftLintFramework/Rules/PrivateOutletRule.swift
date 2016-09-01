//
//  PrivateOutletRule.swift
//  SwiftLint
//
//  Created by Olivier Halligon on 12/08/2016.
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
        nonTriggeringExamples: [
            "class Foo {\n  @IBOutlet private var label: UILabel?\n}\n",
            "class Foo {\n  @IBOutlet private var label: UILabel!\n}\n",
            "class Foo {\n  var notAnOutlet: UILabel\n}\n",
            "class Foo {\n  @IBOutlet weak private var label: UILabel?\n}\n",
            "class Foo {\n  @IBOutlet private weak var label: UILabel?\n}\n",
        ],
        triggeringExamples: [
            "class Foo {\n  @IBOutlet var label: UILabel?\n}\n",
            "class Foo {\n  @IBOutlet var label: UILabel!\n}\n",
        ]
    )

    public func validateFile(file: File,
                             kind: SwiftDeclarationKind,
                             dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        guard kind == .VarInstance else {
            return []
        }

        // Check if IBOutlet
        let attributes = (dictionary["key.attributes"] as? [SourceKitRepresentable])?
            .flatMap({ ($0 as? [String: SourceKitRepresentable]) as? [String: String] })
            .flatMap({ $0["key.attribute"] }) ?? []
        let isOutlet = attributes.contains("source.decl.attribute.iboutlet")
        guard isOutlet else { return [] }

        // Check if private
        let accessibility = (dictionary["key.accessibility"] as? String) ?? ""
        let setterAccessiblity = (dictionary["key.setter_accessibility"] as? String) ?? ""
        let isPrivate = accessibility == "source.lang.swift.accessibility.private"
        let isPrivateSet = setterAccessiblity == "source.lang.swift.accessibility.private"

        if isPrivate || (self.configuration.allowPrivateSet && isPrivateSet) {
            return []
        }

        // Violation found!
        let location: Location
        if let offset = (dictionary["key.offset"] as? Int64).flatMap({ Int($0) }) {
            location = Location(file: file, byteOffset: offset)
        } else {
            location = Location(file: file.path)
        }

        return [
            StyleViolation(ruleDescription: self.dynamicType.description,
                severity: configuration.severityConfiguration.severity,
                location: location
            )
        ]
    }
}
