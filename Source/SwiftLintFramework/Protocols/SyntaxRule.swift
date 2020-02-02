import Foundation
import SourceKittenFramework
#if canImport(SwiftSyntax)
import SwiftSyntax
#endif

/// A rule that leverages the SwiftSyntax library.
public protocol SyntaxRule: Rule {}

#if canImport(SwiftSyntax)
public protocol SyntaxRuleVisitor: SyntaxVisitor {
    /// The rule that uses this visitor.
    associatedtype Rule: SyntaxRule

    /// Return the violations that should be calculated based on data that was accumulated during the `visit` methods.
    func violations(for rule: Rule, in file: SwiftLintFile) -> [StyleViolation]
}

public extension SyntaxRule {
    /// Wraps computation of violations based on a visitor.
    func validate<Visitor: SyntaxRuleVisitor>(file: SwiftLintFile,
                                              visitor: Visitor) -> [StyleViolation] where Visitor.Rule == Self {
        let lock = NSLock()
        // https://bugs.swift.org/browse/SR-11170
        let work = DispatchWorkItem {
            var visitor = visitor
            lock.lock()
            file.syntax.walk(&visitor)
            lock.unlock()
        }
        if #available(OSX 10.12, *) {
            let thread = Thread {
                work.perform()
            }
            thread.stackSize = 8 << 20 // 8 MB.
            thread.start()
            work.wait()
        } else {
            queuedFatalError("macOS < 10.12")
        }

        lock.lock()
        defer { lock.unlock() }

        return visitor.violations(for: self, in: file)
    }
}
#endif
