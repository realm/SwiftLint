// swiftlint:disable file_length
import Foundation
import SourceKittenFramework
import SwiftSyntax

private let warnSyntaxParserFailureOnceImpl: Void = {
    queuedPrintError("The syntactic_sugar rule is disabled because the Swift Syntax tree could not be parsed")
}()

private func warnSyntaxParserFailureOnce() {
    _ = warnSyntaxParserFailureOnceImpl
}

public struct SyntacticSugarRule: CorrectableRule, ConfigurationProviderRule, AutomaticTestableRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "syntactic_sugar",
        name: "Syntactic Sugar",
        description: "Shorthand syntactic sugar should be used, i.e. [Int] instead of Array<Int>.",
        kind: .idiomatic,
        nonTriggeringExamples: [
            Example("let x: [Int]"),
            Example("let x: [Int: String]"),
            Example("let x: Int?"),
            Example("func x(a: [Int], b: Int) -> [Int: Any]"),
            Example("let x: Int!"),
            Example("""
            extension Array {
              func x() { }
            }
            """),
            Example("""
            extension Dictionary {
              func x() { }
            }
            """),
            Example("let x: CustomArray<String>"),
            Example("var currentIndex: Array<OnboardingPage>.Index?"),
            Example("func x(a: [Int], b: Int) -> Array<Int>.Index"),
            Example("unsafeBitCast(nonOptionalT, to: Optional<T>.self)"),
            Example("unsafeBitCast(someType, to: Swift.Array<T>.self)"),
            Example("IndexingIterator<Array<Dictionary<String, AnyObject>>>.self"),
            Example("let y = Optional<String>.Type"),

            Example("type is Optional<String>.Type"),
            Example("let x: Foo.Optional<String>"),

            Example("let x = case Optional<Any>.none = obj"),
            Example("let a = Swift.Optional<String?>.none")
        ],
        triggeringExamples: [
            Example("let x: ↓Array<String>"),
            Example("let x: ↓Dictionary<Int, String>"),
            Example("let x: ↓Optional<Int>"),
            Example("let x: ↓ImplicitlyUnwrappedOptional<Int>"),
            Example("let x: ↓Swift.Array<String>"),

            Example("func x(a: ↓Array<Int>, b: Int) -> [Int: Any]"),
            Example("func x(a: ↓Swift.Array<Int>, b: Int) -> [Int: Any]"),

            Example("func x(a: [Int], b: Int) -> ↓Dictionary<Int, String>"),
            Example("let x = y as? ↓Array<[String: Any]>"),
            Example("let x = Box<Array<T>>()"),
            Example("func x() -> Box<↓Array<T>>"),
            Example("func x() -> ↓Dictionary<String, Any>?"),

            Example("typealias Document = ↓Dictionary<String, T?>"),
            Example("func x(_ y: inout ↓Array<T>)"),
            Example("let x:↓Dictionary<String, ↓Dictionary<Int, Int>>"),
            Example("func x() -> Any { return ↓Dictionary<Int, String>()}"),

            Example("let x = ↓Array<String>.array(of: object)"),
            Example("let x = ↓Swift.Array<String>.array(of: object)"),

            Example("""
            @_specialize(where S == ↓Array<Character>)
            public init<S: Sequence>(_ elements: S)
            """)
        ],
        corrections: [
            Example("let x: Array<String>"): Example("let x: [String]"),
            Example("let x: Array< String >"): Example("let x: [String]"),
            Example("let x: Dictionary<Int, String>"): Example("let x: [Int: String]"),
            Example("let x: Optional<Int>"): Example("let x: Int?"),
            Example("let x: Optional< Int >"): Example("let x: Int?"),
            Example("let x: ImplicitlyUnwrappedOptional<Int>"): Example("let x: Int!"),
            Example("let x: ImplicitlyUnwrappedOptional< Int >"): Example("let x: Int!"),

            Example("let x: Dictionary<Int , String>"): Example("let x: [Int: String]"),
            Example("let x: Swift.Optional<String>"): Example("let x: String?"),
            Example("let x:↓Dictionary<String, ↓Dictionary<Int, Int>>"): Example("let x:[String: [Int: Int]]"),
            Example("let x:↓Dictionary<↓Dictionary<Int, Int>, String>"): Example("let x:[[Int: Int]: String]"),
            Example("let x:↓Dictionary<↓Dictionary<↓Dictionary<Int, Int>, Int>, String>"):
                Example("let x:[[[Int: Int]: Int]: String]"),
            Example("let x:↓Array<↓Dictionary<Int, Int>>"): Example("let x:[[Int: Int]]"),
            Example("let x:↓Optional<↓Dictionary<Int, Int>>"): Example("let x:[Int: Int]?"),
            Example("let x:↓ImplicitlyUnwrappedOptional<↓Dictionary<Int, Int>>"): Example("let x:[Int: Int]!")
        ]
    )

    public func validate(file: SwiftLintFile) -> [StyleViolation] {
        guard let tree = file.syntaxTree else {
            warnSyntaxParserFailureOnce()
            return []
        }
        let visitor = SyntacticSugarRuleVisitor()
        visitor.walk(tree)

        let allViolations = flattenViolations(visitor.violations)
        return allViolations.map { violation in
            return StyleViolation(ruleDescription: Self.description,
                                  severity: configuration.severity,
                                  location: Location(file: file, byteOffset: ByteCount(violation.position.utf8Offset)),
                                  reason: message(for: violation.type))
        }
    }

    private func flattenViolations(_ violations: [SyntacticSugarRuleViolation]) -> [SyntacticSugarRuleViolation] {
        return violations.flatMap { [$0] + flattenViolations($0.children) }
    }

    public func correct(file: SwiftLintFile) -> [Correction] {
        guard let tree = file.syntaxTree else {
            warnSyntaxParserFailureOnce()
            return []
        }
        let visitor = SyntacticSugarRuleVisitor()
        visitor.walk(tree)

        var context = CorrectingContex(rule: self, file: file, contents: file.contents)
        context.correctViolations(visitor.violations)

        file.write(context.contents)

        return context.corrections
    }

    private func message(for originalType: String) -> String {
        let typeString: String
        let sugaredType: String

        switch originalType {
        case "Optional":
            typeString = "Optional<Int>"
            sugaredType = "Int?"
        case "ImplicitlyUnwrappedOptional":
            typeString = "ImplicitlyUnwrappedOptional<Int>"
            sugaredType = "Int!"
        case "Array":
            typeString = "Array<Int>"
            sugaredType = "[Int]"
        case "Dictionary":
            typeString = "Dictionary<String, Int>"
            sugaredType = "[String: Int]"
        default:
            return Self.description.description
        }

        return "Shorthand syntactic sugar should be used, i.e. \(sugaredType) instead of \(typeString)."
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
        case implicitlyUnwrappedOptional
    }

    let position: AbsolutePosition
    let type: String

    let correction: Correction

    var children: [SyntacticSugarRuleViolation] = []
}

private final class SyntacticSugarRuleVisitor: SyntaxAnyVisitor {
    private let types = ["Optional", "ImplicitlyUnwrappedOptional", "Array", "Dictionary"]

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
        if let violation = violation(in: node.returnType) {
            violations.append(violation)
        }
    }

    override func visitPost(_ node: AsExprSyntax) {
        // json["recommendations"] as? ↓Array<[String: Any]>
        if let violation = violation(in: node.typeName) {
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
        if let violation = violation(in: node.leftTypeIdentifier) {
            violations.append(violation)
        }
        if let violation = violation(in: node.rightTypeIdentifier) {
            violations.append(violation)
        }
    }

    override func visitPost(_ node: SpecializeExprSyntax) {
        // let x = ↓Array<String>.array(of: object)
        let tokens = Array(node.expression.tokens)

        // Remove Swift. module prefix if needed
        var tokensText = tokens.map { $0.text }.joined()
        if tokensText.starts(with: "Swift.") {
            tokensText.removeFirst("Swift.".count)
        }

        // Skip checks for 'self' or \T Dictionary<Key, Value>.self
        if let parent = node.parent?.as(MemberAccessExprSyntax.self),
           let lastToken = Array(parent.tokens).last?.tokenKind,
           lastToken == .selfKeyword || lastToken == .identifier("Type") || lastToken == .identifier("none") {
            return
        }

        if types.contains(tokensText) {
            if let violation = violation(from: node) {
                violations.append(violation)
            }
            return
        }

        // If there's no type let's check all inner generics like in case of Box<Array<T>>
        node.genericArgumentClause.arguments
            .compactMap { violation(in: $0.argumentType) }
            .first
            .map { violations.append($0) }
    }

    private func violation(in typeSyntax: TypeSyntax?) -> SyntacticSugarRuleViolation? {
        if let optionalType = typeSyntax?.as(OptionalTypeSyntax.self) {
            return violation(in: optionalType.wrappedType)
        }

        if let simpleType = typeSyntax?.as(SimpleTypeIdentifierSyntax.self) {
            if types.contains(simpleType.name.text) {
                return violation(from: simpleType)
            }

            // If there's no type let's check all inner generics like in case of Box<Array<T>>
            guard let genericArguments = simpleType.genericArgumentClause else { return nil }
            let innerTypes = genericArguments.arguments.compactMap { violation(in: $0.argumentType) }
            return innerTypes.first
        }

        // Base class is "Swift" for cases like "Swift.Array"
        if let memberType = typeSyntax?.as(MemberTypeIdentifierSyntax.self),
           let baseType = memberType.baseType.as(SimpleTypeIdentifierSyntax.self),
           baseType.name.text == "Swift" {
            guard types.contains(memberType.name.text) else { return nil }
            return violation(from: memberType)
        }
        return nil
    }

    private func violation(from node: SyntaxProtocol & SyntaxWithGenericClause) -> SyntacticSugarRuleViolation? {
        guard
            let generic = node.genericArguments,
            let firstGenericType = generic.arguments.first,
            let lastGenericType = generic.arguments.last,
            var typeName = node.typeName
        else { return nil }

        if typeName.hasPrefix("Swift.") {
            typeName.removeFirst("Swift.".count)
        }

        var type = SyntacticSugarRuleViolation.CorrectionType.array
        if typeName.isEqualTo("Dictionary") {
            guard let comma = firstGenericType.trailingComma else { return nil }
            let lastArgumentEnd = firstGenericType.argumentType.endPositionBeforeTrailingTrivia
            type = .dictionary(commaStart: lastArgumentEnd, commaEnd: comma.endPosition)
        }
        if typeName.isEqualTo("Optional") {
            type = .optional
        }
        if typeName.isEqualTo("ImplicitlyUnwrappedOptional") {
            type = .implicitlyUnwrappedOptional
        }

        let firstInnerViolation = violation(in: firstGenericType.argumentType)
        let secondInnerViolation = generic.arguments.count > 1 ? violation(in: lastGenericType.argumentType) : nil

        return SyntacticSugarRuleViolation(
            position: node.positionAfterSkippingLeadingTrivia,
            type: typeName,
            correction: .init(typeStart: node.position,
                              correction: type,
                              leftStart: generic.leftAngleBracket.position,
                              leftEnd: generic.leftAngleBracket.endPosition,
                              rightStart: lastGenericType.endPositionBeforeTrailingTrivia,
                              rightEnd: generic.rightAngleBracket.endPositionBeforeTrailingTrivia),
            children: [ firstInnerViolation, secondInnerViolation].compactMap { $0 }
        )
    }
}

// MARK: - Private

private struct CorrectingContex {
    let rule: Rule
    let file: SwiftLintFile
    var contents: String
    var corrections: [Correction] = []

    mutating func correctViolations(_ violations: [SyntacticSugarRuleViolation]) {
        let sortedVolations = violations.sorted(by: { $0.correction.typeStart > $1.correction.typeStart })
        sortedVolations.forEach { violation in
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

            let violationsAfterComma = violation.children.filter { $0.position.utf8Offset > commaStart.utf8Offset }
            correctViolations(violationsAfterComma)

            replaceCharacters(in: commaRange, with: ": ")

            let violationsBeforeComma = violation.children.filter { $0.position.utf8Offset < commaStart.utf8Offset }
            correctViolations(violationsBeforeComma)
            replaceCharacters(in: leftRange, with: "[")

        case .optional:
            replaceCharacters(in: rightRange, with: "?")
            correctViolations(violation.children)
            replaceCharacters(in: leftRange, with: "")

        case .implicitlyUnwrappedOptional:
            replaceCharacters(in: rightRange, with: "!")
            correctViolations(violation.children)
            replaceCharacters(in: leftRange, with: "")
        }

        let location = Location(file: file, byteOffset: ByteCount(correction.typeStart.utf8Offset))
        corrections.append(Correction(ruleDescription: type(of: rule).description, location: location))
    }

    private mutating func replaceCharacters(in range: NSRange, with replacement: String) {
        contents = contents.bridge().replacingCharacters(in: range, with: replacement)
    }
}

private protocol SyntaxWithGenericClause {
    var typeName: String? { get }
    var genericArguments: GenericArgumentClauseSyntax? { get }
}

extension MemberTypeIdentifierSyntax: SyntaxWithGenericClause {
    var typeName: String? { name.text }
    var genericArguments: GenericArgumentClauseSyntax? { genericArgumentClause }
}

extension SimpleTypeIdentifierSyntax: SyntaxWithGenericClause {
    var typeName: String? { name.text }
    var genericArguments: GenericArgumentClauseSyntax? { genericArgumentClause }
}

extension SpecializeExprSyntax: SyntaxWithGenericClause {
    var typeName: String? {
        expression.as(IdentifierExprSyntax.self)?.firstToken?.text ??
        expression.as(MemberAccessExprSyntax.self)?.name.text
    }
    var genericArguments: GenericArgumentClauseSyntax? { genericArgumentClause }
}
