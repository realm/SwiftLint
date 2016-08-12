//
//  WeakDelegate.swift
//  SwiftLint
//
//  Created by Olivier Halligon on 11/08/2016.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct WeakDelegateRule: ASTRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.Warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "weak_delegate",
        name: "Weak Delegate",
        description: "Delegates should be weak to avoid reference cycles.",
        nonTriggeringExamples: [
            "class Foo {\n  weak var delegate: SomeProtocol?\n}\n",
            "class Foo {\n  weak var someDelegate: SomeDelegateProtocol?\n}\n",
            "class Foo {\n  weak var delegateScroll: ScrollDelegate?\n}\n",
            // We only consider properties to be a delegate if it has "delegate" in its name
            "class Foo {\n  var scrollHandler: ScrollDelegate?\n}\n",
            // Only trigger on instance variables, not local variables
            "func foo() {\n  var delegate: SomeDelegate\n}\n"
        ],
        triggeringExamples: [
            "class Foo {\n  var delegate: SomeProtocol?\n}\n",
            "class Foo {\n  var scrollDelegate: ScrollDelegate?\n}\n",
            "class Foo {\n  var delegateScroll: ScrollDelegate?\n}\n",
        ]
    )

    public func validateFile(file: File,
                             kind: SwiftDeclarationKind,
                             dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        guard kind == .VarInstance else {
            return []
        }

        // Check if name contains "delegate"
        guard let name = (dictionary["key.name"] as? String) where
            name.lowercaseString.containsString("delegate") else {
                return []
        }

        // Check if non-weak
        let attributes = (dictionary["key.attributes"] as? [SourceKitRepresentable])?
            .flatMap({ ($0 as? [String: SourceKitRepresentable]) as? [String: String] })
            .flatMap({ $0["key.attribute"] }) ?? []
        let isWeak = attributes.contains("source.decl.attribute.weak")
        guard !isWeak else { return [] }

        // Violation found!
        let location: Location
        if let offset = (dictionary["key.offset"] as? Int64).flatMap({ Int($0) }) {
            location = Location(file: file, byteOffset: offset)
        } else {
            location = Location(file: file.path)
        }

        return [
            StyleViolation(ruleDescription: self.dynamicType.description,
                severity: configuration.severity,
                location: location
            )
        ]
    }
}
