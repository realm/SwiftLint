//
//  WeakViewControllerRule.swift
//  SwiftLint
//
//  Created by Romans Karpelcevs on 13/4/18.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct WeakViewControllerRule: ASTRule, OptInRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "weak_view_controller",
        name: "Weak View Controller",
        description: "View Controllers should be weak to avoid reference cycles.",
        kind: .lint,
        nonTriggeringExamples: [
            "class Foo {\n  weak var viewController: SomeVC?\n}\n",
            "class Foo {\n  weak var someViewController: SomeViewControllerProtocol?\n}\n",
            "class Foo {\n  weak var viewControllerScroll: ScrollViewController?\n}\n",
            // We only consider properties to be a vulnerable if they have "viewController" in their name
            "class Foo {\n  var scrollHandler: ScrollViewController?\n}\n",
            // Only trigger on instance variables, not local variables
            "func foo() {\n  var viewController: SomeViewController\n}\n",
            // Only trigger when variable has the suffix "-viewController" to avoid false positives
            "class Foo {\n  var viewControllerNotified: Bool?\n}\n",
            // There's no way to declare a property weak in a protocol
            "protocol P {\n var viewController: AnyObject? { get set }\n}\n",
            "class Foo {\n protocol P {\n var viewController: AnyObject? { get set }\n}\n}\n",
            "class Foo {\n var computedViewController: ComputedViewController {\n return bar() \n} \n}"
        ],
        triggeringExamples: [
            "class Foo {\n  ↓var viewController: SomeVC?\n}\n",
            "class Foo {\n  ↓var scrollViewController: ScrollViewController?\n}\n"
        ]
    )

    public func validate(file: File, kind: SwiftDeclarationKind,
                         dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        guard kind == .varInstance else {
            return []
        }

        // Check if name contains "viewcontroller"
        guard let name = dictionary.name,
            name.lowercased().hasSuffix("viewcontroller") else {
                return []
        }

        // Check if non-weak
        let isWeak = dictionary.enclosedSwiftAttributes.contains("source.decl.attribute.weak")
        guard !isWeak else { return [] }

        // if the declaration is inside a protocol
        if let offset = dictionary.offset,
            !protocolDeclarations(forByteOffset: offset, structure: file.structure).isEmpty {
            return []
        }

        // Check if non-computed
        let isComputed = dictionary.bodyLength ?? 0 > 0
        guard !isComputed else { return [] }

        // Violation found!
        let location: Location
        if let offset = dictionary.offset {
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

    private func protocolDeclarations(forByteOffset byteOffset: Int,
                                      structure: Structure) -> [[String: SourceKitRepresentable]] {
        var results = [[String: SourceKitRepresentable]]()

        func parse(dictionary: [String: SourceKitRepresentable]) {

            // Only accepts protocols declarations which contains a body and contains the
            // searched byteOffset
            if let kindString = (dictionary.kind),
                SwiftDeclarationKind(rawValue: kindString) == .protocol,
                let offset = dictionary.bodyOffset,
                let length = dictionary.bodyLength {
                let byteRange = NSRange(location: offset, length: length)

                if NSLocationInRange(byteOffset, byteRange) {
                    results.append(dictionary)
                }
            }
            dictionary.substructure.forEach(parse)
        }
        parse(dictionary: structure.dictionary)
        return results
    }
}
