import SwiftSyntax

struct SingleTestClassRule: SourceKitFreeRule, OptInRule {
    var configuration = SingleTestClassConfiguration()

    static let description = RuleDescription(
        identifier: "single_test_class",
        name: "Single Test Class",
        description: "Test files should contain a single QuickSpec or XCTestCase class.",
        kind: .style,
        nonTriggeringExamples: [
            Example("class FooTests {  }"),
            Example("class FooTests: QuickSpec {  }"),
            Example("class FooTests: XCTestCase {  }"),
        ],
        triggeringExamples: [
            Example("""
            ↓class FooTests: QuickSpec {  }
            ↓class BarTests: QuickSpec {  }
            """),
            Example("""
            ↓class FooTests: QuickSpec {  }
            ↓class BarTests: QuickSpec {  }
            ↓class TotoTests: QuickSpec {  }
            """),
            Example("""
            ↓class FooTests: XCTestCase {  }
            ↓class BarTests: XCTestCase {  }
            """),
            Example("""
            ↓class FooTests: XCTestCase {  }
            ↓class BarTests: XCTestCase {  }
            ↓class TotoTests: XCTestCase {  }
            """),
            Example("""
            ↓class FooTests: QuickSpec {  }
            ↓class BarTests: XCTestCase {  }
            """),
            Example("""
            ↓class FooTests: QuickSpec {  }
            ↓class BarTests: XCTestCase {  }
            class TotoTests {  }
            """),
            Example("""
            final ↓class FooTests: QuickSpec {  }
            ↓class BarTests: XCTestCase {  }
            class TotoTests {  }
            """),
        ]
    )

    func validate(file: SwiftLintFile) -> [StyleViolation] {
        let classes = Visitor(configuration: configuration, file: file)
            .walk(tree: file.syntaxTree, handler: \.violations)

        guard classes.count > 1 else { return [] }

        return classes.map { position in
            StyleViolation(ruleDescription: Self.description,
                           severity: configuration.severity,
                           location: Location(file: file, position: position.position),
                           reason: "\(classes.count) test classes found in this file")
        }
    }
}

private extension SingleTestClassRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override var skippableDeclarations: [any DeclSyntaxProtocol.Type] { .all }

        override func visitPost(_ node: ClassDeclSyntax) {
            guard node.inheritanceClause.containsInheritedType(inheritedTypes: configuration.testParentClasses) else {
                return
            }
            violations.append(node.classKeyword.positionAfterSkippingLeadingTrivia)
        }
    }
}
