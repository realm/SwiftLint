import SourceKittenFramework

public struct ControlStatementRule: ConfigurationProviderRule, AutomaticTestableRule, CorrectableRule {

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

    public func validate(file: File) -> [StyleViolation] {
        return violatingControlBracesRanges(file: file)
            .map { match -> StyleViolation in
                return StyleViolation(ruleDescription: type(of: self).description,
                                      severity: configuration.severity,
                                      location: Location(file: file, characterOffset: match.location))
            }
    }

    public func correct(file: File) -> [Correction] {
        let rawRanges = violatingControlBracesRanges(file: file)
        let violatingRanges = file.ruleEnabled(violatingRanges: rawRanges, for: self)
        var correctedContents = file.contents
        var adjustedLocations = [Int]()

        for violatingRange in violatingRanges.reversed() {
            if let indexRange = correctedContents.nsrangeToIndexRange(violatingRange) {

                let text = correctedContents[indexRange]

                if let firstParenIndex = text.index(of: "("),
                    let matches = getMatchingParens(text: text),
                    let lastParenIndex = matches[firstParenIndex] {

                    // After last paren
                    let indexAfter = correctedContents.index(lastParenIndex, offsetBy: 1,
                                                             limitedBy: correctedContents.endIndex)
                    var nextChar: Character? = nil
                    if let after = indexAfter {
                        nextChar = correctedContents[after]
                    }
                    if nextChar == " " {
                        // Remove paren
                        correctedContents.remove(at: lastParenIndex)
                    } else {
                        // Replace paren with space
                        correctedContents.replaceSubrange(lastParenIndex...lastParenIndex, with: " ")
                    }

                    // Before first paren
                    let indexBefore = correctedContents.index(firstParenIndex, offsetBy: -1,
                                                              limitedBy: correctedContents.startIndex)
                    var prevChar: Character? = nil
                    if let before = indexBefore {
                        prevChar = correctedContents[before]
                    }
                    if prevChar == " " {
                        // Remove paren
                        correctedContents.remove(at: firstParenIndex)
                    } else {
                        // Replace paren with space
                        correctedContents.replaceSubrange(firstParenIndex...firstParenIndex, with: " ")
                    }

                }

                adjustedLocations.insert(violatingRange.location, at: 0)
            }
        }

        file.write(correctedContents)

        return adjustedLocations.map {
            Correction(ruleDescription: type(of: self).description,
                       location: Location(file: file, characterOffset: $0))
        }
    }

    fileprivate func getMatchingParens(text: Substring) -> [String.Index: String.Index]? {
        var stack: [String.Index] = []
        var dict: [String.Index: String.Index] = [:]

        for index in text.indices {
            let char = text[index]
            if char == "(" {
                stack.append(index)
            } else if char == ")" {
                if let last = stack.popLast() {
                    dict[last] = index
                } else {
                    return nil
                }
            }
        }
        return dict
    }

    fileprivate func isFalsePositive(_ content: String, syntaxKind: SyntaxKind?) -> Bool {
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

    fileprivate func violatingControlBracesRanges(file: File) -> [NSRange] {
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
                // Filter out false positives
                .filter { match, syntaxKinds -> Bool in
                    let matchString = file.contents.substring(from: match.location, length: match.length)
                    return !isFalsePositive(matchString, syntaxKind: syntaxKinds.first)
                }
                // Filter out call expressions
                .filter { match, _ -> Bool in
                    let contents = file.contents.bridge()
                    guard let byteOffset = contents.NSRangeToByteRange(start: match.location, length: 1)?.location,
                        let outerKind = file.structure.kinds(forByteOffset: byteOffset).last else {
                            return true
                    }
                    return SwiftExpressionKind(rawValue: outerKind.kind) != .call
                }
                .map { match, _ in
                    return match
                }
        }

    }

}
