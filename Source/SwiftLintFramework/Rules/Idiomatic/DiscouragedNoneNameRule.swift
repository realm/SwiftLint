import SwiftSyntax

struct DiscouragedNoneNameRule: SwiftSyntaxRule, OptInRule, ConfigurationProviderRule {
    var configuration = SeverityConfiguration(.warning)

    init() {}

    static var description = RuleDescription(
        identifier: "discouraged_none_name",
        name: "Discouraged None Name",
        description: "Enum cases and static members named `none` are discouraged as they can conflict with " +
                     "`Optional<T>.none`.",
        kind: .idiomatic,
        nonTriggeringExamples: [
            // Should not trigger unless exactly matches "none"
            Example("""
            enum MyEnum {
                case nOne
            }
            """),
            Example("""
            enum MyEnum {
                case _none
            }
            """),
            Example("""
            enum MyEnum {
                case none_
            }
            """),
            Example("""
            enum MyEnum {
                case none(Any)
            }
            """),
            Example("""
            enum MyEnum {
                case nonenone
            }
            """),
            Example("""
            class MyClass {
                class var nonenone: MyClass { MyClass() }
            }
            """),
            Example("""
            class MyClass {
                static var nonenone = MyClass()
            }
            """),
            Example("""
            class MyClass {
                static let nonenone = MyClass()
            }
            """),
            Example("""
            struct MyStruct {
                static var nonenone = MyStruct()
            }
            """),
            Example("""
            struct MyStruct {
                static let nonenone = MyStruct()
            }
            """),

            // Should not trigger if not an enum case or static/class member
            Example("""
            struct MyStruct {
                let none = MyStruct()
            }
            """),
            Example("""
            struct MyStruct {
                var none = MyStruct()
            }
            """),
            Example("""
            class MyClass {
                let none = MyClass()
            }
            """),
            Example("""
            class MyClass {
                var none = MyClass()
            }
            """)
        ],
        triggeringExamples: [
            Example("""
            enum MyEnum {
                case ↓none
            }
            """),
            Example("""
            enum MyEnum {
                case a, ↓none
            }
            """),
            Example("""
            enum MyEnum {
                case ↓none, b
            }
            """),
            Example("""
            enum MyEnum {
                case a, ↓none, b
            }
            """),
            Example("""
            enum MyEnum {
                case a
                case ↓none
            }
            """),
            Example("""
            enum MyEnum {
                case ↓none
                case b
            }
            """),
            Example("""
            enum MyEnum {
                case a
                case ↓none
                case b
            }
            """),
            Example("""
            class MyClass {
                ↓static let none = MyClass()
            }
            """),
            Example("""
            class MyClass {
                ↓static let none: MyClass = MyClass()
            }
            """),
            Example("""
            class MyClass {
                ↓static var none: MyClass = MyClass()
            }
            """),
            Example("""
            class MyClass {
                ↓class var none: MyClass { MyClass() }
            }
            """),
            Example("""
            struct MyStruct {
                ↓static var none = MyStruct()
            }
            """),
            Example("""
            struct MyStruct {
                ↓static var none: MyStruct = MyStruct()
            }
            """),
            Example("""
            struct MyStruct {
                ↓static var none = MyStruct()
            }
            """),
            Example("""
            struct MyStruct {
                ↓static var none: MyStruct = MyStruct()
            }
            """),
            Example("""
            struct MyStruct {
                ↓static var a = MyStruct(), none = MyStruct()
            }
            """),
            Example("""
            struct MyStruct {
                ↓static var none = MyStruct(), a = MyStruct()
            }
            """)
        ]
    )

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(viewMode: .sourceAccurate)
    }
}

private extension DiscouragedNoneNameRule {
    final class Visitor: ViolationsSyntaxVisitor {
        override func visitPost(_ node: EnumCaseElementSyntax) {
            let emptyParams = node.associatedValue?.parameterList.isEmpty ?? true
            if emptyParams, node.identifier.isNone {
                violations.append(ReasonedRuleViolation(
                    position: node.positionAfterSkippingLeadingTrivia,
                    reason: reason(type: "`case`")
                ))
            }
        }

        override func visitPost(_ node: VariableDeclSyntax) {
            let type: String? = {
                if node.modifiers.isClass {
                    return "`class` member"
                } else if node.modifiers.isStatic {
                    return "`static` member"
                } else {
                    return nil
                }
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
