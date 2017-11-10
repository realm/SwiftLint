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
            "@available(swift 4)\nlet a = 0\n",
            "class C {\n\t@objc\n\tvar s: String = \"\"\n}",
            "class C {\n\t@objc\n\tfunc a() {}\n}",
            "class C {\n\tvar x = 0\n\tlazy\n\tvar y = 0\n}\n",
            "@available(OSX, introduced: 10.6)\n@available(*, deprecated)\nvar x = 0\n",
            "// swiftlint:disable superfluous_disable_command\n// swiftlint:disable force_cast\n\nlet x = bar as! Bar"
        ],
        triggeringExamples: [
            "var x = 1\n↓x = 2\n",
            "\na = 5\n↓var x = 1\n",
            // This case doesn't work because of an apparent limitation in SourceKit
            // "var x: Int {\n\tlet a = 0\n\t↓return a\n}\n",
            "struct X {\n\tlet a\n\t↓func x() {}\n}\n",
            "var x = 0\n↓@objc func f() {}\n",
            "var x = 0\n↓@objc\n\tfunc f() {}\n",
            "@objc func f() {\n}\n↓var x = 0\n"
        ]
    )

    public func validate(file: File) -> [StyleViolation] {
        var attributeLines = attributeLineNumbers(file: file)
        let varLines = varLetLineNumbers(file: file,
                                         structure: file.structure.dictionary.substructure,
                                         attributeLines: &attributeLines)
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
        let offset = content.distance(from: content.startIndex, to: startIndex)
        let location = Location(file: file, characterOffset: offset + file.lines[line].range.location)

        violations.append(StyleViolation(ruleDescription: LetVarWhitespaceRule.description,
                                         severity: configuration.severity,
                                         location: location))
    }

    private func lineOffsets(file: File, statement: [String: SourceKitRepresentable]) -> (Int, Int)? {
        guard let offset = statement.offset,
              let length = statement.length else {
            return nil
        }
        let startLine = file.line(byteOffset: offset, startFrom: 0)
        let endLine = file.line(byteOffset: offset + length, startFrom: max(startLine, 0))

        return (startLine, endLine)
    }

    // Collects all the line numbers containing var or let declarations
    private func varLetLineNumbers(file: File,
                                   structure: [[String: SourceKitRepresentable]],
                                   attributeLines: inout Set<Int>) -> Set<Int> {
        var result = Set<Int>()

        for statement in structure {
            guard let kind = statement.kind,
                  let (startLine, endLine) = lineOffsets(file: file, statement: statement) else {
                continue
            }

            if SwiftDeclarationKind.nonVarAttributableKinds.contains(where: { $0.rawValue == kind }) {
                if attributeLines.contains(startLine) {
                    attributeLines.remove(startLine)
                }
            }
            if SwiftDeclarationKind.varKinds.contains(where: { $0.rawValue == kind }) {
                var lines = Set(startLine...((endLine < 0) ? file.lines.count : endLine))
                var previousLine = startLine - 1

                // Include preceding attributes
                while attributeLines.contains(previousLine) {
                    lines.insert(previousLine)
                    attributeLines.remove(previousLine)
                    previousLine -= 1
                }

                // Exclude the body where the accessors are
                if let bodyOffset = statement.bodyOffset,
                   let bodyLength = statement.bodyLength {
                    let bodyStart = file.line(byteOffset: bodyOffset, startFrom: startLine) + 1
                    let bodyEnd = file.line(byteOffset: bodyOffset + bodyLength, startFrom: bodyStart) - 1

                    if bodyStart <= bodyEnd {
                        lines.subtract(Set(bodyStart...bodyEnd))
                    }
                }
                result.formUnion(lines)
            }

            let substructure = statement.substructure

            if !substructure.isEmpty {
                result.formUnion(varLetLineNumbers(file: file,
                                                   structure: substructure,
                                                   attributeLines: &attributeLines))
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
            let startLine = file.line(byteOffset: token.offset, startFrom: 0)
            let endLine = file.line(byteOffset: token.offset + token.length, startFrom: startLine)

            if startLine <= endLine {
                result.formUnion(Set(startLine...endLine))
            }
        }

        let directives = ["#if", "#elseif", "#else", "#endif", "#!"]
        let directiveLines = file.lines.filter {
            let trimmed = $0.content.trimmingCharacters(in: .whitespaces)
            return directives.contains(where: trimmed.hasPrefix)
        }

        result.formUnion(directiveLines.map { $0.index - 1 })
        return result
    }

    // Collects all the line numbers containing attributes but not declarations
    // other than let/var
    private func attributeLineNumbers(file: File) -> Set<Int> {
        return Set(file.syntaxMap.tokens.flatMap({ token in
            if token.type == SyntaxKind.attributeBuiltin.rawValue {
                return file.line(byteOffset: token.offset)
            }
            return nil
        }))
    }
}

private extension SwiftDeclarationKind {
    // The various kinds of let/var declarations
    static let varKinds: [SwiftDeclarationKind] = [.varGlobal, .varClass, .varLocal, .varStatic, .varInstance]
    // Declarations other than let & var that can have attributes
    static let nonVarAttributableKinds: [SwiftDeclarationKind] = [
        .class, .struct,
        .functionFree, .functionSubscript, .functionDestructor, .functionConstructor,
        .functionMethodClass, .functionMethodStatic, .functionMethodInstance,
        .functionOperator, .functionOperatorInfix, .functionOperatorPrefix, .functionOperatorPostfix ]
}

private extension File {
    // Zero-based line number for the given a byte offset
    func line(byteOffset: Int, startFrom: Int = 0) -> Int {
        for index in startFrom..<lines.count {
            let line = lines[index]

            if line.byteRange.location + line.byteRange.length > byteOffset {
                return index
            }
        }
        return -1
    }

    // Zero-based line number for the given a character offset
    func line(offset: Int, startFrom: Int = 0) -> Int {
        for index in startFrom..<lines.count {
            let line = lines[index]

            if line.range.location + line.range.length > offset {
                return index
            }
        }
        return -1
    }
}
