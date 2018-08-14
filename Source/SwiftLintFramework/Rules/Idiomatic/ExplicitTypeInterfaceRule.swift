import Foundation
import SourceKittenFramework

private typealias DeclarationKindWithMetadata = (declarationKind: SwiftDeclarationKind,
                                                 dictionary: [String: SourceKitRepresentable],
                                                 parentDictionary: [String: SourceKitRepresentable])

public struct ExplicitTypeInterfaceRule: OptInRule, ConfigurationProviderRule {

    public var configuration = ExplicitTypeInterfaceConfiguration()

    public init() {}

    fileprivate static let captureGroupPattern =
    "\\{"       + // The { character
    "\\s*"      + // Zero or more whitespace character(s)
    "\\["       + // The [ characterassociatedEnum
    "("         + // Start if the first capturing group
    "\\s*"      + // Zero or more whitespace character(s)
    "\\w+"      + // At least one word character
    "\\s+"      + // At least one whitespace character
    "\\w+"      + // At least one world character
    ",*"        + // Zero or more , character
    ")"         + // End of the first capturing group
    "+"         + // At least occurance of the first capturing group
    "\\]"         // The ] character

    public static let description = RuleDescription(
        identifier: "explicit_type_interface",
        name: "Explicit Type Interface",
        description: "Properties should have a type interface",
        kind: .idiomatic,
        nonTriggeringExamples: [
            "class Foo {\n  var myVar: Int? = 0\n}\n",
            "class Foo {\n  let myVar: Int? = 0\n}\n",
            "class Foo {\n  static var myVar: Int? = 0\n}\n",
            "class Foo {\n  class var myVar: Int? = 0\n}\n"
        ],
        triggeringExamples: [
            "class Foo {\n  ↓var myVar = 0\n\n}\n",
            "class Foo {\n  ↓let mylet = 0\n\n}\n",
            "class Foo {\n  ↓static var myStaticVar = 0\n}\n",
            "class Foo {\n  ↓class var myClassVar = 0\n}\n",
            "class Foo {\n  ↓let myVar = Int(0)\n}\n",
            "class Foo {\n  ↓let myVar = Set<Int>(0)\n}\n"
        ]
    )

    public func validate(file: File) -> [StyleViolation] {

        let captureGroupByteRanges = file.captureGroupByteRanges
        let elements = file.dictionaries(of: configuration.allowedKinds)

        return elements.compactMap { element -> StyleViolation? in
            guard !element.dictionary.containsType,
                  let offset = element.dictionary.offset,
                  (!configuration.allowRedundancy || !element.dictionary.isInitCall(file: file)),
                  !element.parentDictionary.contains([.forEach, .guard]),
                  !element.parentDictionary.caseStatementPatternRanges.contains(offset),
                  !element.parentDictionary.caseExpressionRanges.contains(offset),
                  !captureGroupByteRanges.contains(offset) else {
                    return nil
            }

            return StyleViolation(ruleDescription: type(of: self).description,
                                  severity: configuration.severityConfiguration.severity,
                                  location: Location(file: file, byteOffset: offset))
        }
    }
}

private extension File {

    var captureGroupByteRanges: [NSRange] {
        return match(pattern: ExplicitTypeInterfaceRule.captureGroupPattern,
                     excludingSyntaxKinds: SyntaxKind.commentKinds)
            .compactMap { contents.bridge().NSRangeToByteRange(start: $0.location, length: $0.length) }
    }

    func dictionaries(of declarationKinds: Set<SwiftDeclarationKind>) -> [DeclarationKindWithMetadata] {
        var declarations = [DeclarationKindWithMetadata]()
        func search(in dictionary: [String: SourceKitRepresentable], parent: [String: SourceKitRepresentable]) {
            if let kind = dictionary.kind,
                let declarationKind = SwiftDeclarationKind(rawValue: kind),
                declarationKinds.contains(declarationKind) {
                declarations.append((declarationKind,
                                    dictionary,
                                    parent))
            }

            dictionary.substructure.forEach { search(in: $0, parent: dictionary) }
        }

        search(in: structure.dictionary, parent: [:])
        return declarations
    }
}

private extension Dictionary where Key == String, Value == SourceKitRepresentable {
    var containsType: Bool {
        return typeName != nil
    }

    var caseStatementPatternRanges: [NSRange] {
        return ranges(with: StatementKind.case.rawValue, for: "source.lang.swift.structure.elem.pattern")
    }

    var caseExpressionRanges: [NSRange] {
        return ranges(with: "source.lang.swift.expr.tuple", for: "source.lang.swift.structure.elem.expr")
    }

    func isInitCall(file: File) -> Bool {
        guard
            let nameOffset = nameOffset,
            let nameLength = nameLength,
            case let contents = file.contents.bridge(),
            let afterNameRange = contents.byteRangeToNSRange(start: nameOffset + nameLength, length: 0)
            else {
                return false
        }

        let contentAfterName = contents.substring(from: afterNameRange.location)
        let initCallRegex = regex("^\\s*=\\s*\\p{Lu}[^\\(\\s<]*(?:<[^\\>]*>)?\\(")

        return initCallRegex.firstMatch(in: contentAfterName, options: [], range: contentAfterName.fullNSRange) != nil
    }

    func contains(_ statements: Set<StatementKind>) -> Bool {
        return StatementKind(optionalRawValue: kind).isKind(of: statements)
    }

    func ranges(with parentKind: String, for elementKind: String) -> [NSRange] {
        guard parentKind == kind else {
            return []
        }

        return elements.filter { elementKind == $0.kind }
                       .compactMap { NSRange(location: $0.offset, length: $0.length) }
    }
}

private extension Optional where Wrapped == StatementKind {
    func isKind(of statements: Set<StatementKind>) -> Bool {
        guard let stmt = self else {
            return false
        }
        return statements.contains(stmt)
    }
}

private extension StatementKind {
    init?(optionalRawValue: String?) {
        guard let rawValue = optionalRawValue,
              let stmt = StatementKind(rawValue: rawValue) else {
            return nil
        }
        self = stmt
    }
}

private extension NSRange {
    init?(location: Int?, length: Int?) {
        guard let location = location, let length = length else {
            return nil
        }

        self = NSRange(location: location, length: length)
    }
}

private extension Collection where Element == NSRange {
    func contains(_ index: Int) -> Bool {
        return first(where: { $0.contains(index) }) != nil
    }
}
