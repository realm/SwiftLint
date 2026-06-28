import SwiftSyntax

@SwiftSyntaxRule(optIn: true)
struct ConvenienceTypeRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "convenience_type",
        name: "Convenience Type",
        description: "Types used for hosting only static members should be implemented as a caseless enum " +
                     "to avoid instantiation",
        kind: .idiomatic,
        nonTriggeringExamples: #examples([
            """
            enum Math { // enum
              public static let pi = 3.14
            }
            """,
            """
            // class with inheritance
            class MathViewController: UIViewController {
              public static let pi = 3.14
            }
            """,
            """
            @objc class Math: NSObject { // class visible to Obj-C
              public static let pi = 3.14
            }
            """,
            """
            struct Math { // type with non-static declarations
              public static let pi = 3.14
              public let randomNumber = 2
            }
            """,
            "class DummyClass {}",
            """
            class Foo: NSObject { // class with Obj-C class property
                class @objc let foo = 1
            }
            """,
            """
            class Foo: NSObject { // class with Obj-C static property
                static @objc let foo = 1
            }
            """,
            """
            class Foo { // @objc class func can't exist on an enum
               @objc class func foo() {}
            }
            """,
            """
            class Foo { // @objc static func can't exist on an enum
               @objc static func foo() {}
            }
            """,
            """
            @objcMembers class Foo { // @objc static func can't exist on an enum
               static func foo() {}
            }
            """,
            """
            final class Foo { // final class, but @objc class func can't exist on an enum
               @objc class func foo() {}
            }
            """,
            """
            final class Foo { // final class, but @objc static func can't exist on an enum
               @objc static func foo() {}
            }
            """,
            """
            @globalActor actor MyActor {
              static let shared = MyActor()
            }
            """,
        ]),
        triggeringExamples: #examples([
            """
            ↓struct Math {
              public static let pi = 3.14
            }
            """,
            """
            ↓struct Math {
              public static let pi = 3.14
              @available(*, unavailable) init() {}
            }
            """,
            """
            final ↓class Foo { // final class can't be inherited
                class let foo = 1
            }
            """,

            // Intentional false positives. Non-final classes could be
            // subclassed, but we figure it is probably rare enough that it is
            // more important to catch these cases, and manually disable the
            // rule if needed.

            """
            ↓class Foo {
                class let foo = 1
            }
            """,
            """
            ↓class Foo {
                final class let foo = 1
            }
            """,
            """
            ↓class SomeClass {
                static func foo() {}
            }
            """,
        ])
    )
}

private extension ConvenienceTypeRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override var skippableDeclarations: [any DeclSyntaxProtocol.Type] { [ProtocolDeclSyntax.self] }

        override func visitPost(_ node: StructDeclSyntax) {
            if hasViolation(
                inheritance: node.inheritanceClause,
                attributes: node.attributes,
                members: node.memberBlock
            ) {
                violations.append(node.structKeyword.positionAfterSkippingLeadingTrivia)
            }
        }

        override func visitPost(_ node: ClassDeclSyntax) {
            if hasViolation(
                inheritance: node.inheritanceClause,
                attributes: node.attributes,
                members: node.memberBlock
            ) {
                violations.append(node.classKeyword.positionAfterSkippingLeadingTrivia)
            }
        }

        private func hasViolation(inheritance: InheritanceClauseSyntax?,
                                  attributes: AttributeListSyntax?,
                                  members: MemberBlockSyntax) -> Bool {
            guard inheritance.isNilOrEmpty,
                  attributes?.containsObjcMembers == false,
                  attributes?.containsObjc == false,
                  !members.members.isEmpty else {
                return false
            }

            return ConvenienceTypeCheckVisitor(configuration: configuration, file: file)
                .walk(tree: members, handler: \.canBeConvenienceType)
        }
    }

    final class ConvenienceTypeCheckVisitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override var skippableDeclarations: [any DeclSyntaxProtocol.Type] { .all }

        private(set) var canBeConvenienceType = true

        override func visitPost(_ node: VariableDeclSyntax) {
            if node.isInstanceVariable {
                canBeConvenienceType = false
            } else if node.attributes.containsObjc {
                canBeConvenienceType = false
            }
        }

        override func visitPost(_ node: FunctionDeclSyntax) {
            if node.modifiers.containsStaticOrClass {
                if node.attributes.containsObjc {
                    canBeConvenienceType = false
                }
            } else {
                canBeConvenienceType = false
            }
        }

        override func visitPost(_ node: InitializerDeclSyntax) {
            if !node.attributes.hasUnavailableAttribute {
                canBeConvenienceType = false
            }
        }

        override func visitPost(_ node: SubscriptDeclSyntax) {
            if !node.modifiers.containsStaticOrClass {
                canBeConvenienceType = false
            }
        }
    }
}

private extension InheritanceClauseSyntax? {
    var isNilOrEmpty: Bool {
        self?.inheritedTypes.isEmpty ?? true
    }
}

private extension AttributeListSyntax {
    var containsObjcMembers: Bool {
        contains(attributeNamed: "objcMembers")
    }

    var containsObjc: Bool {
        contains(attributeNamed: "objc")
    }

    var hasUnavailableAttribute: Bool {
        contains { elem in
            guard let attr = elem.as(AttributeSyntax.self),
                  attr.attributeNameText == "available",
                  let arguments = attr.arguments?.as(AvailabilityArgumentListSyntax.self) else {
                return false
            }
            return arguments.contains { $0.argument.as(TokenSyntax.self)?.tokenKind.isUnavailableKeyword == true }
        }
    }
}
