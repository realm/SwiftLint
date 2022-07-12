@testable import SwiftLintFramework
import SwiftSyntax
import SwiftSyntaxParser
import XCTest

final class DeclVisitorTests: XCTestCase {
    private typealias SourceCreator = (String) -> (String)

    func testVisitDefaultAttributesGetsAll() {
        let makeSource: SourceCreator = { type in
            """
                \(type) A {
                    \(type) B {

                    }
                }
                // comments
                private \(type) C {}
                public \(type) D {}
            """
        }

        testDeclVisitorOnAllTypes(with: DeclVisitor.Attributes(), makeSource: makeSource, expectedViolationCount: 4)
    }

    func testVisitInheritance() {
        let makeSource: SourceCreator = { type in
            """
                \(type) A: Parent {
            """
        }

        let attributes = DeclVisitor.Attributes(inheritsFrom: ["Parent"])
        testDeclVisitorOnAllTypes(with: attributes, makeSource: makeSource, expectedViolationCount: 1)
    }

    func testVisitSkipInheritance() {
        let makeSource: SourceCreator = { type in
           """
               \(type) A: Parent {}
               \(type) B {}
               \(type) C: NonParent {}
           """
        }

        let attributes = DeclVisitor.Attributes(skipIfInheritsFrom: ["Parent"])
        testDeclVisitorOnAllTypes(with: attributes, makeSource: makeSource, expectedViolationCount: 2)
    }

    func testVisitSkipInheritanceAndLookForInheritedType() {
        let makeSource: SourceCreator = { type in
            """
                \(type) A: Foo, Parent {}
                \(type) B: Foo {}
            """
        }

        let attributes = DeclVisitor.Attributes(skipIfInheritsFrom: ["Parent"], inheritsFrom: ["Foo"])
        testDeclVisitorOnAllTypes(with: attributes, makeSource: makeSource, expectedViolationCount: 1)
    }

    func testVisitPublic() {
        let makeSource: SourceCreator = { type in
            """
                private \(type) A {}
                \(type) B {}
                private \(type) C {}
                public \(type) D {}
                open \(type) E {}
            """
        }

        var attributes = DeclVisitor.Attributes(accessControl: .private)
        testDeclVisitorOnAllTypes(with: attributes, makeSource: makeSource, expectedViolationCount: 2)

        attributes = DeclVisitor.Attributes(accessControl: .public)
        testDeclVisitorOnAllTypes(with: attributes, makeSource: makeSource, expectedViolationCount: 1)

        attributes = DeclVisitor.Attributes(accessControl: .open)
        testDeclVisitorOnAllTypes(with: attributes, makeSource: makeSource, expectedViolationCount: 1)
    }

    func testVisitAllNodesWhenAccessControlIsNotSpecified() {
        let makeSource: SourceCreator = { type in
            """
                private \(type) A {}
                \(type) B {}
                private \(type) C {}
                public \(type) D {}
                open \(type) E {}
            """
        }

        let attributes = DeclVisitor.Attributes()
        testDeclVisitorOnAllTypes(with: attributes, makeSource: makeSource, expectedViolationCount: 5)
    }

    func testVisitAllNodesWithSuffix() {
        let makeSource: SourceCreator = { type in
            """
                private \(type) ATests {}
                \(type) BTests2 {}
            """
        }

        let attributes = DeclVisitor.Attributes(suffix: "Tests")
        testDeclVisitorOnAllTypes(with: attributes, makeSource: makeSource, expectedViolationCount: 1)
    }

    func testVisitAllStructsInNestedClasses() {
        let source = """
            class A {
                struct B {}
                struct A {
                    struct C {}
                }
            }
            private struct D {}
        """
        guard let node = try? SyntaxParser.parse(source: source) else {
            XCTFail("unable to parse source")
            return
        }
        let visitor = DeclVisitor(objectType: .struct)
        let violations = visitor.findViolations(node)
        XCTAssertTrue(violations.count == 4)
    }

    func testVisitAllPublicClassesThatInheritFromClass() {
        let source = """
            public class Child: Parent {}
            public class Foo
            public class Bar
            class A {}
        """

        guard let node = try? SyntaxParser.parse(source: source) else {
            XCTFail("unable to parse source")
            return
        }
        let attributes = DeclVisitor.Attributes(accessControl: .public, inheritsFrom: ["Parent"])
        let visitor = DeclVisitor(objectType: .class, attributes: attributes)
        let violations = visitor.findViolations(node)
        XCTAssertTrue(violations.count == 1)
    }

    func testVisitChildVisitors() {
        let source = """
            public class Child: Parent {
                private struct A {
                    public struct B {
                        public struct G1 {}
                        public struct G2 {}
                        public struct G3 {}
                    }
                }
                public struct C {}
            }
            public struct D {}
            public struct E {}
            public struct F {}
        """

        guard let node = try? SyntaxParser.parse(source: source) else {
            XCTFail("unable to parse source")
            return
        }
        let childAttributes = DeclVisitor.Attributes(accessControl: .public)
        let childVisitor = DeclVisitor(objectType: .struct, attributes: childAttributes)
        let attributes = DeclVisitor.Attributes(accessControl: .public, inheritsFrom: ["Parent"])
        let visitor = DeclVisitor(objectType: .class, attributes: attributes, childVisitors: [childVisitor])
        let violations = visitor.findViolations(node)
        XCTAssertTrue(violations.count == 5)
    }
}

private extension DeclVisitorTests {
    func testDeclVisitorOnAllTypes(with attributes: DeclVisitor.Attributes,
                                   makeSource: (String) -> String,
                                   expectedViolationCount: Int) {
        XCTAssertNoThrow(try {
            for type in ObjectType.allCases {
                let source = makeSource(type.rawValue)
                let node = try SyntaxParser.parse(source: source)
                let visitor = DeclVisitor(objectType: type, attributes: attributes)
                let violations = visitor.findViolations(node)
                XCTAssertTrue(violations.count == expectedViolationCount)
            }
        }())
    }
}
