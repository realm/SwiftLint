import Foundation
import SourceKittenFramework

public struct ASTQuery: Codable, Hashable, CacheDescriptionProvider {
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
    let substructure: [ASTQuery]

    init(statementKind: String? = nil, name: String? = nil, substructure: [ASTQuery] = []) {
        self.statementKind = statementKind
        expressionKind = nil
        declarationKind = nil

        self.name = name
        self.substructure = substructure
    }

    init(declarationKind: String? = nil, name: String? = nil, substructure: [ASTQuery] = []) {
        self.declarationKind = declarationKind
        expressionKind = nil
        statementKind = nil

        self.name = name
        self.substructure = substructure
    }

    init(expressionKind: String? = nil, name: String? = nil, substructure: [ASTQuery] = []) {
        self.expressionKind = expressionKind
        declarationKind = nil
        statementKind = nil

        self.name = name
        self.substructure = substructure
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: ASTCodingKeys.self)

        expressionKind = try container.decodeIfPresent(String.self, forKey: .expressionKind)
        declarationKind = try container.decodeIfPresent(String.self, forKey: .declarationKind)
        statementKind = try container.decodeIfPresent(String.self, forKey: .statementKind)

        name = try container.decodeIfPresent(String.self, forKey: .name)
        substructure = try container.decodeIfPresent([ASTQuery].self, forKey: .substructure) ?? []
    }

    var consoleDescription: String { return "user-defined" }

    var cacheDescription: String {
        let jsonObject: [String?] = [
            expressionKind ?? "",
            declarationKind ?? "",
            statementKind ?? "",
            name ?? "",
            substructure.map(\.cacheDescription).joined(separator: ",")
        ]

        if let jsonData = try? JSONSerialization.data(withJSONObject: jsonObject),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            return jsonString
        }
        queuedFatalError("Could not serialize ast configuration for cache")
    }

    func matches(subtree source: SourceKittenDictionary, query: ASTQuery) -> [ByteRange] {
        return source.traverseDepthFirst { next in
            if next ~= query {
                var ret = [ByteRange]()
                if query.substructure.isEmpty {
                    next.byteRange.map { ret.append($0) }
                } else {
                    // TODO: will this handle holes?
                    // { name: foo, substructure [{ }, { name: param }] } should match .foo(bar: baz, param: qux)
                    // { name: foo, substructure [{ name: param }] } should not match .foo(bar: baz, param: qux) only .foo(param: qux)
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
    case ast(ASTQuery)

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
            self = try .ast(JSONDecoder().decode(ASTQuery.self, from: astData))
            return
        }

        throw ConfigurationError.unknownConfiguration
    }
}

protocol ASTQueryable {
    static func ~= (left: Self, right: ASTQuery) -> Bool
}

// FIXME: these matchers a lil awkward.

extension SourceKittenDictionary: ASTQueryable {
    static func ~= (source: Self, ast: ASTQuery) -> Bool {
        // TODO: nil AST.name as a wildcard?
        var result = false
        if let astExpressionKind = ast.expressionKind, let expressionKind = source.expressionKind {
            result = expressionKind ~= astExpressionKind
        }
        if let astDeclarationKind = ast.declarationKind, let declarationKind = source.declarationKind {
            result = declarationKind ~= astDeclarationKind
        }
        if let astStatementKind = ast.statementKind, let statementKind = source.statementKind {
            result = statementKind ~= astStatementKind
        }
        // TODO: nil kinds as a wildcard? or explicit
        if let sourceName = source.name, let astName = ast.name {
            result = sourceName.hasSuffix(astName)
        }
        return result
    }
}

extension SwiftExpressionKind: ASTQueryable {
    static func ~= (left: Self, right: ASTQuery) -> Bool {
        guard let expressionKind = right.expressionKind else { return false }
        return left.rawValue.hasSuffix(expressionKind)
    }
    static func ~= (left: Self, right: String) -> Bool {
        return left.rawValue.hasSuffix(right)
    }
}

extension SwiftDeclarationKind: ASTQueryable {
    static func ~= (left: Self, right: ASTQuery) -> Bool {
        guard let declarationKind = right.declarationKind else { return false }
        return left.rawValue.hasSuffix(declarationKind)
    }
    static func ~= (left: Self, right: String) -> Bool {
        return left.rawValue.hasSuffix(right)
    }
}

extension StatementKind: ASTQueryable {
    static func ~= (left: Self, right: ASTQuery) -> Bool {
        guard let statementKind = right.statementKind else { return false }
        return left.rawValue.hasSuffix(statementKind)
    }
    static func ~= (left: Self, right: String) -> Bool {
        return left.rawValue.hasSuffix(right)
    }
}

extension SwiftLintFile {
    internal func matchesAndSyntaxKinds(matching ast: ASTQuery,
                                        fileAST: SourceKittenDictionary) -> [(ByteRange, [SwiftLintSyntaxToken])] {
        let syntax = syntaxMap
        let ranges = ast.matches(subtree: structureDictionary, query: ast)
        return ranges.map { ($0, syntax.tokens(inByteRange: $0)) }
    }

    internal func match(ast: ASTQuery) -> [(ByteRange, [SyntaxKind])] {
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
        case let .regex(regex, captureGroup):
            return match(pattern: regex.pattern,
                         excludingSyntaxKinds: syntaxKinds,
                         range: range,
                         captureGroup: captureGroup)
        case .ast(let ast):
            let matches = match(ast: ast, excludingSyntaxKinds: syntaxKinds)
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
    internal func match(ast: ASTQuery,
                        excludingSyntaxKinds syntaxKinds: Set<SyntaxKind>) -> [NSRange] {
        return match(ast: ast)
            .filter { syntaxKinds.isDisjoint(with: $0.1) }
            .map { stringView.byteRangeToNSRange($0.0)! } // FIXME: given joined(seperator:) query its finding a cursor: '^'.joined(seperator:) which highlights incorrectly un multiline statements.
    }
}
