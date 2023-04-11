import SwiftSyntax

struct UseCaseExposedFunctionsRule: SwiftSyntaxRule, ConfigurationProviderRule {
    var configuration = SeverityConfiguration(.error)

    init() {}

    let message: String = "A UseCase should only expose one public function"

    static let description = RuleDescription(
        identifier: "usecase_exposed_functions",
        name: "UseCaseExposedFunctionsRule",
        description: "A UseCase should only expose one public function",
        kind: .style,
        nonTriggeringExamples: UseCaseExposedFunctionsRuleExamples.nonTriggeringExamples,
        triggeringExamples: UseCaseExposedFunctionsRuleExamples.triggeringExamples
    )

     func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(viewMode: .sourceAccurate)
    }
}

private extension UseCaseExposedFunctionsRule {
    final class Visitor: ViolationsSyntaxVisitor {
        override var skippableDeclarations: [DeclSyntaxProtocol.Type] {
            .allExcept(ClassDeclSyntax.self, ProtocolDeclSyntax.self, StructDeclSyntax.self)
        }

        override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
            if node.isLogicClass && node.members.nonPrivateFunctions.count > 1 {
                violations.append(node.positionAfterSkippingLeadingTrivia)
            }

            return .skipChildren
        }

        override func visit(_ node: ProtocolDeclSyntax) -> SyntaxVisitorContinueKind {
            if node.isLogicProtocol && node.members.nonPrivateFunctions.count > 1 {
                violations.append(node.positionAfterSkippingLeadingTrivia)
            }

            return .skipChildren
        }

        override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
            if node.isLogicStruct && node.members.nonPrivateFunctions.count > 1 {
                violations.append(node.positionAfterSkippingLeadingTrivia)
            }

            return .skipChildren
        }
    }
}

private extension ClassDeclSyntax {
    // Check that it is a logic class
    var isLogicClass: Bool {
        identifier.text.hasSuffix("Logic") || identifier.text.hasSuffix("UseCase")
    }
}

private extension StructDeclSyntax {
    // Check that it is a logic struct
    var isLogicStruct: Bool {
        identifier.text.hasSuffix("Logic") || identifier.text.hasSuffix("UseCase")
    }
}

private extension ProtocolDeclSyntax {
    // Check that it is a logic struct
    var isLogicProtocol: Bool {
        identifier.text.hasSuffix("Logic") || identifier.text.hasSuffix("UseCase")
    }
}

private extension MemberDeclBlockSyntax {
    var nonPrivateFunctions: [MemberDeclListSyntax.Element] {
        members.filter { member in
            guard let function: FunctionDeclSyntax = member.decl.as(FunctionDeclSyntax.self) else { return false }

            return function.modifiers?.contains(where: { $0.name.tokenKind != .keyword(.private) }) ?? true
        }
    }
}

internal struct UseCaseExposedFunctionsRuleExamples {
    static let nonTriggeringExamples: [Example] = [
        Example("""
        struct MyView: View {
            var body: some View {
                Image(decorative: "my-image")
            }
        }
        """),
        Example("""
        class MyViewModel: ViewModel {
            var state: State = State.empty()
        }
        """),
        Example("""
        protocol LogicalProtocol {
            func receive() -> Bool
        }
        """),
        Example("""
        public class MyUseCase {
            public init() {}

            public func callAsFunction() -> AnyPublisher<Void, Never> {}

            private func computeInput() {}
        }
        """),
        Example("""
        class MyLogic {
            init() {}

            private func get(fire: String) -> Int {
                return 35
            }
            func callAsFunction() -> String {
                return "call"
            }
        }
        """),
        Example("""
        class MyLogic {
            init() {}

            func get(fire: String) -> Int {
                return 35
            }
        }
        """)
    ]

    static let triggeringExamples: [Example] = [
        Example("""
        public protocol MyLogic {
            func getSomething() -> String
            func callAsFunction() -> AnyPublisher<Void, Never>
        }
        """),
        Example("""
        public struct MyLogic {
            public init() {}

            public func get() -> Int {
                return 45
            }
            public func callAsFunction() -> String {
                return ""
            }
        }
        """),
        Example("""
        public class MyLogic {
            public init() {}

            public func get(fire: String) -> Int {
                return 35
            }
            public func callAsFunction() -> String {
                return "call"
            }
        }
        """),
        Example("""
        class MyLogic {
            init() {}

            func get(fire: String) -> Int {
                return 35
            }
            public func callAsFunction() -> String {
                return "call"
            }
        }
        """),
        Example("""
        class MyLogic {
            init() {}

            func get(fire: String) -> Int {
                return 35
            }
            func callAsFunction() -> String {
                return "call"
            }
        }
        """)
    ]
}
