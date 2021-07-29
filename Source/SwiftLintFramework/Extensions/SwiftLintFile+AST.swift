import Foundation
import SourceKittenFramework

extension SwiftLintFile {
    // TODO: theres a bunch of stuff in SwiftLintFile+Regex that unrelated to Regex...
    
    internal func matchesAndSyntaxKinds(matching ast: AST,
                                        fileAST: SourceKittenDictionary) -> [(ByteRange, [SyntaxKind])] {
//        // working return type. Whatever we need to bridge SourceKittenDictionary to StyleViolation.location
//        let ret = [(ByteCount, [SyntaxKind])]()
//
//        self.structureDictionary.traverseDepthFirst { potentialRoot in
//            // what does it mean to compare a high level AST/json summary that fits in .swiftlint against a SourceKittenDictionary
//            if sourceKittenDictionary matches ast {
//                // base case
//                if ast.substructures.isEmpty {
//                    // which ByteCount do we return to build an error type? how do we handle .swiftlints SyntaxKind filters
//                    let result = build and return this node's [(ByteCount, [SyntaxKind])]
//                    ret.append(result)
//                }
//                else {
//                    // is this how subgraph matching works.
//                    // does dfs/bfs matter here?
//                    ast.substructures.traverseBreadthFirst { child in
//                    ret.append(self.matchesAndSyntaxKinds(ast: child, fileAST: potentialRoot))
//                }
//            }
//            return []
//        }
        return []
    }

    internal func match(ast: AST) -> [(ByteRange, [SyntaxKind])] {
        return matchesAndSyntaxKinds(matching: ast, fileAST: structureDictionary)
    }

    /**
     This function returns only matches that are not contained in a syntax kind
     specified.

     - parameter matcher: regex or ast content matcher to be matched inside file.
     - parameter excludingSyntaxKinds: syntax kinds the matches to be filtered
     when inside them.

     - returns: An array of [NSRange] objects consisting of  matches inside
     file contents.
     */
    internal func match(matcher: ContentMatcher,
                        excludingSyntaxKinds syntaxKinds: Set<SyntaxKind>,
                        range: NSRange? = nil) -> [NSRange] {
        switch matcher {
        case .regex(let regex, let captureGroup):
            return match(pattern: regex.pattern,
                         excludingSyntaxKinds: syntaxKinds,
                         range: range,
                         captureGroup: captureGroup)
        case .ast(let ast):
            return match(ast: ast, excludingSyntaxKinds: syntaxKinds)
        }
    }

    /**
     This function returns only matches that are not contained in a syntax kind
     specified.

     - parameter ast: ast  to be matched inside file.
     - parameter excludingSyntaxKinds: syntax kinds the matches to be filtered
     when inside them.

     - returns: An array of [NSRange] objects consisting of ast matches inside
     file contents.
     */
    internal func match(ast: AST,
                        excludingSyntaxKinds syntaxKinds: Set<SyntaxKind>) -> [NSRange] {
        return match(ast: ast)
            .filter { syntaxKinds.isDisjoint(with: $0.1) }
            .map { NSRange(location: $0.0.lowerBound.value, length: $0.0.length.value) } // TODO: this is probably not right.
    }

}
