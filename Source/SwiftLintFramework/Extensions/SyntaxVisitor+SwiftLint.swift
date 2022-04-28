import Foundation
import SwiftSyntax

extension SyntaxVisitor {
    func safeWalk(tree: SourceFileSyntax, lock: NSLock? = nil) {
        #if DEBUG
        // workaround for stack overflow when running in debug
        // https://bugs.swift.org/browse/SR-11170
        let work = DispatchWorkItem {
            lock?.lock()
            self.walk(tree)
            lock?.unlock()
        }
        let thread = Thread {
            work.perform()
        }

        thread.stackSize = 8 << 20 // 8 MB.
        thread.start()
        work.wait()
        #else
        walk(tree)
        #endif
    }

    func walk(file: SwiftLintFile) {
        guard let syntaxTree = file.syntaxTree else {
            return
        }

        safeWalk(tree: syntaxTree)
    }
}
