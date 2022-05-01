import Foundation
import SwiftSyntax

// workaround for https://bugs.swift.org/browse/SR-10121 so we can use `Self` in a closure
protocol SwiftLintSyntaxVisitor: SyntaxVisitor {}
extension SyntaxVisitor: SwiftLintSyntaxVisitor {}

extension SwiftLintSyntaxVisitor {
    func walk<T>(tree: SourceFileSyntax, handler: (Self) -> T) -> T {
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
        guard let syntaxTree = file.syntaxTree else {
            return []
        }

        return walk(tree: syntaxTree, handler: handler)
    }
}
