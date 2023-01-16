import Foundation
import SwiftSyntax

struct PrivateUnitTestRule: SwiftSyntaxCorrectableRule, ConfigurationProviderRule, CacheDescriptionProvider {
    var configuration: PrivateUnitTestConfiguration = {
        var configuration = PrivateUnitTestConfiguration(identifier: "private_unit_test")
        configuration.message = "Unit test marked `private` will not be run by XCTest."
        configuration.regex = regex("XCTestCase")
        return configuration
    }()

    var cacheDescription: String {
        return configuration.cacheDescription
    }

    init() {}

    static let description = RuleDescription(
        identifier: "private_unit_test",
        name: "Private Unit Test",
        description: "Unit tests marked private are silently skipped",
        kind: .lint,
        nonTriggeringExamples: [
            Example("""
            class FooTest: XCTestCase {
                func test1() {}
                internal func test2() {}
                public func test3() {}
            }
            """),
            Example("""
            internal class FooTest: XCTestCase {
                func test1() {}
                internal func test2() {}
                public func test3() {}
            }
            """),
            Example("""
            public class FooTest: XCTestCase {
                func test1() {}
                internal func test2() {}
                public func test3() {}
            }
            """),
            Example("""
            @objc private class FooTest: XCTestCase {
                @objc private func test1() {}
                internal func test2() {}
                public func test3() {}
            }
            """),
            // Non-test classes
            Example("""
            private class Foo: NSObject {
                func test1() {}
                internal func test2() {}
                public func test3() {}
            }
            """),
            Example("""
            private class Foo {
                func test1() {}
                internal func test2() {}
                public func test3() {}
            }
            """),
            // Non-test methods
            Example("""
            public class FooTest: XCTestCase {
                private func test1(param: Int) {}
                private func test2() -> String { "" }
                private func atest() {}
                private static func test3() {}
            }
            """)
        ],
        triggeringExamples: [
            Example("""
            private ↓class FooTest: XCTestCase {
                func test1() {}
                internal func test2() {}
                public func test3() {}
                private func test4() {}
            }
            """),
            Example("""
            class FooTest: XCTestCase {
                func test1() {}
                internal func test2() {}
                public func test3() {}
                private ↓func test4() {}
            }
            """),
            Example("""
            internal class FooTest: XCTestCase {
                func test1() {}
                internal func test2() {}
                public func test3() {}
                private ↓func test4() {}
            }
            """),
            Example("""
            public class FooTest: XCTestCase {
                func test1() {}
                internal func test2() {}
                public func test3() {}
                private ↓func test4() {}
            }
            """)
        ],
        corrections: [
            Example("""

                ↓private class Test: XCTestCase {}
                """): Example("""

                    class Test: XCTestCase {}
                    """),
            Example("""
                class Test: XCTestCase {

                    ↓private func test1() {}
                    private func test2(i: Int) {}
                    @objc private func test3() {}
                    internal func test4() {}
                }
                """): Example("""
                    class Test: XCTestCase {

                        func test1() {}
                        private func test2(i: Int) {}
                        @objc private func test3() {}
                        internal func test4() {}
                    }
                    """)
        ]
    )

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(parentClassRegex: configuration.regex)
    }

    func makeRewriter(file: SwiftLintFile) -> ViolationsSyntaxRewriter? {
        Rewriter(
            parentClassRegex: configuration.regex,
            locationConverter: file.locationConverter,
            disabledRegions: disabledRegions(file: file)
        )
    }
}

private class Visitor: ViolationsSyntaxVisitor {
    private let parentClassRegex: NSRegularExpression

    override var skippableDeclarations: [DeclSyntaxProtocol.Type] { .all }

    init(parentClassRegex: NSRegularExpression) {
        self.parentClassRegex = parentClassRegex
        super.init(viewMode: .sourceAccurate)
    }

    override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
        !node.isPrivate && node.hasParent(matching: parentClassRegex) ? .visitChildren : .skipChildren
    }

    override func visitPost(_ node: ClassDeclSyntax) {
        if node.isPrivate, node.hasParent(matching: parentClassRegex) {
            violations.append(node.classKeyword.positionAfterSkippingLeadingTrivia)
        }
    }

    override func visitPost(_ node: FunctionDeclSyntax) {
        if node.isTestMethod, node.isPrivate {
            violations.append(node.funcKeyword.positionAfterSkippingLeadingTrivia)
        }
    }
}

private class Rewriter: SyntaxRewriter, ViolationsSyntaxRewriter {
    private(set) var correctionPositions: [AbsolutePosition] = []
    private let parentClassRegex: NSRegularExpression
    let locationConverter: SourceLocationConverter
    let disabledRegions: [SourceRange]

    init(parentClassRegex: NSRegularExpression,
         locationConverter: SourceLocationConverter,
         disabledRegions: [SourceRange]) {
        self.parentClassRegex = parentClassRegex
        self.locationConverter = locationConverter
        self.disabledRegions = disabledRegions
    }

    override func visit(_ node: ClassDeclSyntax) -> DeclSyntax {
        guard
            node.isPrivate,
            node.hasParent(matching: parentClassRegex),
            !node.isContainedIn(regions: disabledRegions, locationConverter: locationConverter)
        else {
            return super.visit(node)
        }

        correctionPositions.append(node.positionAfterSkippingLeadingTrivia)
        let (modifiers, declKeyword) = withoutPrivate(modifiers: node.modifiers, declKeyword: node.classKeyword)
        return super.visit(node.withModifiers(modifiers).withClassKeyword(declKeyword))
    }

    override func visit(_ node: FunctionDeclSyntax) -> DeclSyntax {
        guard
            node.isTestMethod,
            node.isPrivate,
            !node.isContainedIn(regions: disabledRegions, locationConverter: locationConverter)
        else {
            return super.visit(node)
        }

        correctionPositions.append(node.positionAfterSkippingLeadingTrivia)
        let (modifiers, declKeyword) = withoutPrivate(modifiers: node.modifiers, declKeyword: node.funcKeyword)
        return super.visit(node.withModifiers(modifiers).withFuncKeyword(declKeyword))
    }

    private func withoutPrivate(modifiers: ModifierListSyntax?,
                                declKeyword: TokenSyntax) -> (ModifierListSyntax?, TokenSyntax) {
        guard let modifiers else {
            return (nil, declKeyword)
        }
        var filteredModifiers = [DeclModifierSyntax]()
        var leadingTrivia = Trivia.zero
        for modifier in modifiers {
            let accumulatedLeadingTrivia = leadingTrivia + (modifier.leadingTrivia ?? .zero)
            if modifier.name.tokenKind == .privateKeyword {
                leadingTrivia = accumulatedLeadingTrivia
            } else {
                filteredModifiers.append(modifier.withLeadingTrivia(accumulatedLeadingTrivia))
                leadingTrivia = .zero
            }
        }
        let declKeyword = declKeyword.withLeadingTrivia(leadingTrivia + (declKeyword.leadingTrivia ?? .zero))
        return (ModifierListSyntax(filteredModifiers), declKeyword)
    }
}

private extension ClassDeclSyntax {
    func hasParent(matching pattern: NSRegularExpression) -> Bool {
        inheritanceClause?.inheritedTypeCollection.contains { type in
            if let name = type.typeName.as(SimpleTypeIdentifierSyntax.self)?.name.text {
                return pattern.numberOfMatches(in: name, range: name.fullNSRange) > 0
            }
            return false
        } ?? false
    }

    var isPrivate: Bool {
        resultInPrivateProperty(modifiers: modifiers, attributes: attributes)
    }
}

private extension FunctionDeclSyntax {
    var isPrivate: Bool {
        resultInPrivateProperty(modifiers: modifiers, attributes: attributes)
    }

    var isTestMethod: Bool {
        identifier.text.hasPrefix("test")
            && signature.input.parameterList.isEmpty
            && signature.output == nil
            && !(modifiers?.hasStatic ?? false)
    }
}

private extension ModifierListSyntax {
    var hasPrivate: Bool {
        contains { $0.name.tokenKind == .privateKeyword }
    }

    var hasStatic: Bool {
        contains { $0.name.tokenKind == .staticKeyword }
    }
}

private func resultInPrivateProperty(modifiers: ModifierListSyntax?, attributes: AttributeListSyntax?) -> Bool {
    guard let modifiers, modifiers.hasPrivate else {
        return false
    }
    guard let attributes else {
        return true
    }
    return !attributes.contains { $0.as(AttributeSyntax.self)?.attributeName.tokenKind == .contextualKeyword("objc") }
}
