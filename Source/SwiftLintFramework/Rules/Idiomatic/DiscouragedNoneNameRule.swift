import SwiftSyntax

public struct DiscouragedNoneNameRule: SourceKitFreeRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public static var description = RuleDescription(
        identifier: "discouraged_none_name",
        name: "Discouraged None Name",
        description: "Discourages name cases/static members `none`, which can conflict with `Optional<T>.none`.",
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

    public init() {}

    public func validate(file: SwiftLintFile) -> [StyleViolation] {
        Visitor(viewMode: .sourceAccurate)
            .walk(file: file, handler: \.violationPositions)
            .sorted { $0.position < $1.position }
            .map { position, reason in
                StyleViolation(
                    ruleDescription: Self.description,
                    severity: configuration.severity,
                    location: Location(file: file, position: position),
                    reason: reason
                )
            }
    }
}

private extension DiscouragedNoneNameRule {
    final class Visitor: SyntaxVisitor {
        private(set) var violationPositions: [(position: AbsolutePosition, reason: String)] = []

        override func visitPost(_ node: EnumCaseElementSyntax) {
            let emptyParams = node.associatedValue?.parameterList.isEmpty ?? true
            if node.identifier.isNone, emptyParams {
                violationPositions.append((node.positionAfterSkippingLeadingTrivia, reason(type: "`case`")))
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

            guard let type = type else {
                return
            }

            for binding in node.bindings {
                guard let pattern = binding.pattern.as(IdentifierPatternSyntax.self), pattern.identifier.isNone else {
                    continue
                }

                violationPositions.append((node.positionAfterSkippingLeadingTrivia, reason(type: type)))
                return
            }
        }

        private func reason(type: String) -> String {
            let reason = "Avoid naming \(type) `none` as the compiler can think you mean `Optional<T>.none`."
            let recommendation = "Consider using an Optional value instead."
            return "\(reason) \(recommendation)"
        }
    }
}

private extension TokenSyntax {
    var isNone: Bool {
        tokenKind == .identifier("none") || tokenKind == .identifier("`none`")
    }
}

private extension ModifierListSyntax? {
    var isStatic: Bool {
        guard let modifiers = self else {
            return false
        }

        return modifiers.contains { $0.name.tokenKind == .staticKeyword }
    }

    var isClass: Bool {
        guard let modifiers = self else {
            return false
        }

        return modifiers.contains { $0.name.tokenKind == .classKeyword }
    }
}
