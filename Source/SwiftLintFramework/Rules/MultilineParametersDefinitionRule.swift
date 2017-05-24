//
//  MultilineMethodDefinitionRule.swift
//  SwiftLint
//
//  Created by Ornithologist Coder on 22/05/17.
//  Copyright © 2017 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct MultilineParametersDefinitionRule: ASTRule, OptInRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "multiline_parameters_definition",
        name: "Multiline parameters definition",
        description: "Functions and methods parameters should be either on the same line, or one per line.",
        nonTriggeringExamples: MultilineParametersRulesExamples.nonTriggeringExamples,
        triggeringExamples: MultilineParametersRulesExamples.triggeringExamples
    )

    public func validate(file: File,
                         kind: SwiftDeclarationKind,
                         dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        guard isValidFunction(kind),
            let offset = dictionary.nameOffset,
            let length = dictionary.nameLength
            else {
                return []
        }

        var numberOfParameters: Int = 0
        var linesWithParameters: Set<Int> = []

        for structure in dictionary.substructure {
            guard
                let structureOffset = structure.offset,
                let (line, _) = file.contents.bridge().lineAndCharacter(forByteOffset: structureOffset),
                structure.kind == SwiftDeclarationKind.varParameter.rawValue,
                structure.typeName != nil
                else {
                    continue
            }

            guard offset..<(offset + length) ~= structureOffset else { break }

            linesWithParameters.insert(line)
            numberOfParameters += 1
        }

        if linesWithParameters.count > 1 && numberOfParameters != linesWithParameters.count {
            return [StyleViolation(ruleDescription: type(of: self).description,
                                   severity: configuration.severity,
                                   location: Location(file: file, byteOffset: offset))]
        }

        return []
    }

    // MARK: - Private

    private func isValidFunction(_ kind: SwiftDeclarationKind) -> Bool {
        return [
            SwiftDeclarationKind.functionMethodStatic,
            SwiftDeclarationKind.functionMethodClass,
            SwiftDeclarationKind.functionMethodInstance,
            SwiftDeclarationKind.functionFree
        ].contains(kind)
    }
}
