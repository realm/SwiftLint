//
//  DynamicInlineRule.swift
//  SwiftLint
//
//  Created by Daniel Duan on 12/08/16.
//  Copyright © 2015 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct DynamicInlineRule: ASTRule, ConfigurationProviderRule {

    public var configuration = SeverityConfiguration(.error)

    public init() {}

    public static let description = RuleDescription(
        identifier: "dynamic_inline",
        name: "Dynamic Inline",
        description: "avoid using 'dynamic' and '@inline(__always)' together.",
        nonTriggeringExamples: [
            "class C {\ndynamic func f() {}}",
            "class C {\n@inline(__always) func f() {}}",
            "class C {\n@inline(never) dynamic func f() {}}"
        ],
        triggeringExamples: [
            "class C {\n@inline(__always) dynamic ↓func f() {}\n}",
            "class C {\n@inline(__always) public dynamic ↓func f() {}\n}",
            "class C {\n@inline(__always) dynamic internal ↓func f() {}\n}",
            "class C {\n@inline(__always)\ndynamic ↓func f() {}\n}",
            "class C {\n@inline(__always)\ndynamic\n↓func f() {}\n}"
        ]
    )

    public func validate(file: File, kind: SwiftDeclarationKind,
                         dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        // Look for functions with both "inline" and "dynamic". For each of these, we can get offset
        // of the "func" keyword. We can assume that the nearest "@inline" before this offset is
        // the attribute we are interested in.
        guard functionKinds.contains(kind),
            case let attributes = dictionary.enclosedSwiftAttributes,
            attributes.contains("source.decl.attribute.dynamic"),
            attributes.contains("source.decl.attribute.inline"),
            let funcByteOffset = dictionary.offset,
            let funcOffset = file.contents.bridge()
                .byteRangeToNSRange(start: funcByteOffset, length: 0)?.location,
            case let inlinePattern = regex("@inline"),
            case let range = NSRange(location: 0, length: funcOffset),
            let inlineMatch = inlinePattern.matches(in: file.contents, options: [], range: range)
                .last,
            inlineMatch.range.location != NSNotFound,
            case let attributeRange = NSRange(location: inlineMatch.range.location,
                length: funcOffset - inlineMatch.range.location),
            case let alwaysInlinePattern = regex("@inline\\(\\s*__always\\s*\\)"),
            alwaysInlinePattern.firstMatch(in: file.contents, options: [], range: attributeRange) != nil
        else {
            return []
        }
        return [StyleViolation(ruleDescription: type(of: self).description,
                    severity: configuration.severity,
                    location: Location(file: file, characterOffset: funcOffset))]
    }

    fileprivate let functionKinds: [SwiftDeclarationKind] = [
        .functionAccessorAddress,
        .functionAccessorDidset,
        .functionAccessorGetter,
        .functionAccessorMutableaddress,
        .functionAccessorSetter,
        .functionAccessorWillset,
        .functionConstructor,
        .functionDestructor,
        .functionFree,
        .functionMethodClass,
        .functionMethodInstance,
        .functionMethodStatic,
        .functionOperator,
        .functionSubscript
    ]
}
