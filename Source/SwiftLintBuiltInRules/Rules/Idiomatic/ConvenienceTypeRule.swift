import SwiftSyntax

struct ConvenienceTypeRule: SwiftSyntaxRule, OptInRule, ConfigurationProviderRule {
    var configuration = SeverityConfiguration(.warning)

    init() {}

    static let description = RuleDescription(
        identifier: "convenience_type",
        name: "Convenience Type",
        description: "Types used for hosting only static members should be implemented as a caseless enum " +
                     "to avoid instantiation",
        kind: .idiomatic,
        nonTriggeringExamples: [
            Example("""
            enum Math { // enum
              public static let pi = 3.14
            }
            """),
            Example("""
            // class with inheritance
            class MathViewController: UIViewController {
              public static let pi = 3.14
            }
            """),
            Example("""
            @objc class Math: NSObject { // class visible to Obj-C
              public static let pi = 3.14
            }
            """),
            Example("""
            struct Math { // type with non-static declarations
              public static let pi = 3.14
              public let randomNumber = 2
            }
            """),
            Example("class DummyClass {}"),
            Example("""
            class Foo: NSObject { // class with Obj-C class property
                class @objc let foo = 1
            }
            """),
            Example("""
            class Foo: NSObject { // class with Obj-C static property
                static @objc let foo = 1
            }
            """),
            Example("""
            class Foo { // @objc class func can't exist on an enum
               @objc class func foo() {}
            }
            """),
            Example("""
            class Foo { // @objc static func can't exist on an enum
               @objc static func foo() {}
            }
            """),
            Example("""
            @objcMembers class Foo { // @objc static func can't exist on an enum
               static func foo() {}
            }
            """),
            Example("""
            final class Foo { // final class, but @objc class func can't exist on an enum
               @objc class func foo() {}
            }
            """),
            Example("""
            final class Foo { // final class, but @objc static func can't exist on an enum
               @objc static func foo() {}
            }
            """),
            Example("""
            @globalActor actor MyActor {
              static let shared = MyActor()
            }
            """)
        ],
        triggeringExamples: [
            Example("""
            ↓struct Math {
              public static let pi = 3.14
            }
            """),
            Example("""
            ↓struct Math {
              public static let pi = 3.14
              @available(*, unavailable) init() {}
            }
            """),
            Example("""
            final ↓class Foo { // final class can't be inherited
                class let foo = 1
            }
            """),

            // Intentional false positives. Non-final classes could be
            // subclassed, but we figure it is probably rare enough that it is
            // more important to catch these cases, and manually disable the
            // rule if needed.

            Example("""
            ↓class Foo {
                class let foo = 1
            }
            """),
            Example("""
            ↓class Foo {
                final class let foo = 1
            }
            """),
            Example("""
            ↓class SomeClass {
                static func foo() {}
            }
            """)
        ]
    )

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(viewMode: .sourceAccurate)
    }
}

private extension ConvenienceTypeRule {
    final class Visitor: ViolationsSyntaxVisitor {
        override var skippableDeclarations: [DeclSyntaxProtocol.Type] { [ProtocolDeclSyntax.self] }

        override func visitPost(_ node: StructDeclSyntax) {
            if hasViolation(inheritance: node.inheritanceClause, attributes: node.attributes, members: node.members) {
                violations.append(node.structKeyword.positionAfterSkippingLeadingTrivia)
            }
        }

        override func visitPost(_ node: ClassDeclSyntax) {
            if hasViolation(inheritance: node.inheritanceClause, attributes: node.attributes, members: node.members) {
                violations.append(node.classKeyword.positionAfterSkippingLeadingTrivia)
            }
        }

        private func hasViolation(inheritance: TypeInheritanceClauseSyntax?,
                                  attributes: AttributeListSyntax?,
                                  members: MemberDeclBlockSyntax) -> Bool {
            guard inheritance.isNilOrEmpty,
                  !attributes.containsObjcMembers,
                  !attributes.containsObjc,
                  !members.members.isEmpty else {
                return false
            }

            return ConvenienceTypeCheckVisitor(viewMode: .sourceAccurate)
                .walk(tree: members, handler: \.canBeConvenienceType)
        }
    }
}

private class ConvenienceTypeCheckVisitor: ViolationsSyntaxVisitor {
    override var skippableDeclarations: [DeclSyntaxProtocol.Type] { .all }

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

private extension TypeInheritanceClauseSyntax? {
    var isNilOrEmpty: Bool {
        self?.inheritedTypeCollection.isEmpty ?? true
    }
}

private extension AttributeListSyntax? {
    var containsObjcMembers: Bool {
        self?.contains { elem in
            elem.as(AttributeSyntax.self)?.attributeName.tokenKind == .identifier("objcMembers")
        } ?? false
    }

    var containsObjc: Bool {
        self?.contains { elem in
            elem.as(AttributeSyntax.self)?.attributeName.tokenKind == .contextualKeyword("objc")
        } ?? false
    }
}

private extension AttributeListSyntax? {
    var hasUnavailableAttribute: Bool {
        guard let attrs = self else {
            return false
        }

        return attrs.contains { elem in
            guard let attr = elem.as(AttributeSyntax.self),
                    let arguments = attr.argument?.as(AvailabilitySpecListSyntax.self) else {
                return false
            }

            return attr.attributeName.tokenKind == .contextualKeyword("available") && arguments.contains { arg in
                arg.entry.as(TokenSyntax.self)?.tokenKind == .contextualKeyword("unavailable")
            }
        }
    }
}
