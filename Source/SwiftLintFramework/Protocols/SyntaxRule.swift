import Foundation
#if canImport(SwiftSyntax)
import SwiftSyntax
#endif

/// A rule that leverages the SwiftSyntax library.
public protocol SyntaxRule: Rule {}

#if canImport(SwiftSyntax)
/// A SwiftSyntax visitor that collects data to provide violations for a specific rule.
public protocol SyntaxRuleVisitor: SyntaxVisitor {
    /// The rule that uses this visitor.
    associatedtype Rule: SyntaxRule

    /// Returns the violations that should be calculated based on data that was accumulated during the `visit` methods.
    func violations(for rule: Rule, in file: SwiftLintFile) -> [StyleViolation]
}

public extension SyntaxRule {
    /// Wraps computation of violations based on a visitor.
    func validate<Visitor: SyntaxRuleVisitor>(file: SwiftLintFile,
                                              visitor: Visitor) -> [StyleViolation] where Visitor.Rule == Self {
        let lock = NSLock()
        var visitor = visitor

        // https://bugs.swift.org/browse/SR-11170
        let work = DispatchWorkItem {
            lock.lock()
            file.syntax.walk(&visitor)
            lock.unlock()
        }
        let thread = Thread {
            work.perform()
        }
        thread.stackSize = 8 << 20 // 8 MB.
        thread.start()
        work.wait()

        lock.lock()
        defer { lock.unlock() }
        return visitor.violations(for: self, in: file)
    }
}
#endif
