import Foundation
import SourceKittenFramework

public struct EmptyParenthesesWithTrailingClosureRule: SubstitutionCorrectableASTRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "empty_parentheses_with_trailing_closure",
        name: "Empty Parentheses with Trailing Closure",
        description: "When using trailing closures, empty parentheses should be avoided " +
                     "after the method call.",
        kind: .style,
        nonTriggeringExamples: [
            Example("[1, 2].map { $0 + 1 }\n"),
            Example("[1, 2].map({ $0 + 1 })\n"),
            Example("[1, 2].reduce(0) { $0 + $1 }"),
            Example("[1, 2].map { number in\n number + 1 \n}\n"),
            Example("let isEmpty = [1, 2].isEmpty()\n"),
            Example("""
            UIView.animateWithDuration(0.3, animations: {
               self.disableInteractionRightView.alpha = 0
            }, completion: { _ in
               ()
            })
            """)
        ],
        triggeringExamples: [
            Example("[1, 2].map↓() { $0 + 1 }\n"),
            Example("[1, 2].map↓( ) { $0 + 1 }\n"),
            Example("[1, 2].map↓() { number in\n number + 1 \n}\n"),
            Example("[1, 2].map↓(  ) { number in\n number + 1 \n}\n"),
            Example("func foo() -> [Int] {\n    return [1, 2].map↓() { $0 + 1 }\n}\n")
        ],
        corrections: [
            Example("[1, 2].map↓() { $0 + 1 }\n"): Example("[1, 2].map { $0 + 1 }\n"),
            Example("[1, 2].map↓( ) { $0 + 1 }\n"): Example("[1, 2].map { $0 + 1 }\n"),
            Example("[1, 2].map↓() { number in\n number + 1 \n}\n"):
                Example("[1, 2].map { number in\n number + 1 \n}\n"),
            Example("[1, 2].map↓(  ) { number in\n number + 1 \n}\n"):
                Example("[1, 2].map { number in\n number + 1 \n}\n"),
            Example("func foo() -> [Int] {\n    return [1, 2].map↓() { $0 + 1 }\n}\n"):
                Example("func foo() -> [Int] {\n    return [1, 2].map { $0 + 1 }\n}\n"),
            Example("class C {\n#if true\nfunc f() {\n[1, 2].map↓() { $0 + 1 }\n}\n#endif\n}"):
                Example("class C {\n#if true\nfunc f() {\n[1, 2].map { $0 + 1 }\n}\n#endif\n}")
        ]
    )

    private static let emptyParenthesesRegex = regex("^\\s*\\(\\s*\\)")

    public func validate(file: SwiftLintFile, kind: SwiftExpressionKind,
                         dictionary: SourceKittenDictionary) -> [StyleViolation] {
        return violationRanges(in: file, kind: kind, dictionary: dictionary).map {
            StyleViolation(ruleDescription: Self.description,
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
        if !dictionary.hasTrailingClosure {
            return []
        }

        let rangeStart = nameOffset + nameLength
        let rangeLength = (offset + length) - (nameOffset + nameLength)
        let byteRange = ByteRange(location: rangeStart, length: rangeLength)
        let regex = Self.emptyParenthesesRegex

        guard let range = file.stringView.byteRangeToNSRange(byteRange),
            let match = regex.firstMatch(in: file.contents, options: [], range: range)?.range,
            match.location == range.location
        else {
            return []
        }

        return [match]
    }
}

private extension SourceKittenDictionary {
    var hasTrailingClosure: Bool {
        guard let lastStructure = substructure.last else {
            return false
        }

        if SwiftVersion.current >= .fiveDotSix, lastStructure.expressionKind == .argument {
            return lastStructure.substructure.last?.expressionKind == .closure
        } else {
            return lastStructure.expressionKind == .closure
        }
    }
}
