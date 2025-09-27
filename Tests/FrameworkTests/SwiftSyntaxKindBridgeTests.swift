import SourceKittenFramework
import Testing

@testable import SwiftLintCore

@Suite
struct SwiftSyntaxKindBridgeTests {
    @Test
    func basicKeywordMapping() {
        // Test basic keyword mappings
        #expect(SwiftSyntaxKindBridge.mapClassification(.keyword) == .keyword)
    }

    @Test
    func identifierMapping() {
        // Test identifier mappings
        #expect(SwiftSyntaxKindBridge.mapClassification(.identifier) == .identifier)
        #expect(SwiftSyntaxKindBridge.mapClassification(.dollarIdentifier) == .identifier)
    }

    @Test
    func commentMapping() {
        // Test comment mappings
        #expect(SwiftSyntaxKindBridge.mapClassification(.lineComment) == .comment)
        #expect(SwiftSyntaxKindBridge.mapClassification(.blockComment) == .comment)
        #expect(SwiftSyntaxKindBridge.mapClassification(.docLineComment) == .docComment)
        #expect(SwiftSyntaxKindBridge.mapClassification(.docBlockComment) == .docComment)
    }

    @Test
    func literalMapping() {
        // Test literal mappings
        #expect(SwiftSyntaxKindBridge.mapClassification(.stringLiteral) == .string)
        #expect(SwiftSyntaxKindBridge.mapClassification(.integerLiteral) == .number)
        #expect(SwiftSyntaxKindBridge.mapClassification(.floatLiteral) == .number)
    }

    @Test
    func operatorAndTypeMapping() {
        // Test operator and type mappings
        #expect(SwiftSyntaxKindBridge.mapClassification(.operator) == .operator)
        #expect(SwiftSyntaxKindBridge.mapClassification(.type) == .typeidentifier)
    }

    @Test
    func specialCaseMapping() {
        // Test special case mappings
        #expect(SwiftSyntaxKindBridge.mapClassification(.attribute) == .attributeID)
        #expect(SwiftSyntaxKindBridge.mapClassification(.editorPlaceholder) == .placeholder)
        #expect(SwiftSyntaxKindBridge.mapClassification(.ifConfigDirective) == .poundDirectiveKeyword)
        #expect(SwiftSyntaxKindBridge.mapClassification(.argumentLabel) == .argument)
    }

    @Test
    func unmappedClassifications() {
        // Test classifications that have no mapping
        #expect(SwiftSyntaxKindBridge.mapClassification(.none) == nil)
        #expect(SwiftSyntaxKindBridge.mapClassification(.regexLiteral) == nil)
    }

    @Test
    func sourceKittenSyntaxKindsGeneration() {
        // Test that we can generate SourceKitten-compatible tokens from a simple Swift file
        let contents = """
            // This is a comment
            let x = 42
            """
        let file = SwiftLintFile(contents: contents)

        // Get the tokens from the bridge
        let tokens = SwiftSyntaxKindBridge.sourceKittenSyntaxKinds(for: file)

        // Verify we got some tokens
        #expect(!tokens.isEmpty)

        // Check that we have expected token types
        let tokenTypes = Set(tokens.map { $0.value.type })
        #expect(tokenTypes.contains(SyntaxKind.comment.rawValue))
        #expect(tokenTypes.contains(SyntaxKind.keyword.rawValue))
        #expect(tokenTypes.contains(SyntaxKind.identifier.rawValue))
        #expect(tokenTypes.contains(SyntaxKind.number.rawValue))
    }

    @Test
    func tokenOffsetAndLength() {
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
        #expect(letToken != nil)
        #expect(letToken?.value.offset.value == 0)
        #expect(letToken?.value.length.value == 3)

        // Find the number token
        let numberToken = tokens.first { $0.value.type == SyntaxKind.number.rawValue }
        #expect(numberToken != nil)
        // "42" starts at offset 8 and has length 2
        #expect(numberToken?.value.offset.value == 8)
        #expect(numberToken?.value.length.value == 2)
    }

    @Test
    func complexCodeStructure() {
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
        let tokenTypes = Set(tokens.map { $0.value.type })
        #expect(tokenTypes.contains(SyntaxKind.keyword.rawValue))        // import, class, var, let, func
        #expect(tokenTypes.contains(SyntaxKind.identifier.rawValue))     // Foundation, MyClass, name, etc.
        #expect(tokenTypes.contains(SyntaxKind.docComment.rawValue))     // /// A sample class
        #expect(tokenTypes.contains(SyntaxKind.comment.rawValue))        // // Properties
        #expect(tokenTypes.contains(SyntaxKind.attributeID.rawValue))    // @objc    // @objc
        #expect(tokenTypes.contains(SyntaxKind.typeidentifier.rawValue)) // String, UUID
        #expect(tokenTypes.contains(SyntaxKind.string.rawValue))         // "test", "Hello, \\(name)!"
    }

    @Test
    func noSourceKitCallsAreMade() {
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
        #expect(!tokens.isEmpty)
    }

    @Test
    func emptyFileHandling() {
        // Test that empty files are handled gracefully
        let file = SwiftLintFile(contents: "")
        let tokens = SwiftSyntaxKindBridge.sourceKittenSyntaxKinds(for: file)
        #expect(tokens.isEmpty)
    }

    @Test
    func whitespaceOnlyFile() {
        // Test files with only whitespace
        let file = SwiftLintFile(contents: "   \n\n  \t  \n")
        let tokens = SwiftSyntaxKindBridge.sourceKittenSyntaxKinds(for: file)
        // Whitespace is not classified, so we should get no tokens
        #expect(tokens.isEmpty)
    }
}
