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
            """),
            Example("""
            extension Foo {
              internal private(set) var bar: Int {
                get { Foo.shared.bar }
                set { Foo.shared.bar = newValue }
              }
            }
            """),
            Example("""
            extension Foo {
              private(set) internal var bar: Int {
                get { Foo.shared.bar }
                set { Foo.shared.bar = newValue }
              }
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
            """),
            Example("""
            ↓extension Foo {
               #if DEBUG
               public var bar: Int {
                  let value = 1
                  return value
               }
               #endif

               public var baz: Int { return 1 }
            }
            """),
            Example("""
            public extension Foo {
              ↓private func bar() {}
              ↓private func baz() {}
            }
            """)
        ]
    )
}

private extension ExtensionAccessModifierRule {
    private enum ACL: Hashable {
        case implicit
        case explicit(TokenKind)

        static func from(tokenKind: TokenKind?) -> ACL {
            switch tokenKind {
            case nil:
                return .implicit
            case let value?:
                return .explicit(value)
            }
        }
    }

    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override var skippableDeclarations: [any DeclSyntaxProtocol.Type] { .all }

        override func visitPost(_ node: ExtensionDeclSyntax) {
            guard node.inheritanceClause == nil else {
                return
            }

            var areAllACLsEqual = true
            var aclTokens: [(position: AbsolutePosition, acl: ACL)] = []

            for decl in node.memberBlock.expandingIfConfigs() {
                let modifiers = decl.asProtocol((any WithModifiersSyntax).self)?.modifiers
                let aclToken = modifiers?.accessLevelModifier?.name
                let acl = ACL.from(tokenKind: aclToken?.tokenKind)
                if acl != aclTokens.last?.acl, aclTokens.isNotEmpty {
                    areAllACLsEqual = false
                }

                aclTokens.append((decl.positionAfterSkippingLeadingTrivia, acl))
            }

            guard areAllACLsEqual, let lastACL = aclTokens.last else {
                return
            }

            let allowedACLs: Set<ACL> = [
                .explicit(.keyword(.internal)),
                .explicit(.keyword(.private)),
                .explicit(.keyword(.open)),
                .implicit
            ]
            let iAllowedACL = allowedACLs.contains(lastACL.acl)
            let extensionACL = ACL.from(tokenKind: node.modifiers.accessLevelModifier?.name.tokenKind)

            if extensionACL != .implicit {
                if !iAllowedACL || lastACL.acl != extensionACL {
                    let positions = aclTokens.filter { $0.acl != .implicit }.map(\.position)
                    violations.append(contentsOf: positions)
                }
            } else if !iAllowedACL {
                violations.append(node.extensionKeyword.positionAfterSkippingLeadingTrivia)
            }
        }
    }
}

private extension MemberBlockSyntax {
    func expandingIfConfigs() -> [DeclSyntax] {
        members.flatMap { member in
            if let ifConfig = member.decl.as(IfConfigDeclSyntax.self) {
                return ifConfig.clauses.flatMap { clause in
                    switch clause.elements {
                    case .decls(let decls):
                        return decls.map(\.decl)
                    default:
                        return []
                    }
                }
            } else {
                return [member.decl]
            }
        }
    }
}
