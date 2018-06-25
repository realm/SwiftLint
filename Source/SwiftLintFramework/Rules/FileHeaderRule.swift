import Foundation
import SourceKittenFramework

public struct FileHeaderRule: ConfigurationProviderRule, OptInRule {
    public var configuration = FileHeaderConfiguration()

    public init() {}

    public static let description = RuleDescription(
        identifier: "file_header",
        name: "File Header",
        description: "Header comments should be consistent with project patterns. " +
            "The SWIFTLINT_CURRENT_FILENAME placeholder can optionally be used in the " +
            "required and forbidden patterns. It will be replaced by the real file name.",
        kind: .style,
        nonTriggeringExamples: [
            "let foo = \"Copyright\"",
            "let foo = 2 // Copyright",
            "let foo = 2\n // Copyright"
        ],
        triggeringExamples: [
            "// ↓Copyright\n",
            "//\n// ↓Copyright",
            "//\n" +
            "//  FileHeaderRule.swift\n" +
            "//  SwiftLint\n" +
            "//\n" +
            "//  Created by Marcelo Fabri on 27/11/16.\n" +
            "//  ↓Copyright © 2016 Realm. All rights reserved.\n" +
            "//"
        ]
    )

    private static let reason = "Header comments should be consistent with project patterns."

    public func validate(file: File) -> [StyleViolation] {
        var firstToken: SyntaxToken?
        var lastToken: SyntaxToken?
        var firstNonCommentToken: SyntaxToken?

        for token in file.syntaxTokensByLines.lazy.joined() {
            guard let kind = SyntaxKind(rawValue: token.type), kind.isFileHeaderKind else {
                // found a token that is not a comment, which means it's not the top of the file
                // so we can just skip the remaining tokens
                firstNonCommentToken = token
                break
            }

            // skip SwiftLint commands
            guard !isSwiftLintCommand(token: token, file: file) else {
                continue
            }

            if firstToken == nil {
                firstToken = token
            }
            lastToken = token
        }

        let requiredRegex = configuration.requiredRegex(for: file)

        var violationsOffsets = [Int]()
        if let firstToken = firstToken, let lastToken = lastToken {
            let start = firstToken.offset
            let length = lastToken.offset + lastToken.length - firstToken.offset
            guard let range = file.contents.bridge().byteRangeToNSRange(start: start, length: length) else {
                return []
            }

            if let regex = configuration.forbiddenRegex(for: file),
                let firstMatch = regex.matches(in: file.contents, options: [], range: range).first {
                violationsOffsets.append(firstMatch.range.location)
            }

            if let regex = requiredRegex,
                case let matches = regex.matches(in: file.contents, options: [], range: range),
                matches.isEmpty {
                violationsOffsets.append(start)
            }
        } else if requiredRegex != nil {
            let location = firstNonCommentToken.map {
                Location(file: file, byteOffset: $0.offset)
            } ?? Location(file: file.path, line: 1)
            return [
                StyleViolation(ruleDescription: type(of: self).description,
                               severity: configuration.severityConfiguration.severity,
                               location: location,
                               reason: type(of: self).reason)
            ]
        }

        return violationsOffsets.map {
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severityConfiguration.severity,
                           location: Location(file: file, characterOffset: $0),
                           reason: type(of: self).reason)
        }
    }

    private func isSwiftLintCommand(token: SyntaxToken, file: File) -> Bool {
        guard let range = file.contents.bridge().byteRangeToNSRange(start: token.offset,
                                                                    length: token.length) else {
            return false
        }

        return !file.commands(in: range).isEmpty
    }
}

private extension SyntaxKind {
    var isFileHeaderKind: Bool {
        return self == .comment || self == .commentURL
    }
}
