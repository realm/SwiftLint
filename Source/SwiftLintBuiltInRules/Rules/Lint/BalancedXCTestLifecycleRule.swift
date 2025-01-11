import SwiftSyntax

@SwiftSyntaxRule(optIn: true)
struct BalancedXCTestLifecycleRule: Rule {
    var configuration = BalancedXCTestLifecycleConfiguration()

    static let description = RuleDescription(
        identifier: "balanced_xctest_lifecycle",
        name: "Balanced XCTest Life Cycle",
        description: "Test classes must implement balanced setUp and tearDown methods",
        rationale: """
        The `setUp` method of `XCTestCase` can be used to set up variables and resources before \
        each test is run (or with the `class` variant, before all tests are run).

        The memory model for XCTestCase objects is non-obvious. An instance of the `XCTestCase` \
        subclass will be created for each test method, and these will persist for the entire test run.

        So in a test class with 10 tests, given

        ```
        private var foo: String = "Bar"
        ```

        "Bar" will be stored 10 times over, but with

        ```
        // swiftlint:disable:next implicitly_unwrapped_optional
        private var foo: String!

        func setUp() {
            foo = "Bar"
        }

        func tearDown() {
            foo = nil
        }
        ```

        no memory will be consumed by the value of the variable.

        More generally, if `setUp` is implemented, then `tearDown` should also be implemented, \
        and cleanup performed there.
        """,
        kind: .lint,
        nonTriggeringExamples: [
            Example(#"""
            final class FooTests: XCTestCase {
                override func setUp() {}
                override func tearDown() {}
            }
            """#),
            Example(#"""
            final class FooTests: XCTestCase {
                override func setUpWithError() throws {}
                override func tearDown() {}
            }
            """#),
            Example(#"""
            final class FooTests: XCTestCase {
                override func setUp() {}
                override func tearDownWithError() throws {}
            }
            """#),
            Example(#"""
            final class FooTests: XCTestCase {
                override func setUpWithError() throws {}
                override func tearDownWithError() throws {}
            }
            final class BarTests: XCTestCase {
                override func setUpWithError() throws {}
                override func tearDownWithError() throws {}
            }
            """#),
            Example(#"""
            struct FooTests {
                override func setUp() {}
            }
            class BarTests {
                override func setUpWithError() throws {}
            }
            """#),
            Example(#"""
            final class FooTests: XCTestCase {
                override func setUpAlLExamples() {}
            }
            """#),
            Example(#"""
            final class FooTests: XCTestCase {
                class func setUp() {}
                class func tearDown() {}
            }
            """#),
        ],
        triggeringExamples: [
            Example(#"""
            final class ↓FooTests: XCTestCase {
                override func setUp() {}
            }
            """#),
            Example(#"""
            final class ↓FooTests: XCTestCase {
                override func setUpWithError() throws {}
            }
            """#),
            Example(#"""
            final class FooTests: XCTestCase {
                override func setUp() {}
                override func tearDownWithError() throws {}
            }
            final class ↓BarTests: XCTestCase {
                override func setUpWithError() throws {}
            }
            """#),
            Example(#"""
            final class ↓FooTests: XCTestCase {
                class func tearDown() {}
            }
            """#),
            Example(#"""
            final class ↓FooTests: XCTestCase {
                override func tearDown() {}
            }
            """#),
            Example(#"""
            final class ↓FooTests: XCTestCase {
                override func tearDownWithError() throws {}
            }
            """#),
            Example(#"""
            final class FooTests: XCTestCase {
                override func setUp() {}
                override func tearDownWithError() throws {}
            }
            final class ↓BarTests: XCTestCase {
                override func tearDownWithError() throws {}
            }
            """#),
        ]
    )
}

// MARK: - Private

private extension BalancedXCTestLifecycleRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override var skippableDeclarations: [any DeclSyntaxProtocol.Type] { .all }

        override func visitPost(_ node: ClassDeclSyntax) {
            guard node.isXCTestCase(configuration.testParentClasses) else {
                return
            }

            let methods = SetupTearDownVisitor(configuration: configuration, file: file)
                .walk(tree: node.memberBlock, handler: \.methods)
            guard methods.contains(.setUp) != methods.contains(.tearDown) else {
                return
            }

            violations.append(node.name.positionAfterSkippingLeadingTrivia)
        }
    }
}

private final class SetupTearDownVisitor<Configuration: RuleConfiguration>: ViolationsSyntaxVisitor<Configuration> {
    override var skippableDeclarations: [any DeclSyntaxProtocol.Type] { .all }
    private(set) var methods: Set<XCTMethod> = []

    override func visitPost(_ node: FunctionDeclSyntax) {
        if let method = XCTMethod(node.name.description),
           node.signature.parameterClause.parameters.isEmpty {
            methods.insert(method)
        }
    }
}

private enum XCTMethod {
    case setUp
    case tearDown

    init?(_ name: String?) {
        switch name {
        case "setUp", "setUpWithError": self = .setUp
        case "tearDown", "tearDownWithError": self = .tearDown
        default: return nil
        }
    }
}
