import SwiftSyntax

public struct FunctionDefaultParameterAtEndRule: SwiftSyntaxRule, ConfigurationProviderRule, OptInRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "function_default_parameter_at_end",
        name: "Function Default Parameter at End",
        description: "Prefer to locate parameters with defaults toward the end of the parameter list.",
        kind: .idiomatic,
        nonTriggeringExamples: [
            Example("func foo(baz: String, bar: Int = 0) {}"),
            Example("func foo(x: String, y: Int = 0, z: CGFloat = 0) {}"),
            Example("func foo(bar: String, baz: Int = 0, z: () -> Void) {}"),
            Example("func foo(bar: String, z: () -> Void, baz: Int = 0) {}"),
            Example("func foo(bar: Int = 0) {}"),
            Example("func foo() {}"),
            Example("""
            class A: B {
              override func foo(bar: Int = 0, baz: String) {}
            """),
            Example("func foo(bar: Int = 0, completion: @escaping CompletionHandler) {}"),
            Example("""
            func foo(a: Int, b: CGFloat = 0) {
              let block = { (error: Error?) in }
            }
            """),
            Example("""
            func foo(a: String, b: String? = nil,
                     c: String? = nil, d: @escaping AlertActionHandler = { _ in }) {}
            """),
            Example("override init?(for date: Date = Date(), coordinate: CLLocationCoordinate2D) {}"),
            Example("""
            func handleNotification(_ userInfo: NSDictionary,
                                    userInteraction: Bool = false,
                                    completionHandler: ((UIBackgroundFetchResult) -> Void)?) {}
            """),
            Example("""
            func write(withoutNotifying tokens: [NotificationToken] =  {}, _ block: (() throws -> Int)) {}
            """)
        ],
        triggeringExamples: [
            Example("↓func foo(bar: Int = 0, baz: String) {}"),
            Example("private ↓func foo(bar: Int = 0, baz: String) {}"),
            Example("public ↓init?(for date: Date = Date(), coordinate: CLLocationCoordinate2D) {}")
        ]
    )

    public func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor? {
        Visitor(viewMode: .sourceAccurate)
    }
}

private extension FunctionDefaultParameterAtEndRule {
    final class Visitor: SyntaxVisitor, ViolationsSyntaxVisitor {
        private(set) var violationPositions: [AbsolutePosition] = []

        override func visitPost(_ node: FunctionDeclSyntax) {
            guard !node.modifiers.containsOverride, node.signature.containsViolation else {
                return
            }

            violationPositions.append(node.funcKeyword.positionAfterSkippingLeadingTrivia)
        }

        override func visitPost(_ node: InitializerDeclSyntax) {
            guard !node.modifiers.containsOverride, node.signature.containsViolation else {
                return
            }

            violationPositions.append(node.initKeyword.positionAfterSkippingLeadingTrivia)
        }
    }
}

private extension ModifierListSyntax? {
    var containsOverride: Bool {
        self?.contains { decl in
            decl.name.tokenKind == .contextualKeyword("override")
        } ?? false
    }
}

private extension FunctionSignatureSyntax {
    var containsViolation: Bool {
        let params = input.parameterList.filter { param in
            !param.isClosure
        }

        guard params.isNotEmpty else {
            return false
        }

        let defaultParams = params.filter { param in
            param.defaultArgument != nil
        }
        guard defaultParams.isNotEmpty else {
            return false
        }

        let lastParameters = params.suffix(defaultParams.count)
        let lastParametersWithDefaultValue = lastParameters.filter { param in
            param.defaultArgument != nil
        }

        return lastParameters.count != lastParametersWithDefaultValue.count
    }
}

private extension FunctionParameterSyntax {
    var isClosure: Bool {
        if isEscaping || type?.as(FunctionTypeSyntax.self) != nil {
            return true
        }

        if let optionalType = type?.as(OptionalTypeSyntax.self),
           let tuple = optionalType.wrappedType.as(TupleTypeSyntax.self),
           tuple.elements.count == 1 {
            return tuple.elements.first?.type.as(FunctionTypeSyntax.self) != nil
        }


        if let tuple = type?.as(TupleTypeSyntax.self), tuple.elements.count == 1 {
            return tuple.elements.first?.type.as(FunctionTypeSyntax.self) != nil
        }

        return false
    }

    var isEscaping: Bool {
        guard let attrType = type?.as(AttributedTypeSyntax.self) else {
            return false
        }

        return attrType.attributes?.contains { attr in
            attr.as(AttributeSyntax.self)?.attributeName.tokenKind == .identifier("escaping")
        } ?? false
    }
}
