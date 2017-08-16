//
//  QuickDiscouragedCallRule.swift
//  SwiftLint
//
//  Created by Ornithologist Coder on 8/11/17.
//  Copyright © 2017 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct QuickDiscouragedCallRule: ASTRule, OptInRule, ConfigurationProviderRule {
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

    public func validate(file: File,
                         kind: SwiftExpressionKind,
                         dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        guard
            fileContainsQuickSpec(file: file),
            kind == .call,
            let name = dictionary.name,
            let kindName = QuickCallKind(rawValue: name),
            QuickCallKind.restrictiveKinds.contains(kindName)
            else { return [] }

        return violationOffsets(in: dictionary.enclosedArguments)
            .map {
                StyleViolation(ruleDescription: type(of: self).description,
                               severity: configuration.severity,
                               location: Location(file: file, byteOffset: $0),
                               reason: "Discouraged call inside a '\(name)' block.")
            }
    }

    // MARK: - Private

    private func fileContainsQuickSpec(file: File) -> Bool {
        return !file.structure.dictionary.substructure.filter { $0.inheritedTypes.contains("QuickSpec") }.isEmpty
    }

    typealias ViolationOffset = Int

    private func violationOffsets(in substructure: [[String: SourceKitRepresentable]]) -> [ViolationOffset] {
        return substructure.flatMap { dictionary -> [ViolationOffset] in
            return dictionary.substructure.flatMap(toViolationOffsets)
        }
    }

    private func toViolationOffsets(dictionary: [String: SourceKitRepresentable]) -> [ViolationOffset] {
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

    private func toViolationOffset(dictionary: [String: SourceKitRepresentable]) -> ViolationOffset? {
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

// swiftlint:disable identifier_name
private enum QuickCallKind: String {
    case describe
    case context
    case sharedExamples
    case itBehavesLike
    case beforeEach
    case beforeSuite
    case afterEach
    case afterSuite
    case it
    case pending

    static let restrictiveKinds: [QuickCallKind] = [.describe, .context, .sharedExamples]
}
// swiftlint:enabled identifier_name
