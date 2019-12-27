import SourceKittenFramework

public protocol ASTRule: Rule {
    associatedtype KindType: RawRepresentable
    func validate(file: SwiftLintFile, kind: KindType, dictionary: SourceKittenDictionary) -> [StyleViolation]
    func kind(from dictionary: SourceKittenDictionary) -> KindType?
}

public extension ASTRule {
    func validate(file: SwiftLintFile) -> [StyleViolation] {
        return validate(file: file, dictionary: file.structureDictionary)
    }

    func validate(file: SwiftLintFile, dictionary: SourceKittenDictionary) -> [StyleViolation] {
        return dictionary.traverseDepthFirst { subDict in
            guard let kind = self.kind(from: subDict) else { return nil }
            return validate(file: file, kind: kind, dictionary: subDict)
        }
    }
}

public extension ASTRule where KindType == SwiftDeclarationKind {
    func kind(from dictionary: SourceKittenDictionary) -> KindType? {
        return dictionary.declarationKind
    }
}

public extension ASTRule where KindType == SwiftExpressionKind {
    func kind(from dictionary: SourceKittenDictionary) -> KindType? {
        return dictionary.expressionKind
    }
}

public extension ASTRule where KindType == StatementKind {
    func kind(from dictionary: SourceKittenDictionary) -> KindType? {
        return dictionary.statementKind
    }
}
