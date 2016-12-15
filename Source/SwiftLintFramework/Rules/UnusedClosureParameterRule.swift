//
//  UnusedClosureParameterRule.swift
//  SwiftLint
//
//  Created by Marcelo Fabri on 15/12/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct UnusedClosureParameterRule: ASTRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "unused_closure_parameter",
        name: "Unused Closure Parameter",
        description: "Unused parameter in a closure should be replaced with _.",
        nonTriggeringExamples: [
            "[1, 2].map { $0 + 1 }\n",
            "[1, 2].map({ $0 + 1 })\n",
            "[1, 2].map { number in\n number + 1 \n}\n",
            "[1, 2].map { _ in\n 3 \n}\n",
            "[1, 2].something { number, idx in\n return number * idx\n}\n",
            "let isEmpty = [1, 2].isEmpty()\n",
            "violations.sorted(by: { lhs, rhs in \n return lhs.location > rhs.location\n})\n",
            "rlmConfiguration.migrationBlock.map { rlmMigration in\n" +
                "return { migration, schemaVersion in\n" +
                "rlmMigration(migration.rlmMigration, schemaVersion)\n" +
                "}\n" +
            "}"
        ],
        triggeringExamples: [
            "[1, 2].map { ↓number in\n return 3\n}\n",
            "[1, 2].map { ↓number in\n return numberWithSuffix\n}\n",
            "[1, 2].map { ↓number in\n return 3 // number\n}\n",
            "[1, 2].map { ↓number in\n return 3 \"number\"\n}\n",
            "[1, 2].something { number, ↓idx in\n return number\n}\n"
        ]
    )

    private static let emptyParenthesesRegex = regex("^\\s*\\(\\s*\\)")

    public func validateFile(_ file: File,
                             kind: SwiftExpressionKind,
                             dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        guard kind == .call else {
            return []
        }

        guard let offset = (dictionary["key.offset"] as? Int64).flatMap({ Int($0) }),
            let length = (dictionary["key.length"] as? Int64).flatMap({ Int($0) }),
            let nameOffset = (dictionary["key.nameoffset"] as? Int64).flatMap({ Int($0) }),
            let nameLength = (dictionary["key.namelength"] as? Int64).flatMap({ Int($0) }),
            let bodyLength = (dictionary["key.bodylength"] as? Int64).flatMap({ Int($0) }),
            bodyLength > 0 else {
                return []
        }

        let rangeStart = nameOffset + nameLength
        let rangeLength = (offset + length) - (nameOffset + nameLength)
        let parameters = filterByKind(dictionary: dictionary, kind: .varParameter)
        let contents = file.contents.bridge()

        return parameters.flatMap { param -> StyleViolation? in
            guard let paramOffset = (param["key.offset"] as? Int64).flatMap({ Int($0) }),
                let name = param["key.name"] as? String else {
                return nil
            }

            // swiftlint:disable:next force_try
            let regex = try! NSRegularExpression(pattern: name, options: [.ignoreMetacharacters])
            guard let range = contents.byteRangeToNSRange(start: rangeStart,
                                                          length: rangeLength) else {
                return nil
            }

            let matches = regex.matches(in: file.contents, options: [], range: range).ranges()
            for range in matches {
                guard let byteRange = contents.NSRangeToByteRange(start: range.location,
                                                                  length: range.length) else {
                    continue
                }

                // if it's the parameter declaration itself, we should skip
                if byteRange.location == paramOffset {
                    continue
                }

                let tokens = file.syntaxMap.tokensIn(byteRange)
                // a parameter usage should be only one token
                if tokens.count != 1 {
                    continue
                }

                // found an usage, there's no violation!
                if let token = tokens.first, SyntaxKind(rawValue: token.type) == .identifier,
                    token.offset == byteRange.location, token.length == byteRange.length {
                    return nil
                }
            }

            let reason = "Unused parameter \"\(name)\" in a closure should be replaced with _."
            return StyleViolation(ruleDescription: type(of: self).description,
                                  severity: configuration.severity,
                                  location: Location(file: file, byteOffset: paramOffset),
                                  reason: reason)
        }
    }

    private func filterByKind(dictionary: [String: SourceKitRepresentable],
                              kind: SwiftDeclarationKind) -> [[String: SourceKitRepresentable]] {

        let substructure = dictionary["key.substructure"] as? [SourceKitRepresentable] ?? []
        return substructure.flatMap { subItem -> [[String: SourceKitRepresentable]] in
            guard let subDict = subItem as? [String: SourceKitRepresentable],
                let kindString = subDict["key.kind"] as? String else {
                    return []
            }

            if SwiftDeclarationKind(rawValue: kindString) == kind {
                return [subDict]
            }

            if SwiftExpressionKind(rawValue: kindString) == .argument {
                return filterByKind(dictionary: subDict, kind: kind)
            }

            return []
        }
    }
}
