//
//  MultilineParametersRule.swift
//  SwiftLint
//
//  Created by Ornithologist Coder on 22/05/17.
//  Copyright © 2017 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct MultilineParametersRule: ASTRule, OptInRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    private typealias ParameterRange = (offset: Int, length: Int)

    public init() {}

    public static let description = RuleDescription(
        identifier: "multiline_parameters",
        name: "Multiline Parameters",
        description: "Functions and methods parameters should be either on the same line, or one per line.",
        kind: .style,
        nonTriggeringExamples: MultilineParametersRuleExamples.nonTriggeringExamples,
        triggeringExamples: MultilineParametersRuleExamples.triggeringExamples
    )

    public func validate(file: File,
                         kind: SwiftDeclarationKind,
                         dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        guard
            SwiftDeclarationKind.functionKinds.contains(kind),
            let offset = dictionary.nameOffset,
            let length = dictionary.nameLength
            else {
                return []
        }

        let parameterRanges = dictionary.substructure.compactMap { subStructure -> ParameterRange? in
            guard
                let offset = subStructure.offset,
                let length = subStructure.length,
                let kind = subStructure.kind, SwiftDeclarationKind(rawValue: kind) == .varParameter
                else {
                    return nil
            }

            return (offset, length)
        }

        var numberOfParameters = 0
        var linesWithParameters = Set<Int>()

        for range in parameterRanges {
            guard
                let (line, _) = file.contents.bridge().lineAndCharacter(forByteOffset: range.offset),
                offset..<(offset + length) ~= range.offset,
                isRange(range, withinRanges: parameterRanges)
                else {
                    continue
            }

            linesWithParameters.insert(line)
            numberOfParameters += 1
        }

        guard
            linesWithParameters.count > 1,
            numberOfParameters != linesWithParameters.count
            else {
                return []
        }

        return [StyleViolation(ruleDescription: type(of: self).description,
                               severity: configuration.severity,
                               location: Location(file: file, byteOffset: offset))]
    }

    // MARK: - Private

    private func isRange(_ range: ParameterRange, withinRanges ranges: [ParameterRange]) -> Bool {
        return ranges.filter { $0 != range && ($0.offset..<($0.offset + $0.length)).contains(range.offset) }.isEmpty
    }
}
