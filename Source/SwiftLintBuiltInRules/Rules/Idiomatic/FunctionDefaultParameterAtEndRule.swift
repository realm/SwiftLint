import SwiftSyntax

@SwiftSyntaxRule
struct FunctionDefaultParameterAtEndRule: OptInRule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "function_default_parameter_at_end",
        name: "Function Default Parameter at End",
        description: "Prefer to locate parameters with defaults toward the end of the parameter list",
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
            """),
            Example("""
            func expect<T>(file: String = #file, _ expression: @autoclosure () -> (() throws -> T)) -> Expectation<T> {}
            """, excludeFromDocumentation: true),
            Example("func foo(bar: Int, baz: Int = 0, z: () -> Void) {}"),
            Example("func foo(bar: Int, baz: Int = 0, z: () -> Void, x: Int = 0) {}"),
        ],
        triggeringExamples: [
            Example("func foo(↓bar: Int = 0, baz: String) {}"),
            Example("private func foo(↓bar: Int = 0, baz: String) {}"),
            Example("public init?(↓for date: Date = Date(), coordinate: CLLocationCoordinate2D) {}"),
            Example("func foo(bar: Int, ↓baz: Int = 0, z: () -> Void, x: Int) {}"),
        ]
    )
}

private extension FunctionDefaultParameterAtEndRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: FunctionDeclSyntax) {
            if !node.modifiers.contains(keyword: .override) {
                collectViolations(for: node.signature)
            }
        }

        override func visitPost(_ node: InitializerDeclSyntax) {
            if !node.modifiers.contains(keyword: .override) {
                collectViolations(for: node.signature)
            }
        }

        private func collectViolations(for signature: FunctionSignatureSyntax) {
            if signature.parameterClause.parameters.count < 2 {
                return
            }
            var previousWithDefault = true
            for param in signature.parameterClause.parameters.reversed() {
                if param.isClosure {
                    continue
                }
                let hasDefault = param.defaultValue != nil
                if !previousWithDefault, hasDefault {
                    violations.append(param.positionAfterSkippingLeadingTrivia)
                }
                previousWithDefault = hasDefault
            }
        }
    }
}

private extension FunctionParameterSyntax {
    var isClosure: Bool {
        isEscaping || type.isFunctionType
    }

    var isEscaping: Bool {
        type.as(AttributedTypeSyntax.self)?.attributes.contains(attributeNamed: "escaping") == true
    }
}

private extension TypeSyntax {
    var isFunctionType: Bool {
        if `is`(FunctionTypeSyntax.self) {
            true
        } else if let optionalType = `as`(OptionalTypeSyntax.self) {
            optionalType.wrappedType.isFunctionType
        } else if let tupleType = `as`(TupleTypeSyntax.self) {
            tupleType.elements.onlyElement?.type.isFunctionType == true
        } else if let attributedType = `as`(AttributedTypeSyntax.self) {
            attributedType.baseType.isFunctionType
        } else {
            false
        }
    }
}
