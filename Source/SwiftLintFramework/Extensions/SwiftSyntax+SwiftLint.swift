import Foundation
import SourceKittenFramework
import SwiftSyntax

// workaround for https://bugs.swift.org/browse/SR-10121 so we can use `Self` in a closure
protocol SwiftLintSyntaxVisitor: SyntaxVisitor {}
extension SyntaxVisitor: SwiftLintSyntaxVisitor {}

extension SwiftLintSyntaxVisitor {
    func walk<T, SyntaxType: SyntaxProtocol>(tree: SyntaxType, handler: (Self) -> T) -> T {
#if DEBUG
        // workaround for stack overflow when running in debug
        // https://bugs.swift.org/browse/SR-11170
        let lock = NSLock()
        let work = DispatchWorkItem {
            lock.lock()
            self.walk(tree)
            lock.unlock()
        }
        let thread = Thread {
            work.perform()
        }

        thread.stackSize = 8 << 20 // 8 MB.
        thread.start()
        work.wait()

        lock.lock()
        defer {
            lock.unlock()
        }

        return handler(self)
#else
        walk(tree)
        return handler(self)
#endif
    }

    func walk<T>(file: SwiftLintFile, handler: (Self) -> [T]) -> [T] {
        let syntaxTree = file.syntaxTree

        return walk(tree: syntaxTree, handler: handler)
    }
}

extension SyntaxProtocol {
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

extension AbsolutePosition {
    func isContainedIn(regions: [SourceRange], locationConverter: SourceLocationConverter) -> Bool {
        regions.contains { region in
            region.contains(self, locationConverter: locationConverter)
        }
    }
}

extension ByteSourceRange {
    func toSourceKittenByteRange() -> ByteRange {
        ByteRange(location: ByteCount(offset), length: ByteCount(length))
    }
}

extension ClassDeclSyntax {
    func isXCTestCase(_ testParentClasses: Set<String>) -> Bool {
        guard let inheritanceList = inheritanceClause?.inheritedTypeCollection else {
            return false
        }
        let inheritedTypes = inheritanceList.compactMap { $0.typeName.as(SimpleTypeIdentifierSyntax.self)?.name.text }
        return testParentClasses.intersection(inheritedTypes).isNotEmpty
    }
}

extension ExprSyntax {
    var asFunctionCall: FunctionCallExprSyntax? {
        if let functionCall = self.as(FunctionCallExprSyntax.self) {
            return functionCall
        } else if let tuple = self.as(TupleExprSyntax.self),
                  let firstElement = tuple.elementList.onlyElement,
                  let functionCall = firstElement.expression.as(FunctionCallExprSyntax.self) {
            return functionCall
        } else {
            return nil
        }
    }
}

extension StringLiteralExprSyntax {
    var isEmptyString: Bool {
        segments.onlyElement?.contentLength == .zero
    }
}

extension TokenKind {
    var isEqualityComparison: Bool {
        self == .binaryOperator("==") || self == .binaryOperator("!=")
    }
}

extension ModifierListSyntax? {
    var containsLazy: Bool {
        contains(tokenKind: .keyword(.lazy))
    }

    var containsOverride: Bool {
        contains(tokenKind: .keyword(.override))
    }

    var containsStaticOrClass: Bool {
        isStatic || isClass
    }

    var isStatic: Bool {
        contains(tokenKind: .keyword(.static))
    }

    var isClass: Bool {
        contains(tokenKind: .keyword(.class))
    }

    var isFileprivate: Bool {
        contains(tokenKind: .keyword(.fileprivate))
    }

    var isPrivateOrFileprivate: Bool {
        guard let modifiers = self else {
            return false
        }

        return modifiers.contains { elem in
            (elem.name.tokenKind == .keyword(.private) || elem.name.tokenKind == .keyword(.fileprivate)) &&
                elem.detail == nil
        }
    }

    var isFinal: Bool {
        contains(tokenKind: .keyword(.final))
    }

    private func contains(tokenKind: TokenKind) -> Bool {
        guard let modifiers = self else {
            return false
        }

        return modifiers.contains { $0.name.tokenKind == tokenKind }
    }
}

extension AttributeSyntax {
    var attributeNameText: String {
        attributeName.as(SimpleTypeIdentifierSyntax.self)?.name.text ??
            attributeName.description
    }
}

extension AttributeListSyntax? {
    func contains(attributeNamed attributeName: String) -> Bool {
        self?.contains { $0.as(AttributeSyntax.self)?.attributeNameText == attributeName } == true
    }
}

extension TokenKind {
    var isUnavailableKeyword: Bool {
        self == .keyword(.unavailable) || self == .identifier("unavailable")
    }
}

extension VariableDeclSyntax {
    var isIBOutlet: Bool {
        attributes.contains(attributeNamed: "IBOutlet")
    }

    var weakOrUnownedModifier: DeclModifierSyntax? {
        modifiers?.first { decl in
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
        guard let inheritedTypeCollection = inheritanceClause?.inheritedTypeCollection else {
            return false
        }

        let rawValueTypes: Set<String> = [
            "Int", "Int8", "Int16", "Int32", "Int64",
            "UInt", "UInt8", "UInt16", "UInt32", "UInt64",
            "Double", "Float", "Float80", "Decimal", "NSNumber",
            "NSDecimalNumber", "NSInteger", "String", "CGFloat"
        ]

        return inheritedTypeCollection.contains { element in
            guard let identifier = element.typeName.as(SimpleTypeIdentifierSyntax.self)?.name.text else {
                return false
            }

            return rawValueTypes.contains(identifier)
        }
    }
}

extension FunctionDeclSyntax {
    var isIBAction: Bool {
        attributes.contains(attributeNamed: "IBAction")
    }

    /// Returns the signature including arguments, e.g "setEditing(_:animated:)"
    func resolvedName() -> String {
        var name = self.identifier.text
        name += "("

        let params = signature.input.parameterList.compactMap { param in
            (param.firstName ?? param.secondName)?.text.appending(":")
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

        return SuperCallVisitor(expectedFunctionName: identifier.text)
            .walk(tree: body, handler: \.superCallsCount)
    }
}

extension AccessorBlockSyntax {
    var getAccessor: AccessorDeclSyntax? {
        accessors.first { accessor in
            accessor.accessorKind.tokenKind == .keyword(.get)
        }
    }

    var setAccessor: AccessorDeclSyntax? {
        accessors.first { accessor in
            accessor.accessorKind.tokenKind == .keyword(.set)
        }
    }

    var specifiesGetAccessor: Bool {
        getAccessor != nil
    }

    var specifiesSetAccessor: Bool {
        setAccessor != nil
    }
}

extension TypeInheritanceClauseSyntax? {
    func containsInheritedType(inheritedTypes: Set<String>) -> Bool {
        self?.inheritedTypeCollection.contains { elem in
            guard let simpleType = elem.typeName.as(SimpleTypeIdentifierSyntax.self) else {
                return false
            }

            return inheritedTypes.contains(simpleType.name.text)
        } ?? false
    }
}

extension Trivia {
    func containsNewlines() -> Bool {
        contains { piece in
            if case .newlines = piece {
                return true
            } else {
                return false
            }
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

    var withoutTrailingIndentation: Trivia {
        Trivia(pieces: reversed().drop(while: \.isHorizontalWhitespace).reversed())
    }
}

extension TriviaPiece {
    var isHorizontalWhitespace: Bool {
        switch self {
        case .spaces, .tabs:
            return true
        default:
            return false
        }
    }
}

extension IntegerLiteralExprSyntax {
    var isZero: Bool {
        guard case let .integerLiteral(number) = digits.tokenKind else {
            return false
        }

        return number.isZero
    }
}

extension FloatLiteralExprSyntax {
    var isZero: Bool {
        guard case let .floatingLiteral(number) = floatingDigits.tokenKind else {
            return false
        }

        return number.isZero
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
              expr.base?.as(SuperRefExprSyntax.self) != nil,
              expr.name.text == expectedFunctionName else {
            return
        }

        superCallsCount += 1
    }
}
