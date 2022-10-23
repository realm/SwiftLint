import Foundation
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
        regions.contains { region in
            region.contains(positionAfterSkippingLeadingTrivia, locationConverter: locationConverter)
        }
    }
}

extension ExprSyntax {
    var asFunctionCall: FunctionCallExprSyntax? {
        if let functionCall = self.as(FunctionCallExprSyntax.self) {
            return functionCall
        } else if let tuple = self.as(TupleExprSyntax.self),
                  tuple.elementList.count == 1,
                  let firstElement = tuple.elementList.first,
                  let functionCall = firstElement.expression.as(FunctionCallExprSyntax.self) {
            return functionCall
        } else {
            return nil
        }
    }
}

extension StringLiteralExprSyntax {
    var isEmptyString: Bool {
        segments.count == 1 && segments.first?.contentLength == .zero
    }
}

extension TokenKind {
    var isEqualityComparison: Bool {
        self == .spacedBinaryOperator("==") ||
            self == .spacedBinaryOperator("!=") ||
            self == .unspacedBinaryOperator("==")
    }
}

extension ModifierListSyntax? {
    var containsLazy: Bool {
        contains(tokenKind: .contextualKeyword("lazy"))
    }

    var containsOverride: Bool {
        contains(tokenKind: .contextualKeyword("override"))
    }

    var containsStaticOrClass: Bool {
        isStatic || isClass
    }

    var isStatic: Bool {
        contains(tokenKind: .staticKeyword)
    }

    var isClass: Bool {
        contains(tokenKind: .classKeyword)
    }

    var isPrivateOrFileprivate: Bool {
        guard let modifiers = self else {
            return false
        }

        return modifiers.contains { elem in
            (elem.name.tokenKind == .privateKeyword || elem.name.tokenKind == .fileprivateKeyword) &&
                elem.detail == nil
        }
    }

    private func contains(tokenKind: TokenKind) -> Bool {
        guard let modifiers = self else {
            return false
        }

        return modifiers.contains { $0.name.tokenKind == tokenKind }
    }
}

extension VariableDeclSyntax {
    var isIBOutlet: Bool {
        attributes?.contains { attr in
            attr.as(AttributeSyntax.self)?.attributeName.tokenKind == .identifier("IBOutlet")
        } ?? false
    }

    var weakOrUnownedModifier: DeclModifierSyntax? {
        modifiers?.first { decl in
            decl.name.tokenKind == .contextualKeyword("weak") ||
                decl.name.tokenKind == .contextualKeyword("unowned")
        }
    }

    var isInstanceVariable: Bool {
        !modifiers.containsStaticOrClass
    }
}

extension FunctionDeclSyntax {
    var isIBAction: Bool {
        attributes?.contains { attr in
            attr.as(AttributeSyntax.self)?.attributeName.tokenKind == .identifier("IBAction")
        } ?? false
    }
}

extension AccessorBlockSyntax {
    var getAccessor: AccessorDeclSyntax? {
        accessors.first { accessor in
            accessor.accessorKind.tokenKind == .contextualKeyword("get")
        }
    }

    var setAccessor: AccessorDeclSyntax? {
        accessors.first { accessor in
            accessor.accessorKind.tokenKind == .contextualKeyword("set")
        }
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
