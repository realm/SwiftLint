import SourceKittenFramework
import SwiftIDEUtils
@testable import SwiftLintCore
import SwiftSyntax
import TestHelpers
import XCTest

final class SwiftSyntaxKindBridgeTests: SwiftLintTestCase {
    func testBasicKeywordMapping() {
        // Test basic keyword mappings
        XCTAssertEqual(SwiftSyntaxKindBridge.mapClassification(.keyword), .keyword)
    }

    func testIdentifierMapping() {
        // Test identifier mappings
        XCTAssertEqual(SwiftSyntaxKindBridge.mapClassification(.identifier), .identifier)
        XCTAssertEqual(SwiftSyntaxKindBridge.mapClassification(.dollarIdentifier), .identifier)
    }

    func testCommentMapping() {
        // Test comment mappings
        XCTAssertEqual(SwiftSyntaxKindBridge.mapClassification(.lineComment), .comment)
        XCTAssertEqual(SwiftSyntaxKindBridge.mapClassification(.blockComment), .comment)
        XCTAssertEqual(SwiftSyntaxKindBridge.mapClassification(.docLineComment), .docComment)
        XCTAssertEqual(SwiftSyntaxKindBridge.mapClassification(.docBlockComment), .docComment)
    }

    func testLiteralMapping() {
        // Test literal mappings
        XCTAssertEqual(SwiftSyntaxKindBridge.mapClassification(.stringLiteral), .string)
        XCTAssertEqual(SwiftSyntaxKindBridge.mapClassification(.integerLiteral), .number)
        XCTAssertEqual(SwiftSyntaxKindBridge.mapClassification(.floatLiteral), .number)
    }

    func testOperatorAndTypeMapping() {
        // Test operator and type mappings
        XCTAssertEqual(SwiftSyntaxKindBridge.mapClassification(.operator), .operator)
        XCTAssertEqual(SwiftSyntaxKindBridge.mapClassification(.type), .typeidentifier)
    }

    func testSpecialCaseMapping() {
        // Test special case mappings
        XCTAssertEqual(SwiftSyntaxKindBridge.mapClassification(.attribute), .attributeID)
        XCTAssertEqual(SwiftSyntaxKindBridge.mapClassification(.editorPlaceholder), .placeholder)
        XCTAssertEqual(SwiftSyntaxKindBridge.mapClassification(.ifConfigDirective), .poundDirectiveKeyword)
        XCTAssertEqual(SwiftSyntaxKindBridge.mapClassification(.argumentLabel), .argument)
    }

    func testUnmappedClassifications() {
        // Test classifications that have no mapping
        XCTAssertNil(SwiftSyntaxKindBridge.mapClassification(.none))
        XCTAssertNil(SwiftSyntaxKindBridge.mapClassification(.regexLiteral))
    }

    func testSourceKittenSyntaxKindsGeneration() {
        // Test that we can generate SourceKitten-compatible tokens from a simple Swift file
        let contents = """
            // This is a comment
            let x = 42
            """
        let file = SwiftLintFile(contents: contents)

        // Get the tokens from the bridge
        let tokens = SwiftSyntaxKindBridge.sourceKittenSyntaxKinds(for: file)

        // Verify we got some tokens
        XCTAssertFalse(tokens.isEmpty)

        // Check that we have expected token types
        let tokenTypes = Set(tokens.map(\.value.type))
        XCTAssertTrue(tokenTypes.contains(SyntaxKind.comment.rawValue))
        XCTAssertTrue(tokenTypes.contains(SyntaxKind.keyword.rawValue))
        XCTAssertTrue(tokenTypes.contains(SyntaxKind.identifier.rawValue))
        XCTAssertTrue(tokenTypes.contains(SyntaxKind.number.rawValue))
    }

    func testTokenOffsetAndLength() {
        // Test that token offsets and lengths are correct
        let contents = "let x = 42"
        let file = SwiftLintFile(contents: contents)

        let tokens = SwiftSyntaxKindBridge.sourceKittenSyntaxKinds(for: file)

        // Find the "let" keyword token
        let letToken = tokens.first { token in
            if token.value.type == SyntaxKind.keyword.rawValue {
                let start = token.value.offset.value
                let end = token.value.offset.value + token.value.length.value
                let startIndex = contents.index(contents.startIndex, offsetBy: start)
                let endIndex = contents.index(contents.startIndex, offsetBy: end)
                let substring = String(contents[startIndex..<endIndex])
                return substring == "let"
            }
            return false
        }
        XCTAssertNotNil(letToken)
        XCTAssertEqual(letToken?.value.offset.value, 0)
        XCTAssertEqual(letToken?.value.length.value, 3)

        // Find the number token
        let numberToken = tokens.first { $0.value.type == SyntaxKind.number.rawValue }
        XCTAssertNotNil(numberToken)
        // "42" starts at offset 8 and has length 2
        XCTAssertEqual(numberToken?.value.offset.value, 8)
        XCTAssertEqual(numberToken?.value.length.value, 2)
    }

    func testComplexCodeStructure() {
        // Test with more complex Swift code
        let contents = """
            import Foundation

            /// A sample class
            @objc
            class MyClass {
                // Properties
                var name: String = "test"
                let id = UUID()

                func doSomething() {
                    print("Hello, \\(name)!")
                }
            }
            """
        let file = SwiftLintFile(contents: contents)

        let tokens = SwiftSyntaxKindBridge.sourceKittenSyntaxKinds(for: file)

        // Verify we have various token types
        let tokenTypes = Set(tokens.map(\.value.type))
        XCTAssertTrue(tokenTypes.contains(SyntaxKind.keyword.rawValue))        // import, class, var, let, func
        XCTAssertTrue(tokenTypes.contains(SyntaxKind.identifier.rawValue))     // Foundation, MyClass, name, etc.
        XCTAssertTrue(tokenTypes.contains(SyntaxKind.docComment.rawValue))     // /// A sample class
        XCTAssertTrue(tokenTypes.contains(SyntaxKind.comment.rawValue))        // // Properties
        XCTAssertTrue(tokenTypes.contains(SyntaxKind.attributeID.rawValue))    // @objc
        XCTAssertTrue(tokenTypes.contains(SyntaxKind.typeidentifier.rawValue)) // String, UUID
        XCTAssertTrue(tokenTypes.contains(SyntaxKind.string.rawValue))         // "test", "Hello, \\(name)!"
    }

    func testNoSourceKitCallsAreMade() {
        // This test verifies that the bridge doesn't make any SourceKit calls
        // If it did, the validation system would fatal error in test mode

        let contents = """
            struct Test {
                let value = 123
                func method() -> Int { return value }
            }
            """
        let file = SwiftLintFile(contents: contents)

        // This should succeed without any fatal errors from the validation system
        let tokens = SwiftSyntaxKindBridge.sourceKittenSyntaxKinds(for: file)
        XCTAssertFalse(tokens.isEmpty)
    }

    func testEmptyFileHandling() {
        // Test that empty files are handled gracefully
        let file = SwiftLintFile(contents: "")
        let tokens = SwiftSyntaxKindBridge.sourceKittenSyntaxKinds(for: file)
        XCTAssertTrue(tokens.isEmpty)
    }

    func testWhitespaceOnlyFile() {
        // Test files with only whitespace
        let file = SwiftLintFile(contents: "   \n\n  \t  \n")
        let tokens = SwiftSyntaxKindBridge.sourceKittenSyntaxKinds(for: file)
        // Whitespace is not classified, so we should get no tokens
        XCTAssertTrue(tokens.isEmpty)
    }
}
