import Foundation
import SourceKittenFramework

public struct AST: Codable, Hashable, CacheDescriptionProvider {
    enum ASTCodingKeys: CodingKey {
        case expressionKind
        case declarationKind
        case statementKind

        case name
        case substructure
    }

    let expressionKind: String?
    let declarationKind: String?
    let statementKind: String?

    let name: String?
    let substructure: [AST]

    init(expressionKind: String? = nil, declarationKind: String? = nil, statementKind: String? = nil, name: String? = nil, substructure: [AST] = []) {
        self.expressionKind = expressionKind
        self.declarationKind = declarationKind
        self.statementKind = declarationKind

        self.name = name
        self.substructure = substructure
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: ASTCodingKeys.self)

        expressionKind = try container.decodeIfPresent(String.self, forKey: .expressionKind)
        declarationKind = try container.decodeIfPresent(String.self, forKey: .declarationKind)
        statementKind = try container.decodeIfPresent(String.self, forKey: .statementKind)

        name = try container.decodeIfPresent(String.self, forKey: .name)
        substructure = try container.decodeIfPresent([AST].self, forKey: .substructure) ?? []
    }

    var consoleDescription: String { "TODO" }

    var cacheDescription: String { "TODO" }

    func matches(subtree source: SourceKittenDictionary, query: AST) -> [ByteRange] {
        return source.traverseWithParentDepthFirst { parent, next in
            if parent ~= query {
                var ret = [ByteRange]()
                if query.substructure.isEmpty {
                    parent.byteRange.map { ret.append($0) }
                } else {
                    // TODO: will this handle holes?
                    //{ name: foo, substructure [{ }, { name: param }] } should match .foo(bar: baz, param: qux)
                    //{ name: foo, substructure [{ name: param }] } should not match .foo(bar: baz, param: qux) only .foo(param: qux)
                    for subQuery in query.substructure {
                        ret.append(contentsOf: matches(subtree: next, query: subQuery))
                        // TODO: determine how to best union ranges so we get accurate byteRanges (or use some other sourceLocation metadata)
                    }
                }
                return ret
            }
            return []
        }
    }
}

public enum ContentMatcher: Hashable, CacheDescriptionProvider {
    case regex(regex: NSRegularExpression, captureGroup: Int)
    case ast(AST)

    var consoleDescription: String {
        switch self {
        case .regex(let regex, _):
            return regex.pattern
        case .ast(let ast):
            return ast.consoleDescription
        }
    }

    var cacheDescription: String {
        switch self {
        case .regex(let regex, _):
            return regex.pattern
        case .ast(let ast):
            return ast.cacheDescription
        }
    }

    init?(configuration: [String: Any]) throws {
        let captureGroup = configuration["capture_group"] as? Int ?? 0
        if let regexString = configuration["regex"] as? String {
            let regex = try NSRegularExpression.cached(pattern: regexString)

            guard (0 ... regex.numberOfCaptureGroups).contains(captureGroup) else {
                throw ConfigurationError.unknownConfiguration
            }

            self = .regex(regex: regex, captureGroup: captureGroup)
            return
        }

        if let astString = configuration["ast"] as? String {
            guard let astData = astString.data(using: .utf8) else {
                throw ConfigurationError.unknownConfiguration
            }
            self = try .ast(JSONDecoder().decode(AST.self, from: astData))
            return
        }

        throw ConfigurationError.unknownConfiguration
    }
}

protocol ASTQueryable {
    static func ~= (left: Self, right: AST) -> Bool
}

// FIXME: these matchers a lil awkward.

extension SourceKittenDictionary: ASTQueryable {
    static func ~= (source: Self, ast: AST) -> Bool {
        // TODO: nil AST.name as a wildcard?
        var result = false
        if let ast_expressionKind = ast.expressionKind, let expressionKind = source.expressionKind {
            result = expressionKind ~= ast_expressionKind
        }
        if let ast_declarationKind = ast.declarationKind, let declarationKind = source.declarationKind {
            result = declarationKind ~= ast_declarationKind
        }
        if let ast_statementKind = ast.statementKind, let statementKind = source.statementKind {
            result = statementKind ~= ast_statementKind
        }
        // TODO: nil kinds as a wildcard? or explicit
        if let sourceName = source.name, let astName = ast.name {
            result = sourceName.hasSuffix(astName)
        }
        return result
    }
}

extension SwiftExpressionKind: ASTQueryable {
    static func ~= (left: Self, right: AST) -> Bool {
        guard let expressionKind = right.expressionKind else { return false }
        return left.rawValue.hasSuffix(expressionKind)
    }
    static func ~= (left: Self, right: String) -> Bool {
        return left.rawValue.hasSuffix(right)
    }
}

extension SwiftDeclarationKind: ASTQueryable {
    static func ~= (left: Self, right: AST) -> Bool {
        guard let declarationKind = right.declarationKind else { return false }
        return left.rawValue.hasSuffix(declarationKind)
    }
    static func ~= (left: Self, right: String) -> Bool {
        return left.rawValue.hasSuffix(right)
    }
}

extension StatementKind: ASTQueryable {
    static func ~= (left: Self, right: AST) -> Bool {
        guard let statementKind = right.statementKind else { return false }
        return left.rawValue.hasSuffix(statementKind)
    }
    static func ~= (left: Self, right: String) -> Bool {
        return left.rawValue.hasSuffix(right)
    }
}

extension SwiftLintFile {
    // TODO: theres a bunch of stuff in SwiftLintFile+Regex that unrelated to Regex...

    internal func matchesAndSyntaxKinds(matching ast: AST,
                                        fileAST: SourceKittenDictionary) -> [(ByteRange, [SwiftLintSyntaxToken])] {
        let syntax = syntaxMap
        let ranges = ast.matches(subtree: structureDictionary, query: ast)
        return ranges.map { ($0, syntax.tokens(inByteRange: $0)) }
    }

    internal func match(ast: AST) -> [(ByteRange, [SyntaxKind])] {
        return matchesAndSyntaxKinds(matching: ast, fileAST: structureDictionary).map { ($0, $1.kinds) }
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
            let matches = match(ast: ast, excludingSyntaxKinds: syntaxKinds)
            if matches.count > 0 {
                print(matches)
            }
            return matches
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
            .map { stringView.byteRangeToNSRange($0.0)! } // FIXME: given joined(seperator:) query its finding a cursor: '^'.joined(seperator:) which highlights incorrectly un multiline statements.
    }
}
