import SwiftSyntax

struct SingleTestClassRule: SourceKitFreeRule, OptInRule, ConfigurationProviderRule {
    var configuration = SingleTestClassConfiguration()

    static let description = RuleDescription(
        identifier: "single_test_class",
        name: "Single Test Class",
        description: "Test files should contain a single QuickSpec or XCTestCase class.",
        kind: .style,
        nonTriggeringExamples: [
            Example("class FooTests {  }"),
            Example("class FooTests: QuickSpec {  }"),
            Example("class FooTests: XCTestCase {  }")
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
            """)
        ]
    )

    func validate(file: SwiftLintFile) -> [StyleViolation] {
        let classes = TestClassVisitor(viewMode: .sourceAccurate, testParentClasses: configuration.testParentClasses)
            .walk(tree: file.syntaxTree, handler: \.violations)

        guard classes.count > 1 else { return [] }

        return classes.map { position in
            return StyleViolation(ruleDescription: Self.description,
                                  severity: configuration.severity,
                                  location: Location(file: file, position: position.position),
                                  reason: "\(classes.count) test classes found in this file")
        }
    }
}

private class TestClassVisitor: ViolationsSyntaxVisitor {
    private let testParentClasses: Set<String>
    override var skippableDeclarations: [any DeclSyntaxProtocol.Type] { .all }

    init(viewMode: SyntaxTreeViewMode, testParentClasses: Set<String>) {
        self.testParentClasses = testParentClasses
        super.init(viewMode: viewMode)
    }

    override func visitPost(_ node: ClassDeclSyntax) {
        guard node.inheritanceClause.containsInheritedType(inheritedTypes: testParentClasses) else {
            return
        }

        violations.append(node.classKeyword.positionAfterSkippingLeadingTrivia)
    }
}
