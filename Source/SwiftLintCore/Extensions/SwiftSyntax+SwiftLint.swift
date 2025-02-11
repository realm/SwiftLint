import SourceKittenFramework
import SwiftSyntax

// workaround for https://bugs.swift.org/browse/SR-10121 so we can use `Self` in a closure
public protocol SwiftLintSyntaxVisitor: SyntaxVisitor {}
extension SyntaxVisitor: SwiftLintSyntaxVisitor {}

public extension SwiftLintSyntaxVisitor {
    func walk<T>(tree: some SyntaxProtocol, handler: (Self) -> T) -> T {
        walk(tree)
        return handler(self)
    }

    func walk<T>(file: SwiftLintFile, handler: (Self) -> [T]) -> [T] {
        walk(tree: file.syntaxTree, handler: handler)
    }
}

public extension SyntaxProtocol {
    func windowsOfThreeTokens() -> [(TokenSyntax, TokenSyntax, TokenSyntax)] {
        Array(tokens(viewMode: .sourceAccurate))
            .windows(ofCount: 3)
            .map { tokens in
                let previous = tokens[tokens.startIndex]
                let current = tokens[tokens.startIndex + 1]
                let next = tokens[tokens.startIndex + 2]
                return (previous, current, next)
            }
    }

    func isContainedIn(regions: [SourceRange], locationConverter: SourceLocationConverter) -> Bool {
        positionAfterSkippingLeadingTrivia.isContainedIn(regions: regions, locationConverter: locationConverter)
    }
}

public extension AbsolutePosition {
    func isContainedIn(regions: [SourceRange], locationConverter: SourceLocationConverter) -> Bool {
        regions.contains { region in
            region.contains(self, locationConverter: locationConverter)
        }
    }
}

public extension ByteSourceRange {
    func toSourceKittenByteRange() -> ByteRange {
        ByteRange(location: ByteCount(offset), length: ByteCount(length))
    }
}

public extension ClassDeclSyntax {
    func isXCTestCase(_ testParentClasses: Set<String>) -> Bool {
        guard let inheritanceList = inheritanceClause?.inheritedTypes else {
            return false
        }
        let inheritedTypes = inheritanceList.compactMap { $0.type.as(IdentifierTypeSyntax.self)?.name.text }
        return testParentClasses.intersection(inheritedTypes).isNotEmpty
    }
}

public extension ExprSyntax {
    var asFunctionCall: FunctionCallExprSyntax? {
        if let functionCall = self.as(FunctionCallExprSyntax.self) {
            return functionCall
        }
        if let tuple = self.as(TupleExprSyntax.self),
                  let firstElement = tuple.elements.onlyElement,
                  let functionCall = firstElement.expression.as(FunctionCallExprSyntax.self) {
            return functionCall
        }
        return nil
    }
}

public extension StringLiteralExprSyntax {
    var isEmptyString: Bool {
        segments.onlyElement?.trimmedLength == .zero
    }
}

public extension TokenKind {
    var isEqualityComparison: Bool {
        self == .binaryOperator("==") || self == .binaryOperator("!=")
    }
}

public extension DeclModifierListSyntax {
    var containsStaticOrClass: Bool {
        contains(keyword: .static) || contains(keyword: .class)
    }

    func containsPrivateOrFileprivate(setOnly: Bool = false) -> Bool {
        if !contains(keyword: .private), !contains(keyword: .fileprivate) {
            return false
        }
        let hasSet = contains { $0.detail?.detail.text == "set" }
        return setOnly ? hasSet : !hasSet
    }

    var accessLevelModifier: DeclModifierSyntax? {
        first { $0.asAccessLevelModifier != nil }
    }

    func accessLevelModifier(setter: Bool = false) -> DeclModifierSyntax? {
        first {
            if $0.asAccessLevelModifier == nil {
                return false
            }
            let hasSetDetail = $0.detail?.detail.tokenKind == .identifier("set")
            return setter ? hasSetDetail : !hasSetDetail
        }
    }

    func contains(keyword: Keyword) -> Bool {
        contains { $0.name.tokenKind == .keyword(keyword) }
    }
}

public extension DeclModifierSyntax {
    var asAccessLevelModifier: TokenKind? {
        switch name.tokenKind {
        case .keyword(.open), .keyword(.public), .keyword(.package), .keyword(.internal),
             .keyword(.fileprivate), .keyword(.private):
            return name.tokenKind
        default:
            return nil
        }
    }
}

public extension AttributeSyntax {
    var attributeNameText: String {
        attributeName.as(IdentifierTypeSyntax.self)?.name.text ?? attributeName.description
    }
}

public extension AttributeListSyntax {
    func contains(attributeNamed attributeName: String) -> Bool {
        contains { $0.as(AttributeSyntax.self)?.attributeNameText == attributeName } == true
    }
}

public extension TokenKind {
    var isUnavailableKeyword: Bool {
        self == .keyword(.unavailable) || self == .identifier("unavailable")
    }
}

public extension VariableDeclSyntax {
    var isIBOutlet: Bool {
        attributes.contains(attributeNamed: "IBOutlet")
    }

    var weakOrUnownedModifier: DeclModifierSyntax? {
        modifiers.first { decl in
            decl.name.tokenKind == .keyword(.weak) ||
                decl.name.tokenKind == .keyword(.unowned)
        }
    }

    var isInstanceVariable: Bool {
        !modifiers.containsStaticOrClass
    }
}

public extension EnumDeclSyntax {
    /// True if this enum supports raw values
    var supportsRawValues: Bool {
        guard let inheritedTypeCollection = inheritanceClause?.inheritedTypes else {
            return false
        }

        let rawValueTypes: Set<String> = [
            "Int", "Int8", "Int16", "Int32", "Int64",
            "UInt", "UInt8", "UInt16", "UInt32", "UInt64",
            "Double", "Float", "Float80", "Decimal", "NSNumber",
            "NSDecimalNumber", "NSInteger", "String", "CGFloat",
        ]

        return inheritedTypeCollection.contains { element in
            guard let identifier = element.type.as(IdentifierTypeSyntax.self)?.name.text else {
                return false
            }

            return rawValueTypes.contains(identifier)
        }
    }

    /// True if this enum is a `CodingKey`. For that, it has to be named `CodingKeys` and must conform to the `CodingKey` protocol. 
    var definesCodingKeys: Bool {
        guard let inheritedTypeCollection = inheritanceClause?.inheritedTypes,
              name.text == "CodingKeys" else { 
            return false
        }

        return inheritedTypeCollection.contains { element in
            element.type.as(IdentifierTypeSyntax.self)?.name.text == "CodingKey"
        }
    }
}

public extension FunctionDeclSyntax {
    var isIBAction: Bool {
        attributes.contains(attributeNamed: "IBAction")
    }

    /// Returns the signature including arguments, e.g "setEditing(_:animated:)"
    var resolvedName: String {
        var name = self.name.text
        name += "("

        let params = signature.parameterClause.parameters.compactMap { param in
            param.firstName.text.appending(":")
        }

        name += params.joined()
        name += ")"
        return name
    }

    /// How many times this function calls the `super` implementation in its body.
    /// Returns 0 if the function has no body.
    func numberOfCallsToSuper() -> Int {
        guard let body else {
            return 0
        }

        return SuperCallVisitor(expectedFunctionName: name.text)
            .walk(tree: body, handler: \.superCallsCount)
    }
}

public extension AccessorBlockSyntax {
    var getAccessor: AccessorDeclSyntax? {
        accessorsList.first { $0.accessorSpecifier.tokenKind == .keyword(.get) }
    }

    var setAccessor: AccessorDeclSyntax? {
        accessorsList.first { $0.accessorSpecifier.tokenKind == .keyword(.set) }
    }

    var specifiesGetAccessor: Bool {
        getAccessor != nil
    }

    var specifiesSetAccessor: Bool {
        setAccessor != nil
    }

    var accessorsList: AccessorDeclListSyntax {
        if case let .accessors(list) = accessors {
            return list
        }
        return AccessorDeclListSyntax([])
    }
}

public extension InheritanceClauseSyntax? {
    func containsInheritedType(inheritedTypes: Set<String>) -> Bool {
        self?.inheritedTypes.contains { elem in
            guard let simpleType = elem.type.as(IdentifierTypeSyntax.self) else {
                return false
            }

            return inheritedTypes.contains(simpleType.name.text)
        } ?? false
    }
}

public extension Trivia {
    func containsNewlines() -> Bool {
        contains { piece in
            if case .newlines = piece {
                return true
            }
            return false
        }
    }

    var containsComments: Bool {
        isNotEmpty && contains { piece in
            !piece.isWhitespace && !piece.isNewline
        }
    }

    var isSingleSpace: Bool {
        self == .spaces(1)
    }

    var withFirstEmptyLineRemoved: Trivia {
        if let index = firstIndex(where: \.isNewline), index < endIndex {
            return Trivia(pieces: dropFirst(index + 1))
        }
        return self
    }

    var withTrailingEmptyLineRemoved: Trivia {
        if let index = pieces.lastIndex(where: \.isNewline), index < endIndex {
            if index == endIndex - 1 {
                return Trivia(pieces: dropLast(1))
            }
            if pieces.suffix(from: index + 1).allSatisfy(\.isHorizontalWhitespace) {
                return Trivia(pieces: prefix(upTo: index))
            }
        }
        return self
    }

    var withoutTrailingIndentation: Trivia {
        Trivia(pieces: reversed().drop(while: \.isHorizontalWhitespace).reversed())
    }
}

public extension TriviaPiece {
    var isHorizontalWhitespace: Bool {
        switch self {
        case .spaces, .tabs:
            return true
        default:
            return false
        }
    }
}

public extension IntegerLiteralExprSyntax {
    var isZero: Bool {
        guard case let .integerLiteral(number) = literal.tokenKind else {
            return false
        }
        return number.isZero
    }
}

public extension FloatLiteralExprSyntax {
    var isZero: Bool {
        guard case let .floatLiteral(number) = literal.tokenKind else {
            return false
        }
        return number.isZero
    }
}

public extension MemberAccessExprSyntax {
    var isBaseSelf: Bool {
        base?.as(DeclReferenceExprSyntax.self)?.isSelf == true
    }
}

public extension DeclReferenceExprSyntax {
    var isSelf: Bool {
        baseName.text == "self"
    }
}

public extension ClosureCaptureSyntax {
    var capturesSelf: Bool {
        expression.as(DeclReferenceExprSyntax.self)?.isSelf == true
    }

    var capturesWeakly: Bool {
        specifier?.specifier.text == "weak"
    }
}

private extension String {
    var isZero: Bool {
        if self == "0" { // fast path
            return true
        }

        var number = lowercased()
        for prefix in ["0x", "0o", "0b"] {
            number = number.deletingPrefix(prefix)
        }

        number = number.replacingOccurrences(of: "_", with: "")
        return Float(number) == 0
    }
}

private class SuperCallVisitor: SyntaxVisitor {
    private let expectedFunctionName: String
    private(set) var superCallsCount = 0

    init(expectedFunctionName: String) {
        self.expectedFunctionName = expectedFunctionName
        super.init(viewMode: .sourceAccurate)
    }

    override func visitPost(_ node: FunctionCallExprSyntax) {
        guard let expr = node.calledExpression.as(MemberAccessExprSyntax.self),
              expr.base?.as(SuperExprSyntax.self) != nil,
              expr.declName.baseName.text == expectedFunctionName else {
            return
        }

        superCallsCount += 1
    }
}
