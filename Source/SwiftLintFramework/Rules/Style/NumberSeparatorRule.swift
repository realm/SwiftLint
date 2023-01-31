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
        description: "Underscores should be used as thousand separator in large decimal numbers",
        kind: .style,
        nonTriggeringExamples: NumberSeparatorRuleExamples.nonTriggeringExamples,
        triggeringExamples: NumberSeparatorRuleExamples.triggeringExamples,
        corrections: NumberSeparatorRuleExamples.corrections
    )

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
                violations.append(violation.position)
            }
        }

        override func visitPost(_ node: IntegerLiteralExprSyntax) {
            if let violation = violation(token: node.digits) {
                violations.append(violation.position)
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

            let newNode = node.withFloatingDigits(node.floatingDigits.withKind(.floatingLiteral(violation.correction)))
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

            let newNode = node.withDigits(node.digits.withKind(.integerLiteral(violation.correction)))
            correctionPositions.append(violation.position)
            return super.visit(newNode)
        }
    }
}

private protocol NumberSeparatorValidator {
    var configuration: NumberSeparatorConfiguration { get }
}

extension NumberSeparatorValidator {
    func violation(token: TokenSyntax) -> (position: AbsolutePosition, correction: String)? {
        let content = token.withoutTrivia().text
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
            let result = isValid(number: fractionSubstring, isFraction: true)
            validFraction = result.0
            expectedFraction = result.1
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

        return (token.positionAfterSkippingLeadingTrivia, corrected)
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
