import Foundation
import SourceKittenFramework

public struct ExplicitTypeInterfaceRule: OptInRule, ConfigurationProviderRule {
    public var configuration = ExplicitTypeInterfaceConfiguration()

    public init() {}

    public static let description = RuleDescription(
        identifier: "explicit_type_interface",
        name: "Explicit Type Interface",
        description: "Properties should have a type interface",
        kind: .idiomatic,
        nonTriggeringExamples: [
            """
            class Foo {
              var myVar: Int? = 0
            }
            """,
            """
            class Foo {
              let myVar: Int? = 0
            }
            """,
            """
            class Foo {
              static var myVar: Int? = 0
            }
            """,
            """
            class Foo {
              class var myVar: Int? = 0
            }
            """
        ],
        triggeringExamples: [
            """
            class Foo {
              ↓var myVar = 0
            }
            """,
            """
            class Foo {
              ↓let mylet = 0
            }
            """,
            """
            class Foo {
              ↓static var myStaticVar = 0
            }
            """,
            """
            class Foo {
              ↓class var myClassVar = 0
            }
            """,
            """
            class Foo {
              ↓let myVar = Int(0)
            }
            """,
            """
            class Foo {
              ↓let myVar = Set<Int>(0)
            }
            """
        ]
    )

    public func validate(file: File) -> [StyleViolation] {
        return validate(file: file, dictionary: file.structure.dictionary, parentStructure: nil)
    }

    private func validate(file: File, dictionary: [String: SourceKitRepresentable],
                          parentStructure: [String: SourceKitRepresentable]?) -> [StyleViolation] {
        return dictionary.substructure.flatMap({ subDict -> [StyleViolation] in
            var violations = validate(file: file, dictionary: subDict, parentStructure: dictionary)

            if let kindString = subDict.kind,
                let kind = SwiftDeclarationKind(rawValue: kindString) {
                violations += validate(file: file, kind: kind, dictionary: subDict, parentStructure: dictionary)
            }

            return violations
        })
    }

    private func validate(file: File,
                          kind: SwiftDeclarationKind,
                          dictionary: [String: SourceKitRepresentable],
                          parentStructure: [String: SourceKitRepresentable]) -> [StyleViolation] {
        guard configuration.allowedKinds.contains(kind),
            let offset = dictionary.offset,
            !dictionary.containsType,
            (!configuration.allowRedundancy ||
                (!dictionary.isInitCall(file: file) && !dictionary.isTypeReferenceAssignment(file: file))
            ),
            !parentStructure.contains([.forEach, .guard]),
            !parentStructure.caseStatementPatternRanges.contains(offset),
            !parentStructure.caseExpressionRanges.contains(offset),
            !file.captureGroupByteRanges.contains(offset) else {
                return []
        }

        return [
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severityConfiguration.severity,
                           location: Location(file: file, byteOffset: offset))
        ]
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
        let initCallRegex =
            regex("^\\s*=\\s*(?:try[!?]?\\s+)?\\[?\\p{Lu}[^\\(\\s<]*(?:<[^\\>]*>)?(?::\\s*[^\\(\\n]+)?\\]?\\(")

        return initCallRegex.firstMatch(in: contentAfterName, options: [], range: contentAfterName.fullNSRange) != nil
    }

    func isTypeReferenceAssignment(file: File) -> Bool {
        guard
            let nameOffset = nameOffset,
            let nameLength = nameLength,
            case let contents = file.contents.bridge(),
            let afterNameRange = contents.byteRangeToNSRange(start: nameOffset + nameLength, length: 0)
        else {
            return false
        }

        let contentAfterName = contents.substring(from: afterNameRange.location)
        let typeAssignment = regex("^\\s*=\\s*(?:\\p{Lu}[^\\(\\s<]*(?:<[^\\>]*>)?\\.)*self")

        return typeAssignment.firstMatch(in: contentAfterName, options: [], range: contentAfterName.fullNSRange) != nil
    }

    var caseStatementPatternRanges: [NSRange] {
        return ranges(with: StatementKind.case.rawValue, for: "source.lang.swift.structure.elem.pattern")
    }

    var caseExpressionRanges: [NSRange] {
        return ranges(with: SwiftExpressionKind.tuple.rawValue, for: "source.lang.swift.structure.elem.expr")
    }

    func contains(_ statements: Set<StatementKind>) -> Bool {
        guard let kind = kind,
              let statement = StatementKind(rawValue: kind) else {
                return false
        }
        return statements.contains(statement)
    }

    func ranges(with parentKind: String, for elementKind: String) -> [NSRange] {
        guard parentKind == kind else {
            return []
        }

        return elements
            .filter { elementKind == $0.kind }
            .compactMap {
                guard let location = $0.offset, let length = $0.length else { return nil }
                return NSRange(location: location, length: length)
            }
    }
}

private extension File {
    var captureGroupByteRanges: [NSRange] {
        return match(pattern: "\\{\\s*\\[(\\s*\\w+\\s+\\w+,*)+\\]",
                     excludingSyntaxKinds: SyntaxKind.commentKinds)
                .compactMap { contents.bridge().NSRangeToByteRange(start: $0.location, length: $0.length) }
    }
}

private extension Collection where Element == NSRange {
    func contains(_ index: Int) -> Bool {
        return contains { $0.contains(index) }
    }
}
