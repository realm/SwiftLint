import Foundation
import SourceKittenFramework

public struct EmptyParenthesesWithTrailingClosureRule: SubstitutionCorrectableASTRule, ConfigurationProviderRule,
                                                       AutomaticTestableRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "empty_parentheses_with_trailing_closure",
        name: "Empty Parentheses with Trailing Closure",
        description: "When using trailing closures, empty parentheses should be avoided " +
                     "after the method call.",
        kind: .style,
        nonTriggeringExamples: [
            "[1, 2].map { $0 + 1 }\n",
            "[1, 2].map({ $0 + 1 })\n",
            "[1, 2].reduce(0) { $0 + $1 }",
            "[1, 2].map { number in\n number + 1 \n}\n",
            "let isEmpty = [1, 2].isEmpty()\n",
            "UIView.animateWithDuration(0.3, animations: {\n" +
            "   self.disableInteractionRightView.alpha = 0\n" +
            "}, completion: { _ in\n" +
            "   ()\n" +
            "})"
        ],
        triggeringExamples: [
            "[1, 2].map↓() { $0 + 1 }\n",
            "[1, 2].map↓( ) { $0 + 1 }\n",
            "[1, 2].map↓() { number in\n number + 1 \n}\n",
            "[1, 2].map↓(  ) { number in\n number + 1 \n}\n",
            "func foo() -> [Int] {\n    return [1, 2].map↓() { $0 + 1 }\n}\n"
        ],
        corrections: [
            "[1, 2].map↓() { $0 + 1 }\n": "[1, 2].map { $0 + 1 }\n",
            "[1, 2].map↓( ) { $0 + 1 }\n": "[1, 2].map { $0 + 1 }\n",
            "[1, 2].map↓() { number in\n number + 1 \n}\n": "[1, 2].map { number in\n number + 1 \n}\n",
            "[1, 2].map↓(  ) { number in\n number + 1 \n}\n": "[1, 2].map { number in\n number + 1 \n}\n",
            "func foo() -> [Int] {\n    return [1, 2].map↓() { $0 + 1 }\n}\n":
                "func foo() -> [Int] {\n    return [1, 2].map { $0 + 1 }\n}\n",
            "class C {\n#if true\nfunc f() {\n[1, 2].map↓() { $0 + 1 }\n}\n#endif\n}":
                "class C {\n#if true\nfunc f() {\n[1, 2].map { $0 + 1 }\n}\n#endif\n}"
        ]
    )

    private static let emptyParenthesesRegex = regex("^\\s*\\(\\s*\\)")

    public func validate(file: SwiftLintFile, kind: SwiftExpressionKind,
                         dictionary: SourceKittenDictionary) -> [StyleViolation] {
        return violationRanges(in: file, kind: kind, dictionary: dictionary).map {
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severity,
                           location: Location(file: file, characterOffset: $0.location))
        }
    }

    public func substitution(for violationRange: NSRange, in file: SwiftLintFile) -> (NSRange, String)? {
        return (violationRange, "")
    }

    public func violationRanges(in file: SwiftLintFile, kind: SwiftExpressionKind,
                                dictionary: SourceKittenDictionary) -> [NSRange] {
        guard kind == .call else {
            return []
        }

        guard let offset = dictionary.offset,
            let length = dictionary.length,
            let nameOffset = dictionary.nameOffset,
            let nameLength = dictionary.nameLength,
            let bodyLength = dictionary.bodyLength,
            bodyLength > 0 else {
                return []
        }

        // avoid the more expensive regex match if there's no trailing closure in the substructure
        if SwiftVersion.current >= .fourDotTwo,
            dictionary.substructure.last?.expressionKind != .closure {
            return []
        }

        let rangeStart = nameOffset + nameLength
        let rangeLength = (offset + length) - (nameOffset + nameLength)
        let regex = EmptyParenthesesWithTrailingClosureRule.emptyParenthesesRegex

        guard let range = file.stringView.byteRangeToNSRange(start: rangeStart, length: rangeLength),
            let match = regex.firstMatch(in: file.contents, options: [], range: range)?.range,
            match.location == range.location else {
                return []
        }

        return [match]
    }
}
