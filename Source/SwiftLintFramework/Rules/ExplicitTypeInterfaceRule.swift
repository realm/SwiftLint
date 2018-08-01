import Foundation
import SourceKittenFramework

public struct ExplicitTypeInterfaceRule: OptInRule, ConfigurationProviderRule {

    public var configuration = ExplicitTypeInterfaceConfiguration()

    public init() {}

    fileprivate static let captureGroupPattern =
    "\\{"       + // The { character
    "\\s*"      + // Zero or more whitespace character(s)
    "\\["       + // The [ character
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
        let declarationRanges = file.declarationRanges(of: [.guard, .case])

        let collector = NamespaceCollector(dictionary: file.structure.dictionary)
        let elements = collector.findAllElements(of: [.varClass, .varLocal, .varGlobal, .varStatic, .varInstance])

        return elements.compactMap { element -> StyleViolation? in
            guard configuration.allowedKinds.contains(element.kind),
                  !element.dictionary.containsType,
                  (!configuration.allowRedundancy || !element.dictionary.isInitCall(file: file)),
                  !captureGroupByteRanges.contains(where: { $0.contains(element.offset) }),
                  !declarationRanges.contains(where: { $0.contains(element.offset) }) else {
                    return nil
            }

            return StyleViolation(ruleDescription: type(of: self).description,
                                  severity: configuration.severityConfiguration.severity,
                                  location: Location(file: file, byteOffset: element.offset))
        }
    }
}

private extension File {
    var captureGroupByteRanges: [NSRange] {
        return match(pattern: ExplicitTypeInterfaceRule.captureGroupPattern,
                     excludingSyntaxKinds: SyntaxKind.commentKinds)
               .compactMap { contents.bridge().NSRangeToByteRange(start: $0.location, length: $0.length) }
    }

    func declarationRanges(of statements: [StatementKind]) -> [NSRange] {
        var ranges: [NSRange] = []
        func search(in dictionary: [String: SourceKitRepresentable]) {
            if let kind = dictionary.kind,
                let statement = StatementKind(rawValue: kind),
                statements.contains(statement),
                let statementOffset = dictionary.offset,
                let statementLength = dictionary.length {
                    ranges.append(NSRange(location: statementOffset, length: statementLength))
            }

            dictionary.substructure.forEach(search)
        }

        search(in: structure.dictionary)
        return ranges
    }
}

private extension Dictionary where Key == String, Value == SourceKitRepresentable {
    var containsType: Bool {
        return typeName != nil
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
}
