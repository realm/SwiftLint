import SwiftSyntax

/// Rule to require that any state properties in SwiftUI be declared as private.
/// State properties should only be accessible from inside the View's body, or from methods called by it
struct PrivateSwiftUIStatePropertyRule: SwiftSyntaxRule, OptInRule, ConfigurationProviderRule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "private_swiftui_state",
        name: "Private SwiftUI @State Properties",
        description: "SwiftUI's state properties should be private",
        kind: .lint,
        nonTriggeringExamples: [
            Example("""
            struct ContentView: View {
                @State private var isPlaying: Bool = false
            }
            """
            ),
            Example("""
            struct ContentView: View {
                @State fileprivate var isPlaying: Bool = false
            }
            """
            ),
            Example("""
            struct ContentView: View {
                var isPlaying = false
            }
            """
            ),
            Example("""
            struct ContentView: View {
                @StateObject var foo = Foo()
            }
            """
            )
        ],
        triggeringExamples: [
            Example("""
            struct ContentView: View {
                @State ↓var isPlaying: Bool = false
            }
            """
            )
        ]
    )

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(viewMode: .sourceAccurate)
    }
}

private extension PrivateSwiftUIStatePropertyRule {
    final class Visitor: ViolationsSyntaxVisitor {
        override func visitPost(_ node: MemberDeclListItemSyntax) {
            guard
                let decl = node.decl.as(VariableDeclSyntax.self),
                decl.attributes.hasStateAttribute,
                !decl.modifiers.isPrivateOrFileprivate
            else {
                return
            }

            violations.append(decl.bindingKeyword.positionAfterSkippingLeadingTrivia)
        }
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
