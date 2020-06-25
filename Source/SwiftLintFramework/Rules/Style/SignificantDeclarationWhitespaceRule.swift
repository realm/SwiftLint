import Foundation
import SourceKittenFramework

public struct SignificantDeclarationWhitespaceRule: ConfigurationProviderRule, OptInRule, AutomaticTestableRule {
    public var configuration = SeverityLevelsConfiguration(warning: 3, error: nil)

    public init() {}

    public static let description = RuleDescription(
        identifier: "significant_declaration_whitespace",
        name: "Significant Declaration Whitespace",
        description: "Significant declarations should be separated from preceding statements by a blank line.",
        kind: .style,
        nonTriggeringExamples: [
            Example("""
            class A {
                var a = 0
                var a = 0
            }

            class A {
                var a = 0
                var a = 0
            }
            """),
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
            Example("@available(OSX, introduced: 10.6)\n@available(*, deprecated)\nvar x = 0\n"),
            Example("""
            // swiftlint:disable superfluous_disable_command
            // swiftlint:disable force_cast

            let x = bar as! Bar
            """),
            Example("var x: Int {\n\tlet a = 0\n\treturn a\n}\n") // don't trigger on local vars
        ],
        triggeringExamples: [
            Example("""
            class A {
                var a = 0
                var a = 0
            }
            ↓class A {
                var a = 0
                var a = 0
            }
            """)
        ]
    )

    public func validate(file: SwiftLintFile) -> [StyleViolation] {
        let dict = file.structureDictionary

        let commentLines = commentsAndAttributes(file: file)

        let varLines = violationsLineNumbers(file: file, commentLines: commentLines, structure: dict.substructure)

        var violations = [StyleViolation]()

        for index in file.lines.indices {
            guard varLines.contains(index) else {
                continue
            }
            violated(&violations, file, index)
        }
        return violations
    }

    private func violated(_ violations: inout [StyleViolation], _ file: SwiftLintFile, _ line: Int) {
        let content = file.lines[line].content
        let startIndex = content.rangeOfCharacter(from: CharacterSet.whitespaces.inverted)?.lowerBound
                         ?? content.startIndex
        let offset = content.distance(from: content.startIndex, to: startIndex)
        let location = Location(file: file, characterOffset: offset + file.lines[line].range.location)

        violations.append(StyleViolation(ruleDescription: Self.description,
                                         severity: .warning,
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

    // Collects all the line numbers containing significant declarations that aren't preceded by blank line
    private func violationsLineNumbers(file: SwiftLintFile,
                                       commentLines: Set<Int>,
                                       structure: [SourceKittenDictionary]) -> [Int] {
        var result = [Int]()
        var previous: ClosedRange<Int>?

        for statement in structure {
            guard let kind = statement.declarationKind,
                  let (startLine, endLine) = lineOffsets(file: file, statement: statement) else {
                continue
            }

            var startLineIncludingLeading = startLine
            while commentLines.contains(startLineIncludingLeading - 1) {
                startLineIncludingLeading -= 1
            }

            if SwiftDeclarationKind.allDeclarations.contains(kind),
               let previous = previous,
               let previousEnd = previous.last,
               abs(startLineIncludingLeading - previousEnd) <= 1,
               (endLine - startLineIncludingLeading) >= configuration.warning {
                result.append(startLineIncludingLeading)
            }

            previous = (startLineIncludingLeading...((endLine < 0) ? file.lines.count : endLine))

            let substructure = statement.substructure

            if SwiftDeclarationKind.bigDeclarations.contains(kind) && !substructure.isEmpty {
                let subResult = violationsLineNumbers(file: file,
                                                      commentLines: commentLines,
                                                      structure: substructure)
                result.append(contentsOf: subResult)
            }
        }

        return result
    }

    // Collects all the line numbers containing comments or #if/#endif or attributes
    private func commentsAndAttributes(file: SwiftLintFile) -> Set<Int> {
        var result = Set<Int>()
        let syntaxMap = file.syntaxMap

        for token in syntaxMap.tokens where token.kind == .comment ||
                                            token.kind == .docComment ||
                                            token.kind == .attributeBuiltin {
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
}

private extension SwiftDeclarationKind {
    // The various kinds of let/var declarations
    static let varKinds: [SwiftDeclarationKind] = [.varClass, .varStatic, .varInstance]
    // The various kinds of func/init declarations
    static let funcKinds: [SwiftDeclarationKind] = [.functionMethodClass, .functionMethodStatic,
                                                    .functionMethodInstance,
                                                    .functionConstructor, .functionDestructor]

    static let bigDeclarations = Set(SwiftDeclarationKind.typeKinds + [.extension])
    static let mediumDeclarations = Set(SwiftDeclarationKind.varKinds + SwiftDeclarationKind.funcKinds)
    static let allDeclarations = bigDeclarations.union(mediumDeclarations)
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
