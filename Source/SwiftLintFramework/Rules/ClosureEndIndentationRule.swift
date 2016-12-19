//
//  ClosureEndIndentationRule.swift
//  SwiftLint
//
//  Created by Marcelo Fabri on 12/18/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct ClosureEndIndentationRule: ASTRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "closure_end_indentation",
        name: "Closure End Indentation",
        description: "Closure end should have the same indentation as the line that started it.",
        nonTriggeringExamples: [
            "SignalProducer(values: [1, 2, 3])\n" +
            "   .startWithNext { number in\n" +
            "       print(number)\n" +
            "   }"
        ],
        triggeringExamples: [
            "SignalProducer(values: [1, 2, 3])\n" +
            "   .startWithNext { number in\n" +
            "       print(number)\n" +
            "}"
        ]
    )

    private static let notWhitespace = regex("[^\\s]")

    public func validateFile(_ file: File,
                             kind: SwiftExpressionKind,
                             dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        guard kind == .call else {
            return []
        }

        let contents = file.contents
        guard let offset = (dictionary["key.offset"] as? Int64).flatMap({ Int($0) }),
            let length = (dictionary["key.length"] as? Int64).flatMap({ Int($0) }),
            let bodyOffset = (dictionary["key.bodyoffset"] as? Int64).flatMap({ Int($0) }),
            let bodyLength = (dictionary["key.bodylength"] as? Int64).flatMap({ Int($0) }),
            bodyLength > 0,
            case let endOffset = offset + length - 1,
            contents.bridge().substringWithByteRange(start: endOffset, length: 1) == "}",
            let (startLine, _) = contents.lineAndCharacter(forByteOffset: bodyOffset),
            let (endLine, endPosition) = contents.lineAndCharacter(forByteOffset: endOffset),
            startLine != endLine else {
                return []
        }

        let range = file.lines[startLine - 1].range
        let regex = ClosureEndIndentationRule.notWhitespace
        guard let match = regex.firstMatch(in: contents, options: [], range: range)?.range,
            match.location - range.location != endPosition - 1 else {
                return []
        }

        return [
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severity,
                           location: Location(file: file, byteOffset: endOffset))
        ]
    }
}
