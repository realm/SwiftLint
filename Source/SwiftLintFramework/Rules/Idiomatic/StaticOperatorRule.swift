import SwiftSyntax

struct StaticOperatorRule: SwiftSyntaxRule, ConfigurationProviderRule, OptInRule {
    var configuration = SeverityConfiguration(.warning)

    init() {}

    static let description = RuleDescription(
        identifier: "static_operator",
        name: "Static Operator",
        description: "Operators should be declared as static functions, not free functions",
        kind: .idiomatic,
        nonTriggeringExamples: [
            Example("""
            class A: Equatable {
              static func == (lhs: A, rhs: A) -> Bool {
                return false
              }
            """),
            Example("""
            class A<T>: Equatable {
                static func == <T>(lhs: A<T>, rhs: A<T>) -> Bool {
                    return false
                }
            """),
            Example("""
            public extension Array where Element == Rule {
              static func == (lhs: Array, rhs: Array) -> Bool {
                if lhs.count != rhs.count { return false }
                return !zip(lhs, rhs).contains { !$0.0.isEqualTo($0.1) }
              }
            }
            """),
            Example("""
            private extension Optional where Wrapped: Comparable {
              static func < (lhs: Optional, rhs: Optional) -> Bool {
                switch (lhs, rhs) {
                case let (lhs?, rhs?):
                  return lhs < rhs
                case (nil, _?):
                  return true
                default:
                  return false
                }
              }
            }
            """)
        ],
        triggeringExamples: [
            Example("""
            ↓func == (lhs: A, rhs: A) -> Bool {
              return false
            }
            """),
            Example("""
            ↓func == <T>(lhs: A<T>, rhs: A<T>) -> Bool {
              return false
            }
            """),
            Example("""
            ↓func == (lhs: [Rule], rhs: [Rule]) -> Bool {
              if lhs.count != rhs.count { return false }
              return !zip(lhs, rhs).contains { !$0.0.isEqualTo($0.1) }
            }
            """),
            Example("""
            private ↓func < <T: Comparable>(lhs: T?, rhs: T?) -> Bool {
              switch (lhs, rhs) {
              case let (lhs?, rhs?):
                return lhs < rhs
              case (nil, _?):
                return true
              default:
                return false
              }
            }
            """)
        ]
    )

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(viewMode: .sourceAccurate)
    }
}

private extension StaticOperatorRule {
    final class Visitor: ViolationsSyntaxVisitor {
        override var skippableDeclarations: [DeclSyntaxProtocol.Type] { .all }

        override func visitPost(_ node: FunctionDeclSyntax) {
            if node.isFreeFunction, node.isOperator {
                violations.append(node.funcKeyword.positionAfterSkippingLeadingTrivia)
            }
        }
    }
}

private extension FunctionDeclSyntax {
    var isFreeFunction: Bool {
        parent?.is(CodeBlockItemSyntax.self) ?? false
    }

    var isOperator: Bool {
        switch identifier.tokenKind {
        case .spacedBinaryOperator:
            return true
        default:
            return false
        }
    }
}
