import SwiftSyntax

public struct SingleTestClassRule: Rule, OptInRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public static let description = RuleDescription(
        identifier: "single_test_class",
        name: "Single Test Class",
        description: "Test files should contain a single QuickSpec or XCTestCase class.",
        kind: .style,
        nonTriggeringExamples: [
            Example("class FooTests {  }\n"),
            Example("class FooTests: QuickSpec {  }\n"),
            Example("class FooTests: XCTestCase {  }\n")
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

    public init() {}

    public func validate(file: SwiftLintFile) -> [StyleViolation] {
        let classes = TestClassVisitor(viewMode: .sourceAccurate)
            .walk(tree: file.syntaxTree, handler: \.violations)

        guard classes.count > 1 else { return [] }

        return classes.map { position in
            return StyleViolation(ruleDescription: Self.description,
                                  severity: configuration.severity,
                                  location: Location(file: file, position: position.position),
                                  reason: "\(classes.count) test classes found in this file.")
        }
    }
}

private class TestClassVisitor: ViolationsSyntaxVisitor {
    private let testClasses: Set = ["QuickSpec", "XCTestCase"]
    override var skippableDeclarations: [DeclSyntaxProtocol.Type] { .all }

    override func visitPost(_ node: ClassDeclSyntax) {
        guard let inheritanceCollection = node.inheritanceClause?.inheritedTypeCollection,
              inheritanceCollection.containsInheritedType(inheritedTypes: testClasses) else {
            return
        }

        violations.append(node.classKeyword.positionAfterSkippingLeadingTrivia)
    }
}

private extension InheritedTypeListSyntax {
    func containsInheritedType(inheritedTypes: Set<String>) -> Bool {
        contains { elem in
            guard let simpleType = elem.typeName.as(SimpleTypeIdentifierSyntax.self) else {
                return false
            }

            return inheritedTypes.contains(simpleType.name.text)
        }
    }
}
