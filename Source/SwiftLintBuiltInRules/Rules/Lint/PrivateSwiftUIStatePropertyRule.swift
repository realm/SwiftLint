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
            struct ContentView: View {
                @State private var isPlaying: Bool = false

                struct InnerView: View {
                    @State private var showsIndicator: Bool = false
                }
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
            struct MyStruct {
                struct ContentView: View {
                    @State private var isPlaying: Bool = false
                }

                @State var nonTriggeringState: Bool = false
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
            struct ContentView: View {
                struct InnerView: View {
                    @State private var showsIndicator: Bool = false
                }

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
            struct MyStruct {
                struct ContentView: View {
                    @State ↓var isPlaying: Bool = false
                }

                @State var isPlaying: Bool = false
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

        /// LIFO stack that stores type inheritance clauses for each visited node
        /// The last value is the inheritance clause for the most recently visited node
        /// A nil value indicates that the node does not provide any inheritance clause
        private var visitedTypeInheritances = Stack<InheritanceClauseSyntax?>()

        override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
            visitedTypeInheritances.push(node.inheritanceClause)
            return .visitChildren
        }

        override func visitPost(_ node: ClassDeclSyntax) {
            visitedTypeInheritances.pop()
        }

        override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
            visitedTypeInheritances.push(node.inheritanceClause)
            return .visitChildren
        }

        override func visitPost(_ node: StructDeclSyntax) {
            visitedTypeInheritances.pop()
        }

        override func visit(_ node: ActorDeclSyntax) -> SyntaxVisitorContinueKind {
            visitedTypeInheritances.push(node.inheritanceClause)
            return .visitChildren
        }

        override func visitPost(_ node: ActorDeclSyntax) {
            visitedTypeInheritances.pop()
        }

        override func visitPost(_ node: MemberBlockItemSyntax) {
            guard
                let decl = node.decl.as(VariableDeclSyntax.self),
                let inheritanceClause = visitedTypeInheritances.peek() as? InheritanceClauseSyntax,
                inheritanceClause.conformsToApplicableSwiftUIProtocol,
                decl.attributes.hasStateAttribute,
                !decl.modifiers.isPrivateOrFileprivate
            else {
                return
            }

            violations.append(decl.bindingSpecifier.positionAfterSkippingLeadingTrivia)
        }
    }
}

private extension InheritanceClauseSyntax {
    static let applicableSwiftUIProtocols: Set<String> = ["View", "App", "Scene"]

    var conformsToApplicableSwiftUIProtocol: Bool {
        inheritedTypes.containsInheritedType(inheritedTypes: Self.applicableSwiftUIProtocols)
    }
}

private extension InheritedTypeListSyntax {
    func containsInheritedType(inheritedTypes: Set<String>) -> Bool {
        contains {
            guard let simpleType = $0.type.as(IdentifierTypeSyntax.self) else { return false }

            return inheritedTypes.contains(simpleType.name.text)
        }
    }
}

private extension AttributeListSyntax? {
    /// Returns `true` if the attribute's identifier is equal to "State"
    var hasStateAttribute: Bool {
        guard let attributes = self else { return false }

        return attributes.contains { attr in
            guard let stateAttr = attr.as(AttributeSyntax.self),
                  let identifier = stateAttr.attributeName.as(IdentifierTypeSyntax.self) else {
                return false
            }

            return identifier.name.text == "State"
        }
    }
}
