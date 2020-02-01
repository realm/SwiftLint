import Foundation
import SourceKittenFramework

public struct NoSpaceInMethodCallRule: SubstitutionCorrectableASTRule, ConfigurationProviderRule,
                                       AutomaticTestableRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "no_space_in_method_call",
        name: "No Space in Method Call",
        description: "Don't add a space between the method name and the parentheses.",
        kind: .style,
        minSwiftVersion: .fourDotTwo,
        nonTriggeringExamples: [
            Example("foo()"),
            Example("object.foo()"),
            Example("object.foo(1)"),
            Example("object.foo(value: 1)"),
            Example("object.foo { print($0 }"),
            Example("list.sorted { $0.0 < $1.0 }.map { $0.value }"),
            Example("self.init(rgb: (Int) (colorInt))")
        ],
        triggeringExamples: [
            Example("foo↓ ()"),
            Example("object.foo↓ ()"),
            Example("object.foo↓ (1)"),
            Example("object.foo↓ (value: 1)"),
            Example("object.foo↓ () {}"),
            Example("object.foo↓     ()")
        ],
        corrections: [
            Example("foo↓ ()"): Example("foo()"),
            Example("object.foo↓ ()"): Example("object.foo()"),
            Example("object.foo↓ (1)"): Example("object.foo(1)"),
            Example("object.foo↓ (value: 1)"): Example("object.foo(value: 1)"),
            Example("object.foo↓ () {}"): Example("object.foo() {}"),
            Example("object.foo↓     ()"): Example("object.foo()")
        ]
    )

    // MARK: - ASTRule

    public func validate(file: SwiftLintFile,
                         kind: SwiftExpressionKind,
                         dictionary: SourceKittenDictionary) -> [StyleViolation] {
        return violationRanges(in: file, kind: kind, dictionary: dictionary).map {
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severity,
                           location: Location(file: file, characterOffset: $0.location))
        }
    }

    // MARK: - SubstitutionCorrectableASTRule

    public func substitution(for violationRange: NSRange, in file: SwiftLintFile) -> (NSRange, String)? {
        return (violationRange, "")
    }

    public func violationRanges(in file: SwiftLintFile,
                                kind: SwiftExpressionKind,
                                dictionary: SourceKittenDictionary) -> [NSRange] {
        guard kind == .call,
            let bodyOffset = dictionary.bodyOffset,
            let nameOffset = dictionary.nameOffset,
            let nameLength = dictionary.nameLength,
            nameLength > 0,
            case let nameEndPosition = nameOffset + nameLength,
            bodyOffset != nameEndPosition + 1,
            case let contents = file.stringView,
            case let byteRange = ByteRange(location: nameEndPosition, length: bodyOffset - nameEndPosition - 1),
            let range = contents.byteRangeToNSRange(byteRange)
        else {
            return []
        }

        // Don't trigger if it's a single parameter trailing closure without parens
        if let subDict = dictionary.substructure.last,
            subDict.expressionKind == .closure,
            let closureBodyOffset = subDict.bodyOffset,
            closureBodyOffset == bodyOffset {
            return []
        }

        // Don't trigger if it's a typecast
        if let name = dictionary.name, name.hasPrefix("("), name.hasSuffix(")") {
            return []
        }

        return [range]
    }
}
