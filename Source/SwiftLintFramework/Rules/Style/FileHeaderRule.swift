import Foundation
import SourceKittenFramework

struct FileHeaderRule: ConfigurationProviderRule, OptInRule {
    var configuration = FileHeaderConfiguration()

    init() {}

    static let description = RuleDescription(
        identifier: "file_header",
        name: "File Header",
        description: "Header comments should be consistent with project patterns. " +
            "The SWIFTLINT_CURRENT_FILENAME placeholder can optionally be used in the " +
            "required and forbidden patterns. It will be replaced by the real file name.",
        kind: .style,
        nonTriggeringExamples: [
            Example("let foo = \"Copyright\""),
            Example("let foo = 2 // Copyright"),
            Example("let foo = 2\n // Copyright")
        ],
        triggeringExamples: [
            Example("// ↓Copyright\n"),
            Example("//\n// ↓Copyright"),
            Example("""
            //
            //  FileHeaderRule.swift
            //  SwiftLint
            //
            //  Created by Marcelo Fabri on 27/11/16.
            //  ↓Copyright © 2016 Realm. All rights reserved.
            //
            """)
        ].skipWrappingInCommentTests()
    )

    func validate(file: SwiftLintFile) -> [StyleViolation] {
        var firstToken: SwiftLintSyntaxToken?
        var lastToken: SwiftLintSyntaxToken?
        var firstNonCommentToken: SwiftLintSyntaxToken?

        for token in file.syntaxTokensByLines.lazy.joined() {
            guard let kind = token.kind, kind.isFileHeaderKind else {
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
        if let firstToken, let lastToken {
            let start = firstToken.offset
            let length = lastToken.offset + lastToken.length - firstToken.offset
            let byteRange = ByteRange(location: start, length: length)
            guard let range = file.stringView.byteRangeToNSRange(byteRange) else {
                return []
            }

            if let regex = configuration.forbiddenRegex(for: file),
                let firstMatch = regex.matches(in: file.contents, options: [], range: range).first {
                violationsOffsets.append(firstMatch.range.location)
            }

            if let regex = requiredRegex,
                case let matches = regex.matches(in: file.contents, options: [], range: range),
                matches.isEmpty {
                violationsOffsets.append(file.stringView.location(fromByteOffset: start))
            }
        } else if requiredRegex != nil {
            let location = firstNonCommentToken.map {
                Location(file: file, byteOffset: $0.offset)
            } ?? Location(file: file.path, line: 1)
            return [makeViolation(at: location)]
        }

        return violationsOffsets.map { makeViolation(at: Location(file: file, characterOffset: $0)) }
    }

    private func isSwiftLintCommand(token: SwiftLintSyntaxToken, file: SwiftLintFile) -> Bool {
        guard let range = file.stringView.byteRangeToNSRange(token.range) else {
            return false
        }

        return file.commands(in: range).isNotEmpty
    }

    private func makeViolation(at location: Location) -> StyleViolation {
        return StyleViolation(ruleDescription: Self.description,
                              severity: configuration.severityConfiguration.severity,
                              location: location,
                              reason: "Header comments should be consistent with project patterns")
    }
}

private extension SyntaxKind {
    var isFileHeaderKind: Bool {
        return self == .comment || self == .commentURL
    }
}
