//
//  ClassDelegateProtocolRule.swift
//  SwiftLint
//
//  Created by Marcelo Fabri on 12/23/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct ClassDelegateProtocolRule: ASTRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "class_delegate_protocol",
        name: "Class Delegate Protocol",
        description: "Delegate protocols should be class-only so they can be weakly referenced.",
        kind: .lint,
        nonTriggeringExamples: [
            "protocol FooDelegate: class {}\n",
            "protocol FooDelegate: class, BarDelegate {}\n",
            "protocol Foo {}\n",
            "class FooDelegate {}\n",
            "@objc protocol FooDelegate {}\n",
            "@objc(MyFooDelegate)\n protocol FooDelegate {}\n",
            "protocol FooDelegate: BarDelegate {}\n",
            "protocol FooDelegate: AnyObject {}\n",
            "protocol FooDelegate: NSObjectProtocol {}\n"
        ],
        triggeringExamples: [
            "↓protocol FooDelegate {}\n",
            "↓protocol FooDelegate: Bar {}\n"
        ]
    )

    private let referenceTypeProtocols: Set = ["AnyObject", "NSObjectProtocol", "class"]

    public func validate(file: File, kind: SwiftDeclarationKind,
                         dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        guard kind == .protocol else {
            return []
        }

        // Check if name contains "Delegate"
        guard let name = dictionary.name, isDelegateProtocol(name) else {
            return []
        }

        // Check if @objc
        let objcAttributes: Set<String> = ["source.decl.attribute.objc",
                                           "source.decl.attribute.objc.name"]
        let isObjc = !objcAttributes.isDisjoint(with: dictionary.enclosedSwiftAttributes)
        guard !isObjc else {
            return []
        }

        // Check if inherits from another Delegate protocol
        guard dictionary.inheritedTypes.filter(isDelegateProtocol).isEmpty else {
            return []
        }

        // Check if inherits from a known reference type protocol
        guard dictionary.inheritedTypes.filter(isReferenceTypeProtocol).isEmpty else {
            return []
        }

        // Check if : class
        guard let offset = dictionary.offset,
            let nameOffset = dictionary.nameOffset,
            let nameLength = dictionary.nameLength,
            let bodyOffset = dictionary.bodyOffset,
            case let contents = file.contents.bridge(),
            case let start = nameOffset + nameLength,
            let range = contents.byteRangeToNSRange(start: start, length: bodyOffset - start),
            !isClassProtocol(file: file, range: range) else {
            return []
        }

        return [
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severity,
                           location: Location(file: file, byteOffset: offset))
        ]
    }

    private func isClassProtocol(file: File, range: NSRange) -> Bool {
        return !file.match(pattern: "\\bclass\\b", with: [.keyword], range: range).isEmpty
    }

    private func isDelegateProtocol(_ name: String) -> Bool {
        return name.hasSuffix("Delegate")
    }

    private func isReferenceTypeProtocol(_ name: String) -> Bool {
        return referenceTypeProtocols.contains(name)
    }

}
