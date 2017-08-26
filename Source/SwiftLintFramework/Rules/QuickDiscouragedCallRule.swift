//
//  QuickDiscouragedCallRule.swift
//  SwiftLint
//
//  Created by Ornithologist Coder on 8/11/17.
//  Copyright © 2017 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct QuickDiscouragedCallRule: OptInRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "quick_discouraged_call",
        name: "Quick Discouraged Call",
        description: "Discouraged call inside 'describe' and/or 'context' block.",
        kind: .lint,
        nonTriggeringExamples: QuickDiscouragedCallRuleExamples.nonTriggeringExamples,
        triggeringExamples: QuickDiscouragedCallRuleExamples.triggeringExamples
    )

    public func validate(file: File) -> [StyleViolation] {
        let testClasses = file.structure.dictionary.substructure.filter {
            return $0.inheritedTypes.contains("QuickSpec") &&
                $0.kind.flatMap(SwiftDeclarationKind.init) == .class
        }

        let specDeclarations = testClasses.flatMap { classDict in
            return classDict.substructure.filter {
                return $0.name == "spec()" && $0.enclosedVarParameters.isEmpty &&
                    $0.kind.flatMap(SwiftDeclarationKind.init) == .functionMethodInstance &&
                    $0.enclosedSwiftAttributes.contains("source.decl.attribute.override")
            }
        }

        return specDeclarations.flatMap {
            validate(file: file, dictionary: $0)
        }
    }

    private func validate(file: File, dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        return dictionary.substructure.flatMap { subDict -> [StyleViolation] in
            var violations = validate(file: file, dictionary: subDict)

            if let kindString = subDict.kind,
                let kind = SwiftExpressionKind(rawValue: kindString) {
                violations += validate(file: file, kind: kind, dictionary: subDict)
            }

            return violations
        }
    }

    private func validate(file: File,
                          kind: SwiftExpressionKind,
                          dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        // is it a call to a restricted method?
        guard
            kind == .call,
            let name = dictionary.name,
            let kindName = QuickCallKind(rawValue: name),
            QuickCallKind.restrictiveKinds.contains(kindName)
            else { return [] }

        return violationOffsets(in: dictionary.enclosedArguments).map {
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severity,
                           location: Location(file: file, byteOffset: $0),
                           reason: "Discouraged call inside a '\(name)' block.")
        }
    }

    private func violationOffsets(in substructure: [[String: SourceKitRepresentable]]) -> [Int] {
        return substructure.flatMap { dictionary -> [Int] in
            return dictionary.substructure.flatMap(toViolationOffsets)
        }
    }

    private func toViolationOffsets(dictionary: [String: SourceKitRepresentable]) -> [Int] {
        guard
            let kind = dictionary.kind,
            let offset = dictionary.offset
            else { return [] }

        if SwiftExpressionKind(rawValue: kind) == .call,
            let name = dictionary.name, QuickCallKind(rawValue: name) == nil {
            return [offset]
        }

        guard SwiftExpressionKind(rawValue: kind) != .call else { return [] }

        return dictionary.substructure.flatMap(toViolationOffset)
    }

    private func toViolationOffset(dictionary: [String: SourceKitRepresentable]) -> Int? {
        guard
            let name = dictionary.name,
            let offset = dictionary.offset,
            let kind = dictionary.kind,
            SwiftExpressionKind(rawValue: kind) == .call,
            QuickCallKind(rawValue: name) == nil
            else { return nil }

        return offset
    }
}

private enum QuickCallKind: String {
    case describe
    case context
    case sharedExamples
    case itBehavesLike
    case beforeEach
    case beforeSuite
    case afterEach
    case afterSuite
    case it // swiftlint:disable:this identifier_name
    case pending

    static let restrictiveKinds: Set<QuickCallKind> = [.describe, .context, .sharedExamples]
}
