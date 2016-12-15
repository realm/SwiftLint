//
//  WeakDelegate.swift
//  SwiftLint
//
//  Created by Olivier Halligon on 11/8/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct WeakDelegateRule: ASTRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

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
            "func foo() {\n  var delegate: SomeDelegate\n}\n",
            // Only trigger when variable has the suffix "-delegate" to avoid false positives
            "class Foo {\n  var delegateNotified: Bool?\n}\n",
            // There's no way to declare a property weak in a protocol
            "protocol P {\n var delegate: AnyObject? { get set }\n}\n",
            "class Foo {\n protocol P {\n var delegate: AnyObject? { get set }\n}\n}\n"
        ],
        triggeringExamples: [
            "class Foo {\n  var delegate: SomeProtocol?\n}\n",
            "class Foo {\n  var scrollDelegate: ScrollDelegate?\n}\n"
        ]
    )

    public func validateFile(_ file: File,
                             kind: SwiftDeclarationKind,
                             dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        guard kind == .varInstance else {
            return []
        }

        // Check if name contains "delegate"
        guard let name = (dictionary["key.name"] as? String),
            name.lowercased().hasSuffix("delegate") else {
                return []
        }

        // Check if non-weak
        let isWeak = dictionary.enclosedSwiftAttributes.contains("source.decl.attribute.weak")
        guard !isWeak else { return [] }

        // if the declaration is inside a protocol
        if let offset = (dictionary["key.offset"] as? Int64).flatMap({ Int($0) }),
            !protocolDeclarationsFor(offset, structure: file.structure).isEmpty {
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
            StyleViolation(
                ruleDescription: type(of: self).description,
                severity: configuration.severity,
                location: location
            )
        ]
    }

    private func protocolDeclarationsFor(_ byteOffset: Int, structure: Structure) ->
        [[String: SourceKitRepresentable]] {
            var results = [[String: SourceKitRepresentable]]()

            func parse(dictionary: [String: SourceKitRepresentable]) {

                // Only accepts protocols declarations which contains a body and contains the
                // searched byteOffset
                if let kindString = (dictionary["key.kind"] as? String),
                    SwiftDeclarationKind(rawValue: kindString) == .protocol,
                    let offset = (dictionary["key.bodyoffset"] as? Int64).flatMap({ Int($0) }),
                    let length = (dictionary["key.bodylength"] as? Int64).flatMap({ Int($0) }) {
                    let byteRange = NSRange(location: offset, length: length)

                    if NSLocationInRange(byteOffset, byteRange) {
                        results.append(dictionary)
                    }
                }

                if let subStructure = dictionary["key.substructure"] as? [SourceKitRepresentable] {
                    for case let dictionary as [String: SourceKitRepresentable] in subStructure {
                        parse(dictionary: dictionary)
                    }
                }
            }
            parse(dictionary: structure.dictionary)
            return results
    }
}
