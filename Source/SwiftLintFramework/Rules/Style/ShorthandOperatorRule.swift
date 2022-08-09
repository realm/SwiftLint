import Foundation
import SourceKittenFramework

public struct ShorthandOperatorRule: ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.error)

    public init() {}

    public static let description = RuleDescription(
        identifier: "shorthand_operator",
        name: "Shorthand Operator",
        description: "Prefer shorthand operators (+=, -=, *=, /=) over doing the operation and assigning.",
        kind: .style,
        nonTriggeringExamples: allOperators.flatMap { operation in
            [
                Example("foo \(operation)= 1"),
                Example("foo \(operation)= variable"),
                Example("foo \(operation)= bar.method()"),
                Example("self.foo = foo \(operation) 1"),
                Example("foo = self.foo \(operation) 1"),
                Example("page = ceilf(currentOffset \(operation) pageWidth)"),
                Example("foo = aMethod(foo \(operation) bar)"),
                Example("foo = aMethod(bar \(operation) foo)")
            ]
        } + [
            Example("var helloWorld = \"world!\"\n helloWorld = \"Hello, \" + helloWorld"),
            Example("angle = someCheck ? angle : -angle"),
            Example("seconds = seconds * 60 + value")
        ],
        triggeringExamples: allOperators.flatMap { operation in
            [
                Example("↓foo = foo \(operation) 1\n"),
                Example("↓foo = foo \(operation) aVariable\n"),
                Example("↓foo = foo \(operation) bar.method()\n"),
                Example("↓foo.aProperty = foo.aProperty \(operation) 1\n"),
                Example("↓self.aProperty = self.aProperty \(operation) 1\n")
            ]
        } + [
            Example("n = n + i / outputLength"),
            Example("n = n - i / outputLength")
//            "d = d * 60 * 60"
        ]
    )

    private static let allOperators = ["-", "/", "+", "*"]

    private static let pattern: String = {
        let escaped = { (operators: [String]) -> String in
            return "[\(operators.map { "\\\($0)" }.joined())]"
        }

        let escapedAll = escaped(allOperators)
        let operatorsWithoutPrecedence = escaped(["-", "+"])
        let operatorsWithPrecedence = escaped(["/", "*"])
        let operand = "[\\w\\d\\.]+?"
        let spaces = "[^\\S\\r\\n]*?"

        let pattern1 = "\(operatorsWithoutPrecedence)"
        let pattern2 = "\(operatorsWithPrecedence)\(spaces)\\S+$"
        return "^\(spaces)(\(operand))\(spaces)=\(spaces)(\\1)\(spaces)(\(pattern1)|\(pattern2))"
    }()

    private static let violationRegex: NSRegularExpression = {
        return regex(pattern, options: [.anchorsMatchLines])
    }()

    public func validate(file: SwiftLintFile) -> [StyleViolation] {
        let contents = file.stringView
        let matches = Self.violationRegex.matches(in: file)

        return matches.compactMap { match -> StyleViolation? in
            // byteRanges will have the ranges of captured groups
            let byteRanges: [ByteRange?] = (1..<match.numberOfRanges).map { rangeIdx in
                let range = match.range(at: rangeIdx)
                guard range.location != NSNotFound else {
                    return nil
                }

                return contents.NSRangeToByteRange(start: range.location, length: range.length)
            }

            guard let byteRange = byteRanges[0] else {
                return nil
            }

            let kindsInCaptureGroups = byteRanges.map { range -> [SyntaxKind] in
                return range.flatMap(file.syntaxMap.kinds(inByteRange:)) ?? []
            }

            guard kindsAreValid(kindsInCaptureGroups[0]) &&
                kindsAreValid(kindsInCaptureGroups[1]) else {
                    return nil
            }

            return StyleViolation(ruleDescription: Self.description,
                                  severity: configuration.severity,
                                  location: Location(file: file, byteOffset: byteRange.location))
        }
    }

    private func kindsAreValid(_ kinds: [SyntaxKind]) -> Bool {
        return Set(kinds).isSubset(of: [.identifier, .keyword])
    }
}
