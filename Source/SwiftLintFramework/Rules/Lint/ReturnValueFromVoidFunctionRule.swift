import Foundation
import SourceKittenFramework
#if canImport(SwiftSyntax)
import SwiftSyntax
#endif

public struct ReturnValueFromVoidFunctionRule: ConfigurationProviderRule, OptInRule, AutomaticTestableRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "return_value_from_void_function",
        name: "Return Value from Void Function",
        description: "Returning values Void functions should be avoided.",
        kind: .lint,
        minSwiftVersion: .fiveDotOne,
        nonTriggeringExamples: ReturnValueFromVoidFunctionRuleExamples.nonTriggeringExamples,
        triggeringExamples: ReturnValueFromVoidFunctionRuleExamples.triggeringExamples
    )

    public func validate(file: SwiftLintFile) -> [StyleViolation] {
        #if canImport(SwiftSyntax)
        let lock = NSLock()
        var visitor = ReturnVisitor(lock: lock)

        // https://bugs.swift.org/browse/SR-11170
        let work = DispatchWorkItem {
            file.syntax.walk(&visitor)
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
        return visitor.positions.map { position in
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severity,
                           location: Location(file: file, byteOffset: ByteCount(position.utf8Offset)))
        }
        #else
        return []
        #endif
    }
}

#if canImport(SwiftSyntax)
private class ReturnVisitor: SyntaxVisitor {
    private(set) var positions = [AbsolutePosition]()
    private let lock: NSLock

    init(lock: NSLock) {
        self.lock = lock
    }

    func visit(_ node: ReturnStmtSyntax) -> SyntaxVisitorContinueKind {
        if node.expression != nil,
            let functionNode = node.enclosingFunction(),
            functionNode.returnsVoid {
            lock.lock()
            positions.append(node.positionAfterSkippingLeadingTrivia)
            lock.unlock()
        }
        return .visitChildren
    }
}

private extension Syntax {
    func enclosingFunction() -> FunctionDeclSyntax? {
        if let node = self as? FunctionDeclSyntax {
            return node
        }

        if self is ClosureExprSyntax {
            return nil
        }

        return parent?.enclosingFunction()
    }
}

private extension FunctionDeclSyntax {
    var returnsVoid: Bool {
        if let type = signature.output?.returnType as? SimpleTypeIdentifierSyntax {
            return type.name.text == "Void"
        }

        return signature.output?.returnType == nil
    }
}
#endif
