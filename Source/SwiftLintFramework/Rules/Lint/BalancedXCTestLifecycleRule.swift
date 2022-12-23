import SwiftSyntax

struct BalancedXCTestLifecycleRule: SwiftSyntaxRule, OptInRule, ConfigurationProviderRule {
    // MARK: - Properties

    var configuration = BalancedXCTestLifecycleConfiguration()

    static let description = RuleDescription(
        identifier: "balanced_xctest_lifecycle",
        name: "Balanced XCTest Life Cycle",
        description: "Test classes must implement balanced setUp and tearDown methods",
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
            """#)
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
            """#)
        ]
    )

    // MARK: - Life cycle

    init() {}

    // MARK: - Public

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(viewMode: .sourceAccurate, testClasses: configuration.testParentClasses)
    }
}

private extension BalancedXCTestLifecycleRule {
    final class Visitor: ViolationsSyntaxVisitor {
        private let testClasses: Set<String>
        override var skippableDeclarations: [DeclSyntaxProtocol.Type] { .all }

        init(viewMode: SyntaxTreeViewMode, testClasses: Set<String>) {
            self.testClasses = testClasses
            super.init(viewMode: viewMode)
        }

        override func visitPost(_ node: ClassDeclSyntax) {
            guard node.isXCTestCase(testClasses) else {
                return
            }

            let methods = SetupTearDownVisitor(viewMode: .sourceAccurate)
                .walk(tree: node.members, handler: \.methods)
            guard methods.contains(.setUp) != methods.contains(.tearDown) else {
                return
            }

            violations.append(node.identifier.positionAfterSkippingLeadingTrivia)
        }
    }

    final class SetupTearDownVisitor: ViolationsSyntaxVisitor {
        override var skippableDeclarations: [DeclSyntaxProtocol.Type] { .all }
        private(set) var methods: Set<XCTMethod> = []

        override func visitPost(_ node: FunctionDeclSyntax) {
            if let method = XCTMethod(node.identifier.description),
               node.signature.input.parameterList.isEmpty {
                methods.insert(method)
            }
        }
    }
}

// MARK: - Private

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
