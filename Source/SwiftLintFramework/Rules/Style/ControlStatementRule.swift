import Foundation
import SourceKittenFramework

struct ControlStatementRule: ConfigurationProviderRule, SubstitutionCorrectableRule {
    var configuration = SeverityConfiguration(.warning)

    init() {}

    static let description = RuleDescription(
        identifier: "control_statement",
        name: "Control Statement",
        description:
            "`if`, `for`, `guard`, `switch`, `while`, and `catch` statements shouldn't unnecessarily wrap their " +
            "conditionals or arguments in parentheses.",
        kind: .style,
        nonTriggeringExamples: [
            Example("if condition {\n"),
            Example("if (a, b) == (0, 1) {\n"),
            Example("if (a || b) && (c || d) {\n"),
            Example("if (min...max).contains(value) {\n"),
            Example("if renderGif(data) {\n"),
            Example("renderGif(data)\n"),
            Example("for item in collection {\n"),
            Example("for (key, value) in dictionary {\n"),
            Example("for (index, value) in enumerate(array) {\n"),
            Example("for var index = 0; index < 42; index++ {\n"),
            Example("guard condition else {\n"),
            Example("while condition {\n"),
            Example("} while condition {\n"),
            Example("do { ; } while condition {\n"),
            Example("switch foo {\n"),
            Example("do {\n} catch let error as NSError {\n}"),
            Example("foo().catch(all: true) {}"),
            Example("if max(a, b) < c {\n"),
            Example("switch (lhs, rhs) {\n")
        ],
        triggeringExamples: [
            Example("↓if (condition) {\n"),
            Example("↓if(condition) {\n"),
            Example("↓if (condition == endIndex) {\n"),
            Example("↓if ((a || b) && (c || d)) {\n"),
            Example("↓if ((min...max).contains(value)) {\n"),
            Example("↓for (item in collection) {\n"),
            Example("↓for (var index = 0; index < 42; index++) {\n"),
            Example("↓for(item in collection) {\n"),
            Example("↓for(var index = 0; index < 42; index++) {\n"),
            Example("↓guard (condition) else {\n"),
            Example("↓while (condition) {\n"),
            Example("↓while(condition) {\n"),
            Example("} ↓while (condition) {\n"),
            Example("} ↓while(condition) {\n"),
            Example("do { ; } ↓while(condition) {\n"),
            Example("do { ; } ↓while (condition) {\n"),
            Example("↓switch (foo) {\n"),
            Example("do {\n} ↓catch(let error as NSError) {\n}"),
            Example("↓if (max(a, b) < c) {\n")
        ],
        corrections: [
            Example("↓if (condition) {\n"): Example("if condition {\n"),
            Example("↓if(condition) {\n"): Example("if condition {\n"),
            Example("↓if (condition == endIndex) {\n"): Example("if condition == endIndex {\n"),
            Example("↓if ((a || b) && (c || d)) {\n"): Example("if (a || b) && (c || d) {\n"),
            Example("↓if ((min...max).contains(value)) {\n"): Example("if (min...max).contains(value) {\n"),
            Example("↓for (item in collection) {\n"): Example("for item in collection {\n"),
            Example("↓for (var index = 0; index < 42; index++) {\n"):
                Example("for var index = 0; index < 42; index++ {\n"),
            Example("↓for(item in collection) {\n"): Example("for item in collection {\n"),
            Example("↓for(var index = 0; index < 42; index++) {\n"):
                Example("for var index = 0; index < 42; index++ {\n"),
            Example("↓guard (condition) else {\n"): Example("guard condition else {\n"),
            Example("↓while (condition) {\n"): Example("while condition {\n"),
            Example("↓while(condition) {\n"): Example("while condition {\n"),
            Example("} ↓while (condition) {\n"): Example("} while condition {\n"),
            Example("} ↓while(condition) {\n"): Example("} while condition {\n"),
            Example("do { ; } ↓while(condition) {\n"): Example("do { ; } while condition {\n"),
            Example("do { ; } ↓while (condition) {\n"): Example("do { ; } while condition {\n"),
            Example("↓switch (foo) {\n"): Example("switch foo {\n"),
            Example("do {\n} ↓catch(let error as NSError) {\n}"): Example("do {\n} catch let error as NSError {\n}"),
            Example("↓if (max(a, b) < c) {\n"): Example("if max(a, b) < c {\n")
        ]
    )

    func validate(file: SwiftLintFile) -> [StyleViolation] {
        return violationRanges(in: file).map { match -> StyleViolation in
            return StyleViolation(ruleDescription: Self.description,
                                  severity: configuration.severity,
                                  location: Location(file: file, characterOffset: match.location))
        }
    }

    func violationRanges(in file: SwiftLintFile) -> [NSRange] {
        let statements = ["if", "for", "guard", "switch", "while", "catch"]
        let statementPatterns: [String] = statements.map { statement -> String in
            let isGuard = statement == "guard"
            let isSwitch = statement == "switch"
            let elsePattern = isGuard ? "else\\s*" : ""
            let clausePattern = isSwitch ? "[^,{]*" : "[^{]*"
            return "\(statement)\\s*\\(\(clausePattern)\\)\\s*\(elsePattern)\\{"
        }
        return statementPatterns.flatMap { pattern -> [NSRange] in
            return file.match(pattern: pattern)
                .filter { match, syntaxKinds -> Bool in
                    let matchString = file.contents.substring(from: match.location, length: match.length)
                    return !isFalsePositive(matchString, syntaxKind: syntaxKinds.first)
                }
                .map { $0.0 }
                .filter { match -> Bool in
                    let contents = file.stringView
                    guard let byteOffset = contents.NSRangeToByteRange(start: match.location, length: 1)?.location,
                        let outerKind = file.structureDictionary.structures(forByteOffset: byteOffset).last else {
                            return true
                    }

                    return outerKind.expressionKind != .call
                }
        }
    }

    func substitution(for violationRange: NSRange, in file: SwiftLintFile) -> (NSRange, String)? {
        var violationString = file.stringView.substring(with: violationRange)
        if violationString.contains("(") && violationString.contains(")") {
            if let openingIndex = violationString.firstIndex(of: "(") {
                let replacement = violationString[violationString.index(before: openingIndex)] == " " ? "" : " "
                violationString.replaceSubrange(openingIndex...openingIndex, with: replacement)
            }
            if let closingIndex = violationString.lastIndex(of: ")" as Character) {
                let replacement = violationString[violationString.index(after: closingIndex)] == " " ? "" : " "
                violationString.replaceSubrange(closingIndex...closingIndex, with: replacement)
            }
        }
        return (violationRange, violationString)
    }

    private func isFalsePositive(_ content: String, syntaxKind: SyntaxKind?) -> Bool {
        if syntaxKind != .keyword {
            return true
        }

        guard let lastClosingParenthesePosition = content.lastIndex(of: ")") else {
            return false
        }

        var depth = 0
        var index = 0
        for char in content {
            if char == ")" {
                if index != lastClosingParenthesePosition && depth == 1 {
                    return true
                }
                depth -= 1
            } else if char == "(" {
                depth += 1
            }
            index += 1
        }
        return false
    }
}
