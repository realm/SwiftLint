
import SwiftSyntax
import SourceKittenFramework

struct ImplicitlyUnwrapWeakVariableRule: ConfigurationProviderRule, SwiftSyntaxRule, OptInRule {
    
    var configuration = SeverityConfiguration(.warning)
    
    static var description = RuleDescription(
        identifier: "implicitly_unwrapped_weak",
        name: "Implicitly Unwrapped Weak Variable",
        description: "Implicitly unwrapped weak variable should be avoided, use ? instead",
        kind: .lint,
        nonTriggeringExamples: [
            Example("""
            class Foo {
              weak var bar: SomeObject?
            }
            """),
            Example("""
            class Foo {
              @IBOutlet
              weak var button: UIButton!
            }
            """)
        ],
        triggeringExamples: [
            Example("""
            class Foo {
              weak var bar: SomeObject!↓
            }
            """),
            Example("""
            struct Foo {
              weak var bar: SomeObject!↓
            }
            """)
        ]
    )
    
    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(viewMode: .sourceAccurate)
    }
}

private extension ImplicitlyUnwrapWeakVariableRule {
    final class Visitor: ViolationsSyntaxVisitor {
        
        override func visitPost(_ node: VariableDeclSyntax) {
            guard !node.isIBOutlet, node.weakOrUnownedModifier != nil else {
                return
            }
            
            if node.bindings.first?.typeAnnotation?.type.as(ImplicitlyUnwrappedOptionalTypeSyntax.self) != nil {
                violations.append(node.endPositionBeforeTrailingTrivia)
            }
        }
    }
}
