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

extension TokenKind {
    var isEqualityComparison: Bool {
        self == .spacedBinaryOperator("==") ||
            self == .spacedBinaryOperator("!=") ||
            self == .unspacedBinaryOperator("==")
    }
}
