import Foundation
import SourceKittenFramework

struct LetVarWhitespaceRule: ConfigurationProviderRule, OptInRule {
    var configuration = SeverityConfiguration(.warning)

    init() {}

    static let description = RuleDescription(
        identifier: "let_var_whitespace",
        name: "Variable Declaration Whitespace",
        description: "Let and var should be separated from other statements by a blank line.",
        kind: .style,
        nonTriggeringExamples: [
            Example("let a = 0\nvar x = 1\n\nx = 2\n"),
            Example("a = 5\n\nvar x = 1\n"),
            Example("struct X {\n\tvar a = 0\n}\n"),
            Example("let a = 1 +\n\t2\nlet b = 5\n"),
            Example("var x: Int {\n\treturn 0\n}\n"),
            Example("var x: Int {\n\tlet a = 0\n\n\treturn a\n}\n"),
            Example("#if os(macOS)\nlet a = 0\n#endif\n"),
            Example("#warning(\"TODO: remove it\")\nlet a = 0\n"),
            Example("#error(\"TODO: remove it\")\nlet a = 0\n"),
            Example("@available(swift 4)\nlet a = 0\n"),
            Example("class C {\n\t@objc\n\tvar s: String = \"\"\n}"),
            Example("class C {\n\t@objc\n\tfunc a() {}\n}"),
            Example("class C {\n\tvar x = 0\n\tlazy\n\tvar y = 0\n}\n"),
            Example("@available(OSX, introduced: 10.6)\n@available(*, deprecated)\nvar x = 0\n"),
            Example("""
            // swiftlint:disable superfluous_disable_command
            // swiftlint:disable force_cast

            let x = bar as! Bar
            """),
            Example("""
                @available(swift 4)
                @UserDefault("param", defaultValue: true)
                var isEnabled = true

                @Attribute
                func f() {}
            """),
            Example("var x: Int {\n\tlet a = 0\n\treturn a\n}\n") // don't trigger on local vars
        ],
        triggeringExamples: [
            Example("var x = 1\n↓x = 2\n"),
            Example("\na = 5\n↓var x = 1\n"),
            Example("struct X {\n\tlet a\n\t↓func x() {}\n}\n"),
            Example("var x = 0\n↓@objc func f() {}\n"),
            Example("var x = 0\n↓@objc\n\tfunc f() {}\n"),
            Example("@objc func f() {\n}\n↓var x = 0\n"),
            Example("""
                struct S {
                    func f() {}
                    ↓@Wapper
                    let isNumber = false
                    @Wapper
                    var isEnabled = true
                    ↓func g() {}
                }
            """)
        ]
    )

    func validate(file: SwiftLintFile) -> [StyleViolation] {
        let dict = file.structureDictionary

        var attributeLines = attributeLineNumbers(file: file)
        var varLines = Set<Int>()
        varLetLineNumbers(file: file,
                          structure: dict.substructure,
                          attributeLines: &attributeLines,
                          collectingInto: &varLines)
        let skippedLines = skippedLineNumbers(file: file)
        var violations = [StyleViolation]()

        for (index, line) in file.lines.enumerated() {
            guard !varLines.contains(index) &&
                  !skippedLines.contains(index) else {
                continue
            }

            let trimmed = line.content.trimmingCharacters(in: .whitespaces)
            guard trimmed.isNotEmpty else {
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

    private func violated(_ violations: inout [StyleViolation], _ file: SwiftLintFile, _ line: Int) {
        let content = file.lines[line].content
        let startIndex = content.rangeOfCharacter(from: CharacterSet.whitespaces.inverted)?.lowerBound
                         ?? content.startIndex
        let offset = content.distance(from: content.startIndex, to: startIndex)
        let location = Location(file: file, characterOffset: offset + file.lines[line].range.location)

        violations.append(StyleViolation(ruleDescription: Self.description,
                                         severity: configuration.severity,
                                         location: location))
    }

    private func lineOffsets(file: SwiftLintFile, statement: SourceKittenDictionary) -> (Int, Int)? {
        guard let offset = statement.offset,
              let length = statement.length
        else {
            return nil
        }
        let startLine = file.line(byteOffset: offset)
        let endLine = file.line(byteOffset: offset + length)

        return (startLine, endLine)
    }

    // Collects all the line numbers containing var or let declarations
    private func varLetLineNumbers(file: SwiftLintFile,
                                   structure: [SourceKittenDictionary],
                                   attributeLines: inout Set<Int>,
                                   collectingInto result: inout Set<Int>) {
        for statement in structure {
            guard statement.kind != nil,
                  let (startLine, endLine) = lineOffsets(file: file, statement: statement) else {
                continue
            }

            if let declarationKind = statement.declarationKind {
                if SwiftDeclarationKind.nonVarAttributableKinds.contains(declarationKind) {
                    if attributeLines.contains(startLine) {
                        attributeLines.remove(startLine)
                    }
                }
                if SwiftDeclarationKind.varKinds.contains(declarationKind) {
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
                        let bodyStart = file.line(byteOffset: bodyOffset) + 1
                        let bodyEnd = file.line(byteOffset: bodyOffset + bodyLength) - 1

                        if bodyStart <= bodyEnd {
                            lines.subtract(Set(bodyStart...bodyEnd))
                        }
                    }
                    result.formUnion(lines)
                }
            }

            let substructure = statement.substructure

            if substructure.isNotEmpty {
                varLetLineNumbers(file: file,
                                  structure: substructure,
                                  attributeLines: &attributeLines,
                                  collectingInto: &result)
            }
        }
    }

    // Collects all the line numbers containing comments or #if/#endif
    private func skippedLineNumbers(file: SwiftLintFile) -> Set<Int> {
        var result = Set<Int>()
        let syntaxMap = file.syntaxMap

        for token in syntaxMap.tokens where token.kind == .comment ||
                                            token.kind == .docComment {
            let startLine = file.line(byteOffset: token.offset)
            let endLine = file.line(byteOffset: token.offset + token.length)

            if startLine <= endLine {
                result.formUnion(Set(startLine...endLine))
            }
        }

        let directiveLines = file.lines.filter {
            return regex(#"^\s*#(if|elseif|else|endif|\!|warning|error)"#)
                .firstMatch(in: $0.content, options: [], range: $0.content.fullNSRange) != nil
        }

        result.formUnion(directiveLines.map { $0.index - 1 })
        return result
    }

    // Collects all the line numbers containing attributes but not declarations
    // other than let/var
    private func attributeLineNumbers(file: SwiftLintFile) -> Set<Int> {
        let lineNumbers = file.syntaxMap.tokens
            .filter { isAttribute(token: $0, in: file) }
            .map(\.offset)
            .compactMap(file.line)
        return Set(lineNumbers)
    }

    private func isAttribute(token: SwiftLintSyntaxToken, in file: SwiftLintFile) -> Bool {
        let kind = token.kind
        if kind == .attributeBuiltin {
            return true
        }
        if kind == .typeidentifier, let symbol = file.stringView.substringStartingLinesWithByteRange(token.range) {
            return symbol.trimmingCharacters(in: .whitespaces).starts(with: "@")
        }
        return false
    }
}

private extension SwiftDeclarationKind {
    // The various kinds of let/var declarations
    static let varKinds: [SwiftDeclarationKind] = [.varGlobal, .varClass, .varStatic, .varInstance]
    // Declarations other than let & var that can have attributes
    static let nonVarAttributableKinds: [SwiftDeclarationKind] = [
        .class, .struct,
        .functionFree, .functionSubscript, .functionDestructor, .functionConstructor,
        .functionMethodClass, .functionMethodStatic, .functionMethodInstance,
        .functionOperator, .functionOperatorInfix, .functionOperatorPrefix, .functionOperatorPostfix ]
}

private extension SwiftLintFile {
    // Zero based line number for specified byte offset
    func line(byteOffset: ByteCount) -> Int {
        let lineIndex = lines.firstIndexAssumingSorted { line in
            return line.byteRange.location > byteOffset
        }
        return (lineIndex ?? 0 ) - 1
    }
}
