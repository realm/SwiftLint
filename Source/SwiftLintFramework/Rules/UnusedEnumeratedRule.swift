//
//  UnusedEnumeratedRule.swift
//  SwiftLint
//
//  Created by Marcelo Fabri on 12/17/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct UnusedEnumeratedRule: ASTRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "unused_enumerated",
        name: "Unused Enumerated",
        description: "When the index is not used, .enumerated() can be removed.",
        nonTriggeringExamples: [
            "for (idx, foo) in bar.enumerated() { }\n",
            "for (_, foo) in bar.enumerated().something() { }\n",
            "for (_, foo) in bar.something() { }\n",
            "for foo in bar.enumerated() { }\n",
            "for foo in bar { }\n",
            "for (idx, _) in bar.enumerated() { }\n"
        ],
        triggeringExamples: [
            "for (↓_, foo) in bar.enumerated() { }\n",
            "for (↓_, foo) in abc.bar.enumerated() { }\n",
            "for (↓_, foo) in abc.something().enumerated() { }\n"
        ]
    )

    public func validateFile(_ file: File,
                             kind: StatementKind,
                             dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {

        guard kind == .forEach,
            isEnumeratedCall(dictionary),
            let byteRange = byteRangeForVariables(dictionary),
            let firstToken = file.syntaxMap.tokensIn(byteRange).first,
            firstToken.length == 1,
            SyntaxKind(rawValue: firstToken.type) == .keyword,
            isUnderscore(file: file, token: firstToken) else {
            return []
        }

        return [
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severity,
                           location: Location(file: file, byteOffset: firstToken.offset))
        ]
    }

    private func isEnumeratedCall(_ dictionary: [String: SourceKitRepresentable]) -> Bool {
        for subDict in dictionary.substructure {
            guard let kindString = subDict["key.kind"] as? String,
                SwiftExpressionKind(rawValue: kindString) == .call,
                let name = subDict["key.name"] as? String else {
                    continue
            }

            if name.hasSuffix(".enumerated") {
                return true
            }
        }

        return false
    }

    private func byteRangeForVariables(_ dictionary: [String: SourceKitRepresentable]) -> NSRange? {
        guard let elements = dictionary["key.elements"] as? [SourceKitRepresentable] else {
            return nil
        }

        let expectedKind = "source.lang.swift.structure.elem.id"
        for element in elements {
            guard let subDict = element as? [String: SourceKitRepresentable],
                subDict["key.kind"] as? String == expectedKind,
                let offset = (subDict["key.offset"] as? Int64).map({ Int($0) }),
                let length = (subDict["key.length"] as? Int64).map({ Int($0) }) else {
                continue
            }

            return NSRange(location: offset, length: length)
        }

        return nil
    }

    private func isUnderscore(file: File, token: SyntaxToken) -> Bool {
        let contents = file.contents.bridge()
        return contents.substringWithByteRange(start: token.offset, length: token.length) == "_"
    }
}
