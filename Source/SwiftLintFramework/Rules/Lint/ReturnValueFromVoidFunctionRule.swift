import Foundation
import SourceKittenFramework
import SwiftSyntax

public struct ReturnValueFromVoidFunctionRule: ConfigurationProviderRule, AutomaticTestableRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "return_value_from_void_function",
        name: "Return Value from Void Function",
        description: "Returning values Void functions should be avoided.",
        kind: .lint,
        nonTriggeringExamples: ReturnValueFromVoidFunctionRuleExamples.nonTriggeringExamples,
        triggeringExamples: ReturnValueFromVoidFunctionRuleExamples.triggeringExamples
    )

    public func validate(file: SwiftLintFile) -> [StyleViolation] {
        var visitor = ReturnVisitor()

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

        return visitor.positions.map { position in
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severity,
                           location: Location(file: file, byteOffset: position.utf8Offset))
        }
    }
}

private struct ReturnVisitor: SyntaxVisitor {
    private(set) var positions = [AbsolutePosition]()

    mutating func visit(_ node: ReturnStmtSyntax) -> SyntaxVisitorContinueKind {
        if node.expression != nil,
            let functionNode = node.enclosingFunction(),
            functionNode.returnsVoid {
            positions.append(node.positionAfterSkippingLeadingTrivia)
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
        } else {
            return signature.output?.returnType == nil
        }
    }
}
