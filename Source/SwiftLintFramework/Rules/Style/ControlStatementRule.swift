import Foundation
import SourceKittenFramework

public struct ControlStatementRule: ConfigurationProviderRule, AutomaticTestableRule, SubstitutionCorrectableRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "control_statement",
        name: "Control Statement",
        description:
            "`if`, `for`, `guard`, `switch`, `while`, and `catch` statements shouldn't unnecessarily wrap their " +
            "conditionals or arguments in parentheses.",
        kind: .style,
        nonTriggeringExamples: [
            "if condition {\n",
            "if (a, b) == (0, 1) {\n",
            "if (a || b) && (c || d) {\n",
            "if (min...max).contains(value) {\n",
            "if renderGif(data) {\n",
            "renderGif(data)\n",
            "for item in collection {\n",
            "for (key, value) in dictionary {\n",
            "for (index, value) in enumerate(array) {\n",
            "for var index = 0; index < 42; index++ {\n",
            "guard condition else {\n",
            "while condition {\n",
            "} while condition {\n",
            "do { ; } while condition {\n",
            "switch foo {\n",
            "do {\n} catch let error as NSError {\n}",
            "foo().catch(all: true) {}",
            "if max(a, b) < c {\n",
            "switch (lhs, rhs) {\n"
        ],
        triggeringExamples: [
            "↓if (condition) {\n",
            "↓if(condition) {\n",
            "↓if (condition == endIndex) {\n",
            "↓if ((a || b) && (c || d)) {\n",
            "↓if ((min...max).contains(value)) {\n",
            "↓for (item in collection) {\n",
            "↓for (var index = 0; index < 42; index++) {\n",
            "↓for(item in collection) {\n",
            "↓for(var index = 0; index < 42; index++) {\n",
            "↓guard (condition) else {\n",
            "↓while (condition) {\n",
            "↓while(condition) {\n",
            "} ↓while (condition) {\n",
            "} ↓while(condition) {\n",
            "do { ; } ↓while(condition) {\n",
            "do { ; } ↓while (condition) {\n",
            "↓switch (foo) {\n",
            "do {\n} ↓catch(let error as NSError) {\n}",
            "↓if (max(a, b) < c) {\n"
        ],
        corrections: [
            "↓if (condition) {\n": "if condition {\n",
            "↓if(condition) {\n": "if condition {\n",
            "↓if (condition == endIndex) {\n": "if condition == endIndex {\n",
            "↓if ((a || b) && (c || d)) {\n": "if (a || b) && (c || d) {\n",
            "↓if ((min...max).contains(value)) {\n": "if (min...max).contains(value) {\n",
            "↓for (item in collection) {\n": "for item in collection {\n",
            "↓for (var index = 0; index < 42; index++) {\n": "for var index = 0; index < 42; index++ {\n",
            "↓for(item in collection) {\n": "for item in collection {\n",
            "↓for(var index = 0; index < 42; index++) {\n": "for var index = 0; index < 42; index++ {\n",
            "↓guard (condition) else {\n": "guard condition else {\n",
            "↓while (condition) {\n": "while condition {\n",
            "↓while(condition) {\n": "while condition {\n",
            "} ↓while (condition) {\n": "} while condition {\n",
            "} ↓while(condition) {\n": "} while condition {\n",
            "do { ; } ↓while(condition) {\n": "do { ; } while condition {\n",
            "do { ; } ↓while (condition) {\n": "do { ; } while condition {\n",
            "↓switch (foo) {\n": "switch foo {\n",
            "do {\n} ↓catch(let error as NSError) {\n}": "do {\n} catch let error as NSError {\n}",
            "↓if (max(a, b) < c) {\n": "if max(a, b) < c {\n"
        ]
    )

    public func validate(file: SwiftLintFile) -> [StyleViolation] {
        return violationRanges(in: file).map { match -> StyleViolation in
            return StyleViolation(ruleDescription: type(of: self).description,
                                  severity: configuration.severity,
                                  location: Location(file: file, characterOffset: match.location))
        }
    }

    public func violationRanges(in file: SwiftLintFile) -> [NSRange] {
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
                    let contents = file.linesContainer
                    guard let byteOffset = contents.NSRangeToByteRange(start: match.location, length: 1)?.location,
                        let outerKind = file.structureDictionary.structures(forByteOffset: byteOffset).last else {
                            return true
                    }

                    return outerKind.expressionKind != .call
                }
        }
    }

    public func substitution(for violationRange: NSRange, in file: SwiftLintFile) -> (NSRange, String) {
        var violationString = file.linesContainer.substring(with: violationRange)
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
