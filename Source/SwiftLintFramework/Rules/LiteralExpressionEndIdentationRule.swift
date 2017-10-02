//
//  LiteralExpressionEndIdentationRule.swift
//  SwiftLint
//
//  Created by Marcelo Fabri on 10/02/17.
//  Copyright © 2017 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct LiteralExpressionEndIdentationRule: ASTRule, ConfigurationProviderRule, OptInRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "literal_expression_end_indentation",
        name: "Literal Expression End Indentation",
        description: "Array and dictionary literal end should have the same indentation as the line that started it.",
        kind: .style,
        nonTriggeringExamples: [
            "[1, 2, 3]",
            "[1,\n" +
            " 2\n" +
            "]",
            "[\n" +
            "   1,\n" +
            "   2\n" +
            "]",
            "[\n" +
            "   1,\n" +
            "   2]\n",
            "   let x = [\n" +
            "       1,\n" +
            "       2\n" +
            "   ]",
            "[key: 2, key2: 3]",
            "[key: 1,\n" +
            " key2: 2\n" +
            "]",
            "[\n" +
            "   key: 0,\n" +
            "   key2: 20\n" +
            "]"
        ],
        triggeringExamples: [
            "let x = [\n" +
            "   1,\n" +
            "   2\n" +
            "   ↓]",
            "   let x = [\n" +
            "       1,\n" +
            "       2\n" +
            "↓]",
            "let x = [\n" +
            "   key: value\n" +
            "   ↓]"
        ]
    )

    private static let notWhitespace = regex("[^\\s]")

    public func validate(file: File, kind: SwiftExpressionKind,
                         dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        guard kind == .dictionary || kind == .array else {
            return []
        }

        let elements = dictionary.elements.filter { $0.kind == "source.lang.swift.structure.elem.expr" }

        let contents = file.contents.bridge()
        guard !elements.isEmpty,
            let offset = dictionary.offset,
            let length = dictionary.length,
            let (startLine, _) = contents.lineAndCharacter(forByteOffset: offset),
            let firstParamOffset = elements[0].offset,
            let (firstParamLine, _) = contents.lineAndCharacter(forByteOffset: firstParamOffset),
            startLine != firstParamLine,
            let lastParamOffset = elements.last?.offset,
            let (lastParamLine, _) = contents.lineAndCharacter(forByteOffset: lastParamOffset),
            case let endOffset = offset + length - 1,
            let (endLine, endPosition) = contents.lineAndCharacter(forByteOffset: endOffset),
            lastParamLine != endLine else {
                return []
        }

        let range = file.lines[startLine - 1].range
        let regex = LiteralExpressionEndIdentationRule.notWhitespace
        let actual = endPosition - 1
        guard let match = regex.firstMatch(in: file.contents, options: [], range: range)?.range,
            case let expected = match.location - range.location,
            expected != actual  else {
                return []
        }

        let reason = "\(LiteralExpressionEndIdentationRule.description.description) " +
                     "Expected \(expected), got \(actual)."
        return [
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severity,
                           location: Location(file: file, byteOffset: endOffset),
                           reason: reason)
        ]
    }
}
