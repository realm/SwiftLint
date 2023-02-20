import Foundation
import SwiftSyntax

struct NumberSeparatorRule: OptInRule, SwiftSyntaxCorrectableRule, ConfigurationProviderRule {
    var configuration = NumberSeparatorConfiguration(
        minimumLength: 0,
        minimumFractionLength: nil,
        excludeRanges: []
    )

    init() {}

    static let description = RuleDescription(
        identifier: "number_separator",
        name: "Number Separator",
        description: """
            Underscores should be used as thousand separator in large numbers with a configurable number of digits. In \
            other words, there should be an underscore after every 3 digits in the integral as well as the fractional \
            part of a number.
            """,
        kind: .style,
        nonTriggeringExamples: NumberSeparatorRuleExamples.nonTriggeringExamples,
        triggeringExamples: NumberSeparatorRuleExamples.triggeringExamples,
        corrections: NumberSeparatorRuleExamples.corrections
    )

    static let missingSeparatorsReason = """
        Underscores should be used as thousand separators
        """
    static let misplacedSeparatorsReason = """
        Underscore(s) used as thousand separator(s) should be added after every 3 digits only
        """

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(configuration: configuration)
    }

    func makeRewriter(file: SwiftLintFile) -> ViolationsSyntaxRewriter? {
        Rewriter(
            configuration: configuration,
            locationConverter: file.locationConverter,
            disabledRegions: disabledRegions(file: file)
        )
    }
}

private extension NumberSeparatorRule {
    final class Visitor: ViolationsSyntaxVisitor, NumberSeparatorValidator {
        let configuration: NumberSeparatorConfiguration

        init(configuration: NumberSeparatorConfiguration) {
            self.configuration = configuration
            super.init(viewMode: .sourceAccurate)
        }

        override func visitPost(_ node: FloatLiteralExprSyntax) {
            if let violation = violation(token: node.floatingDigits) {
                violations.append(ReasonedRuleViolation(position: violation.position, reason: violation.reason))
            }
        }

        override func visitPost(_ node: IntegerLiteralExprSyntax) {
            if let violation = violation(token: node.digits) {
                violations.append(ReasonedRuleViolation(position: violation.position, reason: violation.reason))
            }
        }
    }

    private final class Rewriter: SyntaxRewriter, ViolationsSyntaxRewriter, NumberSeparatorValidator {
        private(set) var correctionPositions: [AbsolutePosition] = []
        let configuration: NumberSeparatorConfiguration
        let locationConverter: SourceLocationConverter
        let disabledRegions: [SourceRange]

        init(configuration: NumberSeparatorConfiguration,
             locationConverter: SourceLocationConverter,
             disabledRegions: [SourceRange]) {
            self.configuration = configuration
            self.locationConverter = locationConverter
            self.disabledRegions = disabledRegions
        }

        override func visit(_ node: FloatLiteralExprSyntax) -> ExprSyntax {
            guard
                let violation = violation(token: node.floatingDigits),
                !node.isContainedIn(regions: disabledRegions, locationConverter: locationConverter)
            else {
                return super.visit(node)
            }

            let newNode = node.with(\.floatingDigits,
                                    node.floatingDigits.withKind(.floatingLiteral(violation.correction)))
            correctionPositions.append(violation.position)
            return super.visit(newNode)
        }

        override func visit(_ node: IntegerLiteralExprSyntax) -> ExprSyntax {
            guard
                let violation = violation(token: node.digits),
                !node.isContainedIn(regions: disabledRegions, locationConverter: locationConverter)
            else {
                return super.visit(node)
            }

            let newNode = node.with(\.digits, node.digits.withKind(.integerLiteral(violation.correction)))
            correctionPositions.append(violation.position)
            return super.visit(newNode)
        }
    }
}

private protocol NumberSeparatorValidator {
    var configuration: NumberSeparatorConfiguration { get }
}

private enum NumberSeparatorViolation {
    case missingSeparator(position: AbsolutePosition, correction: String)
    case misplacedSeparator(position: AbsolutePosition, correction: String)

    var reason: String {
        switch self {
        case .missingSeparator: return NumberSeparatorRule.missingSeparatorsReason
        case .misplacedSeparator: return NumberSeparatorRule.misplacedSeparatorsReason
        }
    }

    var position: AbsolutePosition {
        switch self {
        case let .missingSeparator(position, _): return position
        case let .misplacedSeparator(position, _): return position
        }
    }

    var correction: String {
        switch self {
        case let .missingSeparator(_, correction): return correction
        case let .misplacedSeparator(_, correction): return correction
        }
    }
}

private extension NumberSeparatorValidator {
    func violation(token: TokenSyntax) -> NumberSeparatorViolation? {
        let content = token.text
        guard isDecimal(number: content),
            !isInValidRanges(number: content)
        else {
            return nil
        }

        let exponential = CharacterSet(charactersIn: "eE")
        guard case let exponentialComponents = content.components(separatedBy: exponential),
            let nonExponential = exponentialComponents.first else {
                return nil
        }

        let components = nonExponential.components(separatedBy: ".")

        var validFraction = true
        var expectedFraction: String?
        if components.count == 2, let fractionSubstring = components.last {
            (validFraction, expectedFraction) = isValid(number: fractionSubstring, isFraction: true)
        }

        guard let integerSubstring = components.first,
            case let (valid, expected) = isValid(number: integerSubstring, isFraction: false),
            !valid || !validFraction
        else {
            return nil
        }

        var corrected = expected
        if let fraction = expectedFraction {
            corrected += "." + fraction
        }

        if exponentialComponents.count == 2, let exponential = exponentialComponents.last {
            let exponentialSymbol = content.contains("e") ? "e" : "E"
            corrected += exponentialSymbol + exponential
        }

        if content.contains("_") {
            return .misplacedSeparator(position: token.positionAfterSkippingLeadingTrivia, correction: corrected)
        }
        return .missingSeparator(position: token.positionAfterSkippingLeadingTrivia, correction: corrected)
    }

    private func isDecimal(number: String) -> Bool {
        let lowercased = number.lowercased()
        let prefixes = ["0x", "0o", "0b"].flatMap { [$0, "-\($0)", "+\($0)"] }

        return !prefixes.contains(where: lowercased.hasPrefix)
    }

    private func isInValidRanges(number: String) -> Bool {
        let doubleValue = Double(number.replacingOccurrences(of: "_", with: ""))
        if let doubleValue, configuration.excludeRanges.contains(where: { $0.contains(doubleValue) }) {
            return true
        }

        return false
    }

    private func isValid(number: String, isFraction: Bool) -> (Bool, String) {
        var correctComponents = [String]()
        let clean = number.replacingOccurrences(of: "_", with: "")

        let minimumLength: Int
        if isFraction {
            minimumLength = configuration.minimumFractionLength ?? .max
        } else {
            minimumLength = configuration.minimumLength
        }

        let shouldAddSeparators = clean.count >= minimumLength

        var numerals = 0
        for char in reversedIfNeeded(clean, reversed: !isFraction) {
            defer { correctComponents.append(String(char)) }
            guard char.unicodeScalars.allSatisfy(CharacterSet.decimalDigits.contains) else { continue }

            if numerals.isMultiple(of: 3) && numerals > 0 && shouldAddSeparators {
                correctComponents.append("_")
            }
            numerals += 1
        }

        let expected = reversedIfNeeded(correctComponents, reversed: !isFraction).joined()
        return (expected == number, expected)
    }

    private func reversedIfNeeded<T>(_ collection: T, reversed: Bool) -> [T.Element] where T: Collection {
        if reversed {
            return collection.reversed()
        }

        return Array(collection)
    }
}
