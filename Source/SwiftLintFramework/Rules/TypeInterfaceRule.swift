//
//  TypeInterfaceRule.swift
//  SwiftLint
//
//  Created by Kim de Vos on 28/02/2017.
//  Copyright © 2017 Realm. All rights reserved.
//
import Foundation
import SourceKittenFramework

public struct TypeInterfaceRule: ASTRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "type_interface",
        name: "Type Interface",
        description: "Properties should have a type interface",
        nonTriggeringExamples: [
            "var myVar: Int? = 0",
            "let myVar: Int = 0"
        ],
        triggeringExamples: [
            "var myVar: ↓ = 0",
            "let myVar: ↓ = 0"

        ]
    )

    public func validate(file: File, kind: SwiftDeclarationKind,
                         dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        guard kind == .varInstance else {
            return []
        }

        // Check if the property have a type
        if dictionary.typeName != nil {
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
            StyleViolation(
                ruleDescription: type(of: self).description,
                severity: configuration.severity,
                location: location
            )
        ]
    }

//    public var configuration = SeverityConfiguration(.warning)
//
//    public init() {}
//
//    public static let description = RuleDescription(
//        identifier: "weak_delegate",
//        name: "Weak Delegate",
//        description: "Delegates should be weak to avoid reference cycles.",
//        nonTriggeringExamples: [
//            "class Foo {\n  weak var delegate: SomeProtocol?\n}\n",
//            "class Foo {\n  weak var someDelegate: SomeDelegateProtocol?\n}\n",
//            "class Foo {\n  weak var delegateScroll: ScrollDelegate?\n}\n",
//            // We only consider properties to be a delegate if it has "delegate" in its name
//            "class Foo {\n  var scrollHandler: ScrollDelegate?\n}\n",
//            // Only trigger on instance variables, not local variables
//            "func foo() {\n  var delegate: SomeDelegate\n}\n",
//            // Only trigger when variable has the suffix "-delegate" to avoid false positives
//            "class Foo {\n  var delegateNotified: Bool?\n}\n",
//            // There's no way to declare a property weak in a protocol
//            "protocol P {\n var delegate: AnyObject? { get set }\n}\n",
//            "class Foo {\n protocol P {\n var delegate: AnyObject? { get set }\n}\n}\n",
//            "class Foo {\n var computedDelegate: ComputedDelegate {\n return bar() \n} \n}"
//        ],
//        triggeringExamples: [
//            "class Foo {\n  ↓var delegate: SomeProtocol?\n}\n",
//            "class Foo {\n  ↓var scrollDelegate: ScrollDelegate?\n}\n"
//        ]
//    )
//
//    public func validate(file: File, kind: SwiftDeclarationKind,
//                         dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
//        guard kind == .varInstance else {
//            return []
//        }
//
//        // Check if name contains "delegate"
//        guard let name = dictionary.name,
//            name.lowercased().hasSuffix("delegate") else {
//                return []
//        }
//
//        // Check if non-computed
//        let isComputed = dictionary.bodyLength ?? 0 > 0
//        guard !isComputed else { return [] }
//
//        // Violation found!
//        let location: Location
//        if let offset = dictionary.offset {
//            location = Location(file: file, byteOffset: offset)
//        } else {
//            location = Location(file: file.path)
//        }
//
//        return [
//            StyleViolation(
//                ruleDescription: type(of: self).description,
//                severity: configuration.severity,
//                location: location
//            )
//        ]
//    }
}
