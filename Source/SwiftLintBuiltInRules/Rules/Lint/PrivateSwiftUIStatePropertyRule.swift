import SwiftSyntax

/// Require that any state properties in SwiftUI be declared as private
///
/// State properties should only be accessible from inside a SwiftUI App, View, or Scene, or from methods called by it
struct PrivateSwiftUIStatePropertyRule: SwiftSyntaxRule, OptInRule, ConfigurationProviderRule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "private_swiftui_state",
        name: "Private SwiftUI @State Properties",
        description: "SwiftUI state properties should be private",
        kind: .lint,
        nonTriggeringExamples: [
            Example("""
            struct MyApp: App {
                @State private var isPlaying: Bool = false
            }
            """),
            Example("""
            struct MyScene: Scene {
                @State private var isPlaying: Bool = false
            }
            """),
            Example("""
            struct ContentView: View {
                @State private var isPlaying: Bool = false
            }
            """),
            Example("""
            struct ContentView: View {
                @State fileprivate var isPlaying: Bool = false
            }
            """),
            Example("""
            struct MyStruct {
                struct ContentView: View {
                    @State private var isPlaying: Bool = false
                }
            }
            """),
            Example("""
            struct ContentView: View {
                var isPlaying = false
            }
            """),
            Example("""
            struct ContentView: View {
                @StateObject var foo = Foo()
            }
            """),
            Example("""
            struct Foo {
                @State var bar = false
            }
            """),
            Example("""
            class Foo: ObservableObject {
                @State var bar = Bar()
            }
            """),
            Example("""
            extension MyObject {
                struct ContentView: View {
                    @State private var isPlaying: Bool = false
                }
            }
            """),
            Example("""
            actor ContentView: View {
                @State private var isPlaying: Bool = false
            }
            """)
        ],
        triggeringExamples: [
            Example("""
            struct MyApp: App {
                @State ↓var isPlaying: Bool = false
            }
            """),
            Example("""
            struct MyScene: Scene {
                @State ↓var isPlaying: Bool = false
            }
            """),
            Example("""
            struct ContentView: View {
                @State ↓var isPlaying: Bool = false
            }
            """),
            Example("""
            struct MyStruct {
                struct ContentView: View {
                    @State ↓var isPlaying: Bool = false
                }
            }
            """),
            Example("""
            final class ContentView: View {
                @State ↓var isPlaying: Bool = false
            }
            """),
            Example("""
            extension MyObject {
                struct ContentView: View {
                    @State ↓var isPlaying: Bool = false
                }
            }
            """),
            Example("""
            actor ContentView: View {
                @State ↓var isPlaying: Bool = false
            }
            """)
        ]
    )

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(viewMode: .sourceAccurate)
    }
}

private extension PrivateSwiftUIStatePropertyRule {
    final class Visitor: ViolationsSyntaxVisitor {
        override var skippableDeclarations: [DeclSyntaxProtocol.Type] {
            [ProtocolDeclSyntax.self]
        }

        private var isSwiftUIStatefulContext = false

        override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
            isSwiftUIStatefulContext = node.inheritanceClause?.conformsToApplicableSwiftUIProtocol ?? false
            return .visitChildren
        }

        override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
            isSwiftUIStatefulContext = node.inheritanceClause?.conformsToApplicableSwiftUIProtocol ?? false
            return .visitChildren
        }

        override func visit(_ node: ActorDeclSyntax) -> SyntaxVisitorContinueKind {
            isSwiftUIStatefulContext = node.inheritanceClause?.conformsToApplicableSwiftUIProtocol ?? false
            return .visitChildren
        }

        override func visitPost(_ node: MemberDeclListItemSyntax) {
            guard
                let decl = node.decl.as(VariableDeclSyntax.self),
                isSwiftUIStatefulContext,
                decl.attributes.hasStateAttribute,
                !decl.modifiers.isPrivateOrFileprivate
            else {
                return
            }

            violations.append(decl.bindingKeyword.positionAfterSkippingLeadingTrivia)
        }
    }
}

private extension TypeInheritanceClauseSyntax {
    static let applicableSwiftUIProtocols: Set<String> = ["View", "App", "Scene"]

    var conformsToApplicableSwiftUIProtocol: Bool {
        !inheritedTypeCollection.distinctTypeNames.isDisjoint(with: Self.applicableSwiftUIProtocols)
    }
}

private extension InheritedTypeListSyntax {
    var distinctTypeNames: Set<String> {
        Set(typeNames)
    }

    var typeNames: [String] {
        compactMap { $0.typeName.as(SimpleTypeIdentifierSyntax.self) }.map(\.name.text)
    }
}

private extension AttributeListSyntax? {
    /// Returns `true` if the attribute's identifier is equal to "State"
    var hasStateAttribute: Bool {
        guard let attributes = self else { return false }

        return attributes.contains { attr in
            guard let stateAttr = attr.as(AttributeSyntax.self),
                  let identifier = stateAttr.attributeName.as(SimpleTypeIdentifierSyntax.self) else {
                return false
            }

            return identifier.name.text == "State"
        }
    }
}
