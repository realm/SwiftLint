//
//  TrailingCommaRule.swift
//  SwiftLint
//
//  Created by Marcelo Fabri on 21/11/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct TrailingCommaRule: ASTRule, ConfigurationProviderRule {
    public var configuration = TrailingCommaConfiguration()

    public init() {}

    public static let description = RuleDescription(
        identifier: "trailing_comma",
        name: "Trailing Comma",
        description: "Trailing commas in arrays and dictionaries should be avoided/enforced.",
        nonTriggeringExamples: [
            "let foo = [1, 2, 3]\n",
            "let foo = []\n",
            "let foo = [:]\n",
            "let foo = [1: 2, 2: 3]\n",
            "let foo = [Void]()\n",
            "let example = [ 1,\n 2\n // 3,\n]"
        ],
        triggeringExamples: [
            "let foo = [1, 2, 3↓,]\n",
            "let foo = [1, 2, 3↓, ]\n",
            "let foo = [1, 2, 3   ↓,]\n",
            "let foo = [1: 2, 2: 3↓, ]\n",
            "struct Bar {\n let foo = [1: 2, 2: 3↓, ]\n}\n",
            "let foo = [1, 2, 3↓,] + [4, 5, 6↓,]\n",
            "let example = [ 1,\n2↓,\n // 3,\n]"
        ]
    )

    // swiftlint:disable:next force_try
    private static let regex = try! NSRegularExpression(pattern: ",",
                                                        options: [.ignoreMetacharacters])

    public func validateFile(_ file: File,
                             kind: SwiftExpressionKind,
                             dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {

        let allowedKinds: [SwiftExpressionKind] = [.array, .dictionary]

        guard let bodyOffset = (dictionary["key.bodyoffset"] as? Int64).flatMap({ Int($0) }),
            let bodyLength = (dictionary["key.bodylength"] as? Int64).flatMap({ Int($0) }),
            let elements = dictionary["key.elements"]  as? [SourceKitRepresentable],
            allowedKinds.contains(kind) else {
                return []
        }

        let endPositions = elements.flatMap { element -> Int? in
            guard let dictionary = element as? [String: SourceKitRepresentable],
                let offset = (dictionary["key.offset"] as? Int64).flatMap({ Int($0) }),
                let length = (dictionary["key.length"] as? Int64).flatMap({ Int($0) }) else {
                    return nil
            }

            return offset + length
        }

        guard let lastPosition = endPositions.max() else {
            return []
        }

        if let (startLine, _) = file.contents.bridge().lineAndCharacter(forByteOffset: bodyOffset),
            let (endLine, _) = file.contents.bridge().lineAndCharacter(forByteOffset: lastPosition),
            configuration.mandatoryComma && startLine == endLine {
            // shouldn't trigger if mandatory comma style and is a single-line declaration 
            return []
        }

        let length = bodyLength + bodyOffset - lastPosition
        let contentsAfterLastElement = file.contents.bridge()
            .substringWithByteRange(start: lastPosition, length: length) ?? ""

        // if a trailing comma is not present
        guard let commaIndex = trailingCommaIndex(contentsAfterLastElement, file: file,
                                                  offset: lastPosition) else {
            guard configuration.mandatoryComma else {
                return []
            }

            return violations(file: file, byteOffset: lastPosition)
        }

        // trailing comma is present, which is a violation if mandatoryComma is false
        guard !configuration.mandatoryComma else {
            return []
        }

        let violationOffset = lastPosition + commaIndex
        return violations(file: file, byteOffset: violationOffset)
    }

    private func violations(file: File, byteOffset: Int) -> [StyleViolation] {
        return [
            StyleViolation(ruleDescription: type(of: self).description,
                severity: configuration.severityConfiguration.severity,
                location: Location(file: file, byteOffset: byteOffset)
            )
        ]
    }

    private func trailingCommaIndex(_ contents: String, file: File, offset: Int) -> Int? {
        let range = NSRange(location: 0, length: (contents as NSString).length)
        let ranges = TrailingCommaRule.regex
            .matches(in: contents, options: [], range: range).map { $0.range }

        // skip commas in comments
        return ranges.filter {
            let range = NSRange(location: $0.location + offset, length: $0.length)
            let kinds = file.syntaxMap.tokensIn(range).flatMap { SyntaxKind(rawValue: $0.type) }
            return kinds.filter { SyntaxKind.commentKinds().contains($0) }.isEmpty
        }.last.flatMap {
            contents.NSRangeToByteRange(start: $0.location, length: $0.length)
        }?.location
    }
}

public enum SwiftExpressionKind: String {
    case array = "source.lang.swift.expr.array"
    case dictionary = "source.lang.swift.expr.dictionary"
    case other

    public init?(rawValue: String) {
        switch rawValue {
        case SwiftExpressionKind.array.rawValue:
            self = .array
        case SwiftExpressionKind.dictionary.rawValue:
            self = .dictionary
        default:
            self = .other
        }
    }
}
