//
//  LetVarWhitespaceRule.swift
//  SwiftLint
//
//  Created by David Catmull on 4/24/17.
//  Copyright © 2017 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct LetVarWhitespaceRule: ConfigurationProviderRule, OptInRule {

    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "let_var_whitespace",
        name: "Variable Declaration Whitespace",
        description: "Let and var should be separated from other statements by a blank line.",
        kind: .style,
        nonTriggeringExamples: [
            "let a = 0\nvar x = 1\n\nx = 2\n",
            "a = 5\n\nvar x = 1\n",
            "struct X {\n\tvar a = 0\n}\n",
            "let a = 1 +\n\t2\nlet b = 5\n",
            "var x: Int {\n\treturn 0\n}\n",
            "var x: Int {\n\tlet a = 0\n\n\treturn a\n}\n",
            "#if os(macOS)\nlet a = 0\n#endif\n",
            "@available(swift 4)\nlet a = 0\n"
        ],
        triggeringExamples: [
            "var x = 1\n↓x = 2\n",
            "\na = 5\n↓var x = 1\n",
            // This case doesn't work because of an apparent limitation in SourceKit
            // "var x: Int {\n\tlet a = 0\n\t↓return a\n}\n",
            "struct X {\n\tlet a\n\t↓func x() {}\n}\n"
        ]
    )

    public func validate(file: File) -> [StyleViolation] {
        let varLines = varLetLineNumbers(file: file, structure: file.structure.dictionary.substructure)
        let skippedLines = skippedLineNumbers(file: file)
        var violations = [StyleViolation]()

        for (index, line) in file.lines.enumerated() {
            guard !varLines.contains(index) &&
                  !skippedLines.contains(index) else {
                continue
            }

            let trimmed = line.content.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else {
                continue
            }

            // Precedes var/let and has text not ending with {
            if linePrecedesVar(index, varLines, skippedLines) {
                if !trimmed.hasSuffix("{") &&
                   !file.lines[index + 1].content.trimmingCharacters(in: .whitespaces).hasPrefix("}") {
                    violated(&violations, file, index + 1)
                }
            }
            // Follows var/let and has text not starting with }
            if lineFollowsVar(index, varLines, skippedLines) {
                if !trimmed.hasPrefix("}") &&
                   !file.lines[index - 1].content.trimmingCharacters(in: .whitespaces).hasSuffix("{") {
                    violated(&violations, file, index)
                }
            }
        }
        return violations
    }

    private func linePrecedesVar(_ lineNumber: Int, _ varLines: Set<Int>, _ skippedLines: Set<Int>) -> Bool {
        return lineNeighborsVar(lineNumber, varLines, skippedLines, 1)
    }

    private func lineFollowsVar(_ lineNumber: Int, _ varLines: Set<Int>, _ skippedLines: Set<Int>) -> Bool {
        return lineNeighborsVar(lineNumber, varLines, skippedLines, -1)
    }

    private func lineNeighborsVar(_ lineNumber: Int, _ varLines: Set<Int>,
                                  _ skippedLines: Set<Int>, _ increment: Int) -> Bool {
        if varLines.contains(lineNumber + increment) {
            return true
        }

        var prevLine = lineNumber

        while skippedLines.contains(prevLine) {
            if varLines.contains(prevLine + increment) {
                return true
            }
            prevLine += increment
        }
        return false
    }

    private func violated(_ violations: inout [StyleViolation], _ file: File, _ line: Int) {
        let content = file.lines[line].content
        let startIndex = content.rangeOfCharacter(from: CharacterSet.whitespaces.inverted)?.lowerBound
                         ?? content.startIndex
        let offset = content.characters.distance(from: content.startIndex, to: startIndex)
        let location = Location(file: file, characterOffset: offset + file.lines[line].range.location)

        violations.append(StyleViolation(ruleDescription: LetVarWhitespaceRule.description,
                                         severity: configuration.severity,
                                         location: location))
    }

    // Collects all the line numbers containing var or let declarations
    private func varLetLineNumbers(file: File, structure: [[String: SourceKitRepresentable]]) -> Set<Int> {
        var result = Set<Int>()

        for statement in structure {
            guard let kind = statement.kind else {
                continue
            }

            if SwiftDeclarationKind.varKinds.contains(where: { $0.rawValue == kind }) {
                guard let offset = statement.offset,
                      let length = statement.length else {
                    break
                }
                let startLine = file.line(for: offset, startFrom: 0)
                let endLine = file.line(for: offset + length, startFrom: startLine)
                var lines = Set(startLine...endLine)

                // Exclude the body where the accessors are
                if let bodyOffset = statement.bodyOffset,
                   let bodyLength = statement.bodyLength {
                    let bodyStart = file.line(for: bodyOffset, startFrom: startLine) + 1
                    let bodyEnd = file.line(for: bodyOffset + bodyLength, startFrom: bodyStart) - 1

                    if bodyStart <= bodyEnd {
                        lines.subtract(Set(bodyStart...bodyEnd))
                    }
                }
                result.formUnion(lines)
            }

            let substructure = statement.substructure

            if !substructure.isEmpty {
                result.formUnion(varLetLineNumbers(file: file, structure: substructure))
            }
        }
        return result
    }

    // Collects all the line numbers containing comments or #if/#endif
    private func skippedLineNumbers(file: File) -> Set<Int> {
        var result = Set<Int>()
        let syntaxMap = file.syntaxMap

        for token in syntaxMap.tokens where token.type == SyntaxKind.comment.rawValue ||
                                            token.type == SyntaxKind.docComment.rawValue {
            let startLine = file.line(for: token.offset, startFrom: 0)
            let endLine = file.line(for: token.offset + token.length, startFrom: startLine)

            if startLine <= endLine {
                result.formUnion(Set(startLine...endLine))
            }
        }

        let conditionals = ["#if", "#elseif", "#else", "#endif", "@available", "#!"]
        let conditionalLines = file.lines.filter {
            let trimmed = $0.content.trimmingCharacters(in: .whitespaces)
            return conditionals.contains(where: trimmed.hasPrefix)
        }

        result.formUnion(conditionalLines.map { $0.index - 1 })
        return result
    }
}

private extension SwiftDeclarationKind {
    static let varKinds: [SwiftDeclarationKind] = [.varGlobal, .varClass, .varLocal, .varStatic, .varInstance]
}

private extension File {
    func line(for byteOffset: Int, startFrom: Int) -> Int {
        for index in startFrom..<lines.count {
            let line = lines[index]

            if line.byteRange.location + line.byteRange.length > byteOffset {
                return index
            }
        }
        return 0
    }
}
