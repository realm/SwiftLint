import Foundation
import SourceKittenFramework

public struct PreferZeroOverExplicitInitRule: OptInRule, ConfigurationProviderRule, SubstitutionCorrectableRule {
    public var configuration = SeverityConfiguration(.warning)
    private var pattern: String {
        let zero = "\\s*:\\s*0(\\.0*)?\\s*"
        let type = "(\(["CGPoint", "CGSize", "CGVector", "CGRect", "UIEdgeInsets"].joined(separator: "|")))"
        let firstArg = "(\(["x", "dx", "width", "top"].joined(separator: "|")))"
        let secondArg = "(\(["y", "dy", "height", "left"].joined(separator: "|")))"
        let thirdAndFourthArg: String = {
            let thirdArg = "(\(["width", "bottom"].joined(separator: "|")))"
            let fourthArg = "(\(["height", "right"].joined(separator: "|")))"
            return "(\\,\\s*\(thirdArg)\(zero)\\,\\s*\(fourthArg)\(zero))?"
        }()
        return "\(type)\\(\\s*\(firstArg)\(zero)\\,\\s*\(secondArg)\(zero)\(thirdAndFourthArg)\\)"
    }

    public static let description = RuleDescription(
        identifier: "prefer_zero_over_explicit_init",
        name: "Prefer Zero Over Explicit Init",
        description: "Prefer `.zero` over explicit init with zero parameters (e.g. `CGPoint(x: 0, y: 0)`)",
        kind: .idiomatic,
        nonTriggeringExamples: [
            Example("CGRect(x: 0, y: 0, width: 0, height: 1)"),
            Example("CGPoint(x: 0, y: -1)"),
            Example("CGSize(width: 2, height: 4)"),
            Example("CGVector(dx: -5, dy: 0)"),
            Example("UIEdgeInsets(top: 0, left: 1, bottom: 0, right: 1)")
        ],
        triggeringExamples: [
            Example("↓CGPoint(x: 0, y: 0)"),
            Example("↓CGPoint(x: 0.000000, y: 0)"),
            Example("↓CGPoint(x: 0.000000, y: 0.000)"),
            Example("↓CGRect(x: 0, y: 0, width: 0, height: 0)"),
            Example("↓CGSize(width: 0, height: 0)"),
            Example("↓CGVector(dx: 0, dy: 0)"),
            Example("↓UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)")
        ],
        corrections: [
            Example("↓CGPoint(x: 0, y: 0)"): Example("CGPoint.zero"),
            Example("(↓CGPoint(x: 0, y: 0))"): Example("(CGPoint.zero)"),
            Example("↓CGRect(x: 0, y: 0, width: 0, height: 0)"): Example("CGRect.zero"),
            Example("↓CGSize(width: 0, height: 0.000)"): Example("CGSize.zero"),
            Example("↓CGVector(dx: 0, dy: 0)"): Example("CGVector.zero"),
            Example("↓UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)"): Example("UIEdgeInsets.zero")
        ]
    )

    public init() {}

    public func validate(file: SwiftLintFile) -> [StyleViolation] {
        violationRanges(in: file).map {
            StyleViolation(
                ruleDescription: Self.description,
                severity: configuration.severity,
                location: Location(file: file, characterOffset: $0.location)
            )
        }
    }

    public func violationRanges(in file: SwiftLintFile) -> [NSRange] {
        return file.matchesAndSyntaxKinds(matching: pattern)
            .filter {
                $0.1 == [.identifier, .identifier, .number, .identifier, .number] ||
                $0.1 == [
                    .identifier, .identifier, .number, .identifier, .number, .identifier, .number, .identifier, .number
                ]
            }
            .map { $0.0.range(at: 0) }
    }

    public func substitution(for violationRange: NSRange, in file: SwiftLintFile) -> (NSRange, String)? {
        let declaration = file.stringView.substring(with: violationRange)
        guard let typeEndIndex = declaration.firstIndex(of: "(") else { return nil }
        return (violationRange, "\(declaration.prefix(upTo: typeEndIndex)).zero")
    }
}
