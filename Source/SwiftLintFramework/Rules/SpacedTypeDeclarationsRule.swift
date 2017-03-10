//
//  LineAfterDeclarationRule.swift
//  SwiftLint
//
//  Created by Diego Ernst on 1/31/17.
//  Copyright © 2017 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct SpacedTypeDeclarationsRule: ASTRule, ConfigurationProviderRule, CorrectableRule {

    public var configuration = SeverityConfiguration(.warning)
    private var declarationTypes: [SwiftDeclarationKind] = [.class, .enum, .struct, .protocol, .extension]

    public static let description = RuleDescription(
        identifier: "spaced_type_declarations",
        name: "Spaced Type Declarations",
        description: "The start and end of a type declaration must be enclosed by two empty lines.",
        nonTriggeringExamples: [
            "class Example { }\n",
            "class Example {\n" +
            "\n" +
            "}\n" +
            "",
            " /* multiline\n" +
            "    comment */\n" +
            "enum Enum { // testing comments\n" +
            "\n" +
            "   case first\n" +
            "   case second\n" +
            "\n" +
            "}\n" +
            ""
        ],
        triggeringExamples: [
            "↓extension Example {\n" +
            "↓   func doSomething() { }\n" +
            "↓}\n" +
            "protocol SomeProtocol { }\n",
            "struct Struct {\n" +
            "\n" +
            "↓  let someConstante: Int?\n" +
            "}\n",
            "struct Struct {\n" +
            "\n" +
            "↓  let someConstante: Int?\n" +
            "↓}\n" +
            "extension Another { }\n"
        ],
        corrections: [
            "↓extension Example {\n" +
            "↓   func doSomething() { }\n" +
            "↓}\n" +
            "protocol SomeProtocol { }\n":
            "extension Example {\n\n" +
            "   func doSomething() { }\n\n" +
            "}\n\n" +
            "protocol SomeProtocol { }\n",
            "struct Struct {\n" +
            "\n" +
            "↓  let someConstante: Int?\n" +
            "}\n":
            "struct Struct {\n" +
            "\n" +
            "  let someConstante: Int?\n\n" +
            "}\n",
            "struct Struct {\n" +
            "\n" +
            "↓  let someConstante: Int?\n" +
            "↓}\n" +
            "extension Another { }\n":
            "struct Struct {\n" +
            "\n" +
            "  let someConstante: Int?\n\n" +
            "}\n\n" +
            "extension Another { }\n",
            "↓class Class {\n" +
            "   let array = [\n" +
            "       1,\n" +
            "       2\n" +
            "↓   ]\n" +
            "}\n":
            "class Class {\n\n" +
            "   let array = [\n" +
            "       1,\n" +
            "       2\n" +
            "   ]\n\n" +
            "}\n"
        ]
    )

    public init() {}

    public func validate(file: File, kind: SwiftDeclarationKind,
                         dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        guard
            declarationTypes.contains(kind),
            let bodyOffset = dictionary.bodyOffset,
            let bodyLength = dictionary.bodyLength,
            let (startLine, _) = file.contents.bridge().lineAndCharacter(forByteOffset: bodyOffset),
            let (endLine, _) = file.contents.bridge().lineAndCharacter(forByteOffset: bodyOffset + bodyLength),
            startLine != endLine
        else {
            return []
        }
        return findErrors(startLine: startLine, endLine: endLine, file: file)
    }

    private func findErrors(startLine: Int, endLine: Int, file: File) -> [StyleViolation] {
        var errorLines = [Int]()
        errorLines.append(contentsOf: checkBeforeAndAfterLines(line: startLine, file: file))
        errorLines.append(contentsOf: checkBeforeAndAfterLines(line: endLine, file: file))
        return errorLines.unique.map { StyleViolation(
                ruleDescription: type(of: self).description,
                severity: self.configuration.severity,
                location: Location(file: file.path, line: $0, character: 1)
            )
        }
    }

    private func checkBeforeAndAfterLines(line: Int, file: File) -> [Int] {
        var nonEmptyLines = [Int]()
        if line - 2 >= 0 && !isLineEmpty(line - 2, file: file) {
            nonEmptyLines.append(line - 1)
        }
        if line < file.lines.count && !isLineEmpty(line, file: file) {
            nonEmptyLines.append(line)
        }
        return nonEmptyLines
    }

    private func isLineEmpty(_ lineIndex: Int, file: File) -> Bool {
        let line = file.lines[lineIndex].content.trimmingCharacters(in: .whitespaces)
        guard line != "}" && line != "]" else { return false }
        let lineKinds: [SyntaxKind] = file.syntaxTokensByLines[lineIndex + 1].flatMap { SyntaxKind(rawValue: $0.type) }
        let commentKinds = SyntaxKind.commentKinds()
        return lineKinds.reduce(true) { $0.0 && commentKinds.contains($0.1) }
    }

    public func correct(file: File) -> [Correction] {
        let ranges: [StyleViolation] = validate(file: file)
        guard !ranges.isEmpty else { return [] }
        var lines: [String] = file.lines.map { $0.content }
        var corrections = [Correction]()

        ranges.sorted { $0.location > $1.location }.forEach {
            if let line = $0.location.line {
                let lineRange = file.lines[line].range
                if !file.ruleEnabled(violatingRanges: [lineRange], for: self).isEmpty {
                    lines.insert("", at: line)
                    corrections.append(Correction(ruleDescription: type(of: self).description, location: $0.location))
                }
            }
        }

        file.write(lines.joined(separator: "\n") + "\n")
        return corrections
    }

}
