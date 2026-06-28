import SwiftSyntax

@SwiftSyntaxRule(optIn: true)
struct DiscouragedNoneNameRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "discouraged_none_name",
        name: "Discouraged None Name",
        description: "Enum cases and static members named `none` are discouraged as they can conflict with " +
                     "`Optional<T>.none`.",
        kind: .idiomatic,
        nonTriggeringExamples: #examples([
            // Should not trigger unless exactly matches "none"
            """
            enum MyEnum {
                case nOne
            }
            """,
            """
            enum MyEnum {
                case _none
            }
            """,
            """
            enum MyEnum {
                case none_
            }
            """,
            """
            enum MyEnum {
                case none(Any)
            }
            """,
            """
            enum MyEnum {
                case nonenone
            }
            """,
            """
            class MyClass {
                class var nonenone: MyClass { MyClass() }
            }
            """,
            """
            class MyClass {
                static var nonenone = MyClass()
            }
            """,
            """
            class MyClass {
                static let nonenone = MyClass()
            }
            """,
            """
            struct MyStruct {
                static var nonenone = MyStruct()
            }
            """,
            """
            struct MyStruct {
                static let nonenone = MyStruct()
            }
            """,

            // Should not trigger if not an enum case or static/class member
            """
            struct MyStruct {
                let none = MyStruct()
            }
            """,
            """
            struct MyStruct {
                var none = MyStruct()
            }
            """,
            """
            class MyClass {
                let none = MyClass()
            }
            """,
            """
            class MyClass {
                var none = MyClass()
            }
            """,
        ]),
        triggeringExamples: #examples([
            """
            enum MyEnum {
                case ↓none
            }
            """,
            """
            enum MyEnum {
                case a, ↓none
            }
            """,
            """
            enum MyEnum {
                case ↓none, b
            }
            """,
            """
            enum MyEnum {
                case a, ↓none, b
            }
            """,
            """
            enum MyEnum {
                case a
                case ↓none
            }
            """,
            """
            enum MyEnum {
                case ↓none
                case b
            }
            """,
            """
            enum MyEnum {
                case a
                case ↓none
                case b
            }
            """,
            """
            class MyClass {
                ↓static let none = MyClass()
            }
            """,
            """
            class MyClass {
                ↓static let none: MyClass = MyClass()
            }
            """,
            """
            class MyClass {
                ↓static var none: MyClass = MyClass()
            }
            """,
            """
            class MyClass {
                ↓class var none: MyClass { MyClass() }
            }
            """,
            """
            struct MyStruct {
                ↓static var none = MyStruct()
            }
            """,
            """
            struct MyStruct {
                ↓static var none: MyStruct = MyStruct()
            }
            """,
            """
            struct MyStruct {
                ↓static var none = MyStruct()
            }
            """,
            """
            struct MyStruct {
                ↓static var none: MyStruct = MyStruct()
            }
            """,
            """
            struct MyStruct {
                ↓static var a = MyStruct(), none = MyStruct()
            }
            """,
            """
            struct MyStruct {
                ↓static var none = MyStruct(), a = MyStruct()
            }
            """,
        ])
    )
}

private extension DiscouragedNoneNameRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: EnumCaseElementSyntax) {
            let emptyParams = node.parameterClause?.parameters.isEmpty ?? true
            if emptyParams, node.name.isNone {
                violations.append(ReasonedRuleViolation(
                    position: node.positionAfterSkippingLeadingTrivia,
                    reason: reason(type: "`case`")
                ))
            }
        }

        override func visitPost(_ node: VariableDeclSyntax) {
            let type: String? = {
                if node.modifiers.contains(keyword: .class) {
                    return "`class` member"
                }
                if node.modifiers.contains(keyword: .static) {
                    return "`static` member"
                }
                return nil
            }()

            guard let type else {
                return
            }

            for binding in node.bindings {
                guard let pattern = binding.pattern.as(IdentifierPatternSyntax.self), pattern.identifier.isNone else {
                    continue
                }

                violations.append(ReasonedRuleViolation(
                    position: node.positionAfterSkippingLeadingTrivia,
                    reason: reason(type: type)
                ))
                return
            }
        }

        private func reason(type: String) -> String {
            let reason = "Avoid naming \(type) `none` as the compiler can think you mean `Optional<T>.none`"
            let recommendation = "consider using an Optional value instead"
            return "\(reason); \(recommendation)"
        }
    }
}

private extension TokenSyntax {
    var isNone: Bool {
        tokenKind == .identifier("none") || tokenKind == .identifier("`none`")
    }
}
