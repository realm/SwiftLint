import Foundation
import SourceKittenFramework
import SwiftSyntax

struct SyntacticSugarRule: CorrectableRule, SourceKitFreeRule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "syntactic_sugar",
        name: "Syntactic Sugar",
        description: "Shorthand syntactic sugar should be used, i.e. [Int] instead of Array<Int>.",
        kind: .idiomatic,
        nonTriggeringExamples: SyntacticSugarRuleExamples.nonTriggering,
        triggeringExamples: SyntacticSugarRuleExamples.triggering,
        corrections: SyntacticSugarRuleExamples.corrections
    )

    func validate(file: SwiftLintFile) -> [StyleViolation] {
        let visitor = SyntacticSugarRuleVisitor(viewMode: .sourceAccurate)
        return visitor.walk(file: file) { visitor in
            flattenViolations(visitor.violations)
        }.map { violation in
            StyleViolation(ruleDescription: Self.description,
                           severity: configuration.severity,
                           location: Location(file: file, byteOffset: ByteCount(violation.position)),
                           reason: violation.type.violationReason)
        }
    }

    private func flattenViolations(_ violations: [SyntacticSugarRuleViolation]) -> [SyntacticSugarRuleViolation] {
        violations.flatMap { [$0] + flattenViolations($0.children) }
    }

    func correct(file: SwiftLintFile) -> [Correction] {
        let visitor = SyntacticSugarRuleVisitor(viewMode: .sourceAccurate)
        return visitor.walk(file: file) { visitor in
            var context = CorrectingContext(rule: self, file: file, contents: file.contents)
            context.correctViolations(visitor.violations)

            file.write(context.contents)

            return context.corrections
        }
    }
}

// MARK: - Private

private enum SugaredType: String {
    case optional = "Optional"
    case array = "Array"
    case dictionary = "Dictionary"

    init?(typeName: String) {
        var typeName = typeName
        if typeName.hasPrefix("Swift.") {
            typeName.removeFirst("Swift.".count)
        }

        self.init(rawValue: typeName)
    }

    var sugaredExample: String {
        switch self {
        case .optional:
            return "Int?"
        case .array:
            return "[Int]"
        case .dictionary:
            return "[String: Int]"
        }
    }

    var desugaredExample: String {
        switch self {
        case .optional, .array:
            return "\(rawValue)<Int>"
        case .dictionary:
            return "\(rawValue)<String, Int>"
        }
    }

    var violationReason: String {
        "Shorthand syntactic sugar should be used, i.e. \(sugaredExample) instead of \(desugaredExample)"
    }
}

private struct SyntacticSugarRuleViolation {
    struct Correction {
        let typeStart: AbsolutePosition
        let correction: CorrectionType

        let leftStart: AbsolutePosition
        let leftEnd: AbsolutePosition

        let rightStart: AbsolutePosition
        let rightEnd: AbsolutePosition
    }
    enum CorrectionType {
        case optional
        case dictionary(commaStart: AbsolutePosition, commaEnd: AbsolutePosition)
        case array
    }

    let position: AbsolutePosition
    let type: SugaredType

    let correction: Correction

    var children: [Self] = []
}

private final class SyntacticSugarRuleVisitor: SyntaxVisitor {
    var violations: [SyntacticSugarRuleViolation] = []

    override func visitPost(_ node: TypeAnnotationSyntax) {
        // let x: ↓Swift.Optional<String>
        // let x: ↓Optional<String>
        if let violation = violation(in: node.type) {
            violations.append(violation)
        }
    }

    override func visitPost(_ node: FunctionParameterSyntax) {
        // func x(a: ↓Array<Int>, b: Int) -> [Int: Any]
        if let violation = violation(in: node.type) {
            violations.append(violation)
        }
    }

    override func visitPost(_ node: ReturnClauseSyntax) {
        // func x(a: [Int], b: Int) -> ↓Dictionary<Int, String>
        if let violation = violation(in: node.type) {
            violations.append(violation)
        }
    }

    override func visitPost(_ node: TypeInitializerClauseSyntax) {
        // typealias Document = ↓Dictionary<String, AnyBSON?>
        if let violation = violation(in: node.value) {
            violations.append(violation)
        }
    }

    override func visitPost(_ node: AttributedTypeSyntax) {
        // func x(_ y: inout ↓Array<T>)
        if let violation = violation(in: node.baseType) {
            violations.append(violation)
        }
    }

    override func visitPost(_ node: SameTypeRequirementSyntax) {
        // @_specialize(where S == ↓Array<Character>)
        if let violation = violation(in: node.leftType) {
            violations.append(violation)
        }
        if let violation = violation(in: node.rightType) {
            violations.append(violation)
        }
    }

    override func visitPost(_ node: GenericSpecializationExprSyntax) {
        // let x = ↓Array<String>.array(of: object)
        // Skip checks for 'self' or \T Dictionary<Key, Value>.self
        if let parent = node.parent?.as(MemberAccessExprSyntax.self),
           let lastToken = Array(parent.tokens(viewMode: .sourceAccurate)).last?.tokenKind,
           [.keyword(.self), .identifier("Type"), .identifier("none"), .identifier("Index")].contains(lastToken) {
            return
        }

        let typeName = node.expression.trimmedDescription

        if SugaredType(typeName: typeName) != nil {
            if let violation = violation(from: node) {
                violations.append(violation)
            }
            return
        }

        // If there's no type, check all inner generics like in the case of 'Box<Array<T>>'
        node.genericArgumentClause.arguments
            .lazy
            .compactMap { self.violation(in: $0.argument) }
            .first
            .map { violations.append($0) }
    }

    override func visitPost(_ node: TypeExprSyntax) {
        if let violation = violation(in: node.type) {
            violations.append(violation)
        }
    }

    private func violation(in typeSyntax: TypeSyntax?) -> SyntacticSugarRuleViolation? {
        if let optionalType = typeSyntax?.as(OptionalTypeSyntax.self) {
            return violation(in: optionalType.wrappedType)
        }

        if let simpleType = typeSyntax?.as(IdentifierTypeSyntax.self) {
            if SugaredType(typeName: simpleType.name.text) != nil {
                return violation(from: simpleType)
            }

            // If there's no type, check all inner generics like in the case of 'Box<Array<T>>'
            guard let genericArguments = simpleType.genericArgumentClause else { return nil }
            let innerTypes = genericArguments.arguments.compactMap { violation(in: $0.argument) }
            return innerTypes.first
        }

        // Base class is "Swift" for cases like "Swift.Array"
        if let memberType = typeSyntax?.as(MemberTypeSyntax.self),
           let baseType = memberType.baseType.as(IdentifierTypeSyntax.self),
           baseType.name.text == "Swift" {
            guard SugaredType(typeName: memberType.name.text) != nil else { return nil }
            return violation(from: memberType)
        }
        return nil
    }

    private func violation(from node: some SyntaxProtocol & SyntaxWithGenericClause) -> SyntacticSugarRuleViolation? {
        guard
            let generic = node.genericArguments,
            let firstGenericType = generic.arguments.first,
            let lastGenericType = generic.arguments.last,
            let typeName = node.typeName,
            let type = SugaredType(typeName: typeName)
        else { return nil }

        let correctionType: SyntacticSugarRuleViolation.CorrectionType
        switch type {
        case .optional:
            correctionType = .optional
        case .array:
            correctionType = .array
        case .dictionary:
            guard let comma = firstGenericType.trailingComma else { return nil }
            let lastArgumentEnd = firstGenericType.argument.endPositionBeforeTrailingTrivia
            correctionType = .dictionary(commaStart: lastArgumentEnd, commaEnd: comma.endPosition)
        }

        let firstInnerViolation = violation(in: firstGenericType.argument)
        let secondInnerViolation = generic.arguments.count > 1 ? violation(in: lastGenericType.argument) : nil

        return SyntacticSugarRuleViolation(
            position: node.positionAfterSkippingLeadingTrivia,
            type: type,
            correction: .init(typeStart: node.position,
                              correction: correctionType,
                              leftStart: generic.leftAngle.position,
                              leftEnd: generic.leftAngle.endPosition,
                              rightStart: lastGenericType.endPositionBeforeTrailingTrivia,
                              rightEnd: generic.rightAngle.endPositionBeforeTrailingTrivia),
            children: [firstInnerViolation, secondInnerViolation].compactMap { $0 }
        )
    }
}

private struct CorrectingContext<R: Rule> {
    let rule: R
    let file: SwiftLintFile
    var contents: String
    var corrections: [Correction] = []

    mutating func correctViolations(_ violations: [SyntacticSugarRuleViolation]) {
        let sortedVolations = violations.sorted(by: { $0.correction.typeStart > $1.correction.typeStart })
        for violation in sortedVolations {
            correctViolation(violation)
        }
    }

    mutating func correctViolation(_ violation: SyntacticSugarRuleViolation) {
        let stringView = file.stringView
        let correction = violation.correction

        guard let violationNSRange = stringView.NSRange(start: correction.leftStart, end: correction.rightEnd),
              file.ruleEnabled(violatingRange: violationNSRange, for: rule) != nil else { return }

        guard let rightRange = stringView.NSRange(start: correction.rightStart, end: correction.rightEnd),
              let leftRange = stringView.NSRange(start: correction.typeStart, end: correction.leftEnd) else {
            return
        }

        switch correction.correction {
        case .array:
            replaceCharacters(in: rightRange, with: "]")
            correctViolations(violation.children)
            replaceCharacters(in: leftRange, with: "[")

        case let .dictionary(commaStart, commaEnd):

            replaceCharacters(in: rightRange, with: "]")
            guard let commaRange = stringView.NSRange(start: commaStart, end: commaEnd) else { return }

            let violationsAfterComma = violation.children.filter { $0.position > commaStart }
            correctViolations(violationsAfterComma)

            replaceCharacters(in: commaRange, with: ": ")

            let violationsBeforeComma = violation.children.filter { $0.position < commaStart }
            correctViolations(violationsBeforeComma)
            replaceCharacters(in: leftRange, with: "[")

        case .optional where typeIsOpaqueOrExistential(correction: correction):
            replaceCharacters(in: rightRange, with: ")?")
            correctViolations(violation.children)
            replaceCharacters(in: leftRange, with: "(")
        case .optional:
            replaceCharacters(in: rightRange, with: "?")
            correctViolations(violation.children)
            replaceCharacters(in: leftRange, with: "")
        }

        let location = Location(file: file, byteOffset: ByteCount(correction.typeStart))
        corrections.append(Correction(ruleDescription: type(of: rule).description, location: location))
    }

    private func typeIsOpaqueOrExistential(correction: SyntacticSugarRuleViolation.Correction) -> Bool {
        if let innerTypeRange = file.stringView.NSRange(start: correction.leftEnd, end: correction.rightStart) {
            let innerTypeString = file.stringView.substring(with: innerTypeRange)
            return innerTypeString.contains("any ") || innerTypeString.contains("some ")
        }
        return false
    }

    private mutating func replaceCharacters(in range: NSRange, with replacement: String) {
        contents = contents.bridge().replacingCharacters(in: range, with: replacement)
    }
}

private protocol SyntaxWithGenericClause {
    var typeName: String? { get }
    var genericArguments: GenericArgumentClauseSyntax? { get }
}

extension MemberTypeSyntax: SyntaxWithGenericClause {
    var typeName: String? { name.text }
    var genericArguments: GenericArgumentClauseSyntax? { genericArgumentClause }
}

extension IdentifierTypeSyntax: SyntaxWithGenericClause {
    var typeName: String? { name.text }
    var genericArguments: GenericArgumentClauseSyntax? { genericArgumentClause }
}

extension GenericSpecializationExprSyntax: SyntaxWithGenericClause {
    var typeName: String? {
        expression.as(DeclReferenceExprSyntax.self)?.firstToken(viewMode: .sourceAccurate)?.text ??
        expression.as(MemberAccessExprSyntax.self)?.declName.baseName.text
    }
    var genericArguments: GenericArgumentClauseSyntax? { genericArgumentClause }
}
