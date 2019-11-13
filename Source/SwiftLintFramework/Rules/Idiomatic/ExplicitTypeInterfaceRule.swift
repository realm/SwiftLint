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

    public func validate(file: SwiftLintFile) -> [StyleViolation] {
        return file.structureDictionary.traverseWithParentDepthFirst { parent, subDict in
            guard let kind = subDict.declarationKind else { return nil }
            return validate(file: file, kind: kind, dictionary: subDict, parentStructure: parent)
        }
    }

    private func validate(file: SwiftLintFile,
                          kind: SwiftDeclarationKind,
                          dictionary: SourceKittenDictionary,
                          parentStructure: SourceKittenDictionary) -> [StyleViolation] {
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

private extension SourceKittenDictionary {
    var containsType: Bool {
        return typeName != nil
    }

    func isInitCall(file: SwiftLintFile) -> Bool {
        guard
            let nameOffset = nameOffset,
            let nameLength = nameLength,
            let afterNameRange = file.linesContainer.byteRangeToNSRange(start: nameOffset + nameLength, length: 0)
        else {
            return false
        }

        let contents = file.contents
        let contentAfterName = contents.substring(from: afterNameRange.location)
        let initCallRegex =
            regex("^\\s*=\\s*(?:try[!?]?\\s+)?\\[?\\p{Lu}[^\\(\\s<]*(?:<[^\\>]*>)?(?::\\s*[^\\(\\n]+)?\\]?\\(")

        return initCallRegex.firstMatch(in: contentAfterName, options: [], range: contentAfterName.fullNSRange) != nil
    }

    func isTypeReferenceAssignment(file: SwiftLintFile) -> Bool {
        guard
            let nameOffset = nameOffset,
            let nameLength = nameLength,
            let afterNameRange = file.linesContainer.byteRangeToNSRange(start: nameOffset + nameLength, length: 0)
        else {
            return false
        }

        let contents = file.contents
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
        guard let statement = statementKind else {
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

private extension SwiftLintFile {
    var captureGroupByteRanges: [NSRange] {
        return match(pattern: "\\{\\s*\\[(\\s*\\w+\\s+\\w+,*)+\\]",
                     excludingSyntaxKinds: SyntaxKind.commentKinds)
                .compactMap { linesContainer.NSRangeToByteRange(start: $0.location, length: $0.length) }
    }
}

private extension Collection where Element == NSRange {
    func contains(_ index: Int) -> Bool {
        return contains { $0.contains(index) }
    }
}
