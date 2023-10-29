import Foundation
import SourceKittenFramework
import SwiftSyntax

@SwiftSyntaxRule
struct ExtensionAccessModifierRule: Rule, OptInRule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "extension_access_modifier",
        name: "Extension Access Modifier",
        description: "Prefer to use extension access modifiers",
        kind: .idiomatic,
        nonTriggeringExamples: [
            Example("""
            extension Foo: SomeProtocol {
              public var bar: Int { return 1 }
            }
            """),
            Example("""
            extension Foo {
              private var bar: Int { return 1 }
              public var baz: Int { return 1 }
            }
            """),
            Example("""
            extension Foo {
              private var bar: Int { return 1 }
              public func baz() {}
            }
            """),
            Example("""
            extension Foo {
              var bar: Int { return 1 }
              var baz: Int { return 1 }
            }
            """),
            Example("""
            extension Foo {
              var bar: Int { return 1 }
              internal var baz: Int { return 1 }
            }
            """),
            Example("""
            internal extension Foo {
              var bar: Int { return 1 }
              var baz: Int { return 1 }
            }
            """),
            Example("""
            public extension Foo {
              var bar: Int { return 1 }
              var baz: Int { return 1 }
            }
            """),
            Example("""
            public extension Foo {
              var bar: Int { return 1 }
              internal var baz: Int { return 1 }
            }
            """),
            Example("""
            extension Foo {
              private var bar: Int { return 1 }
              private var baz: Int { return 1 }
            }
            """),
            Example("""
            extension Foo {
              open var bar: Int { return 1 }
              open var baz: Int { return 1 }
            }
            """),
            Example("""
            extension Foo {
                func setup() {}
                public func update() {}
            }
            """),
            Example("""
            private extension Foo {
              private var bar: Int { return 1 }
              var baz: Int { return 1 }
            }
            """)
        ],
        triggeringExamples: [
            Example("""
            ↓extension Foo {
               public var bar: Int { return 1 }
               public var baz: Int { return 1 }
            }
            """),
            Example("""
            ↓extension Foo {
               public var bar: Int { return 1 }
               public func baz() {}
            }
            """),
            Example("""
            public extension Foo {
              ↓public func bar() {}
              ↓public func baz() {}
            }
            """),
            Example("""
            ↓extension Foo {
               public var bar: Int {
                  let value = 1
                  return value
               }

               public var baz: Int { return 1 }
            }
            """),
            Example("""
            ↓extension Array where Element: Equatable {
                public var unique: [Element] {
                    var uniqueValues = [Element]()
                    for item in self where !uniqueValues.contains(item) {
                        uniqueValues.append(item)
                    }
                    return uniqueValues
                }
            }
            """)
        ]
    )
}

private extension ExtensionAccessModifierRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override var skippableDeclarations: [any DeclSyntaxProtocol.Type] { .all }

        override func visitPost(_ node: ExtensionDeclSyntax) {
            guard node.inheritanceClause == nil else {
                return
            }

            if let modifier = node.modifiers.accessLevelModifier {
                validateNestedDeclsShouldNotHaveACL(node: node, extensionACL: modifier)
            } else {
                validateExtensionShouldHaveACL(node: node)
            }
        }

        private func validateExtensionShouldHaveACL(node: ExtensionDeclSyntax) {
            var previousACL: TokenKind?
            var areAllACLsEqual = true

            for member in node.memberBlock.members {
                let modifiers = member.decl.asProtocol((any WithModifiersSyntax).self)?.modifiers
                let acl = modifiers?.accessLevelModifier?.name.tokenKind ?? .keyword(.internal)
                if acl != previousACL, previousACL != nil {
                    areAllACLsEqual = false
                    break
                }

                previousACL = acl
            }

            let allowedACLs: Set<TokenKind> = [.keyword(.internal), .keyword(.private), .keyword(.open)]
            if areAllACLsEqual, let previousACL, !allowedACLs.contains(previousACL) {
                violations.append(node.extensionKeyword.positionAfterSkippingLeadingTrivia)
            }
        }

        private func validateNestedDeclsShouldNotHaveACL(node: ExtensionDeclSyntax,
                                                         extensionACL: DeclModifierSyntax) {
            guard extensionACL.name.tokenKind != .keyword(.private) else {
                return
            }

            let positions = node.memberBlock.members.compactMap { member -> AbsolutePosition? in
                let modifiers = member.decl.asProtocol((any WithModifiersSyntax).self)?.modifiers
                let aclToken = modifiers?.accessLevelModifier?.name
                let acl = aclToken?.tokenKind ?? .keyword(.internal)
                guard acl == extensionACL.name.tokenKind, let aclToken else {
                    return nil
                }

                return aclToken.positionAfterSkippingLeadingTrivia
            }
            violations.append(contentsOf: positions)
        }
    }
}
