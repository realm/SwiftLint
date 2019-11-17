import SourceKittenFramework

public protocol ASTRule: Rule {
    associatedtype KindType: RawRepresentable
    func validate(file: SwiftLintFile, kind: KindType, dictionary: SourceKittenDictionary) -> [StyleViolation]
    func kind(from dictionary: SourceKittenDictionary) -> KindType?
}

public extension ASTRule {
}

public extension ASTRule where KindType == SwiftDeclarationKind {
    func validate(file: SwiftLintFile) -> [StyleViolation] {
        return validate(file: file, dictionary: file.structureDictionary)
    }

    func validate(file: SwiftLintFile, dictionary: SourceKittenDictionary) -> [StyleViolation] {
        return file.traverseDeclarations { kind, subDict in
            return validate(file: file, kind: kind, dictionary: subDict)
        }
    }

    func kind(from dictionary: SourceKittenDictionary) -> KindType? {
        return dictionary.declarationKind
    }
}

public extension ASTRule where KindType == SwiftExpressionKind {
    func validate(file: SwiftLintFile) -> [StyleViolation] {
        return validate(file: file, dictionary: file.structureDictionary)
    }

    func validate(file: SwiftLintFile, dictionary: SourceKittenDictionary) -> [StyleViolation] {
        return file.traverseExpressions { kind, subDict in
            return validate(file: file, kind: kind, dictionary: subDict)
        }
    }

    func kind(from dictionary: SourceKittenDictionary) -> KindType? {
        return dictionary.expressionKind
    }
}

public extension ASTRule where KindType == StatementKind {
    func validate(file: SwiftLintFile) -> [StyleViolation] {
        return validate(file: file, dictionary: file.structureDictionary)
    }

    func validate(file: SwiftLintFile, dictionary: SourceKittenDictionary) -> [StyleViolation] {
        return dictionary.traverseDepthFirst { subDict in
            guard let kind = self.kind(from: subDict) else { return nil }
            return validate(file: file, kind: kind, dictionary: subDict)
        }
    }

    func kind(from dictionary: SourceKittenDictionary) -> KindType? {
        return dictionary.statementKind
    }
}
