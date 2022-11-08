import Foundation
import SourceKittenFramework

struct ExplicitTypeInterfaceRule: OptInRule, ConfigurationProviderRule {
    var configuration = ExplicitTypeInterfaceConfiguration()

    init() {}

    static let description = RuleDescription(
        identifier: "explicit_type_interface",
        name: "Explicit Type Interface",
        description: "Properties should have a type interface",
        kind: .idiomatic,
        nonTriggeringExamples: [
            Example("""
            class Foo {
              var myVar: Int? = 0
            }
            """),
            Example("""
            class Foo {
              let myVar: Int? = 0
            }
            """),
            Example("""
            class Foo {
              static var myVar: Int? = 0
            }
            """),
            Example("""
            class Foo {
              class var myVar: Int? = 0
            }
            """)
        ],
        triggeringExamples: [
            Example("""
            class Foo {
              ↓var myVar = 0
            }
            """),
            Example("""
            class Foo {
              ↓let mylet = 0
            }
            """),
            Example("""
            class Foo {
              ↓static var myStaticVar = 0
            }
            """),
            Example("""
            class Foo {
              ↓class var myClassVar = 0
            }
            """),
            Example("""
            class Foo {
              ↓let myVar = Int(0)
            }
            """),
            Example("""
            class Foo {
              ↓let myVar = Set<Int>(0)
            }
            """)
        ]
    )

    func validate(file: SwiftLintFile) -> [StyleViolation] {
        let captureGroupRanges = Lazy(self.captureGroupRanges(in: file))
        return file.structureDictionary.traverseWithParentsDepthFirst { parents, subDict in
            guard let kind = subDict.declarationKind,
                  let parent = parents.lastIgnoringCallAndArgument() else {
                return nil
            }
            return validate(file: file, kind: kind, dictionary: subDict, parentStructure: parent,
                            captureGroupRanges: captureGroupRanges.value)
        }
    }

    private func validate(file: SwiftLintFile,
                          kind: SwiftDeclarationKind,
                          dictionary: SourceKittenDictionary,
                          parentStructure: SourceKittenDictionary,
                          captureGroupRanges: [ByteRange]) -> [StyleViolation] {
        guard configuration.allowedKinds.contains(kind),
            let offset = dictionary.offset,
            !dictionary.containsType,
            (!configuration.allowRedundancy ||
                (!dictionary.isInitCall(file: file) && !dictionary.isTypeReferenceAssignment(file: file))
            ),
            !parentStructure.contains([.forEach, .guard]),
            !parentStructure.caseStatementPatternRanges.contains(offset),
            !parentStructure.caseExpressionRanges.contains(offset),
            !captureGroupRanges.contains(offset) else {
                return []
        }

        return [
            StyleViolation(ruleDescription: Self.description,
                           severity: configuration.severityConfiguration.severity,
                           location: Location(file: file, byteOffset: offset))
        ]
    }

    private func captureGroupRanges(in file: SwiftLintFile) -> [ByteRange] {
        return file.match(pattern: "\\{\\s*\\[(\\s*\\w+\\s+\\w+,*)+\\]", excludingSyntaxKinds: SyntaxKind.commentKinds)
            .compactMap { file.stringView.NSRangeToByteRange(start: $0.location, length: $0.length) }
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
            case let afterNameByteRange = ByteRange(location: nameOffset + nameLength, length: 0),
            let afterNameRange = file.stringView.byteRangeToNSRange(afterNameByteRange)
        else {
            return false
        }

        let contents = file.stringView
        let contentAfterName = contents.nsString.substring(from: afterNameRange.location)
        let initCallRegex =
            regex("^\\s*=\\s*(?:try[!?]?\\s+)?\\[?\\p{Lu}[^\\(\\s<]*(?:<[^\\>]*>)?(?::\\s*[^\\(\\n]+)?\\]?\\(")

        return initCallRegex.firstMatch(in: contentAfterName, options: [], range: contentAfterName.fullNSRange) != nil
    }

    func isTypeReferenceAssignment(file: SwiftLintFile) -> Bool {
        guard
            let nameOffset = nameOffset,
            let nameLength = nameLength,
            case let afterNameByteRange = ByteRange(location: nameOffset + nameLength, length: 0),
            let afterNameRange = file.stringView.byteRangeToNSRange(afterNameByteRange)
        else {
            return false
        }

        let contents = file.stringView
        let contentAfterName = contents.nsString.substring(from: afterNameRange.location)
        let typeAssignment = regex("^\\s*=\\s*(?:\\p{Lu}[^\\(\\s<]*(?:<[^\\>]*>)?\\.)*self")

        return typeAssignment.firstMatch(in: contentAfterName, options: [], range: contentAfterName.fullNSRange) != nil
    }

    var caseStatementPatternRanges: [ByteRange] {
        return ranges(with: StatementKind.case.rawValue, for: "source.lang.swift.structure.elem.pattern")
    }

    var caseExpressionRanges: [ByteRange] {
        return ranges(with: SwiftExpressionKind.tuple.rawValue, for: "source.lang.swift.structure.elem.expr")
    }

    func contains(_ statements: Set<StatementKind>) -> Bool {
        guard let statement = statementKind else {
            return false
        }
        return statements.contains(statement)
    }

    func ranges(with parentKind: String, for elementKind: String) -> [ByteRange] {
        guard parentKind == kind else {
            return []
        }

        return elements
            .filter { elementKind == $0.kind }
            .compactMap { $0.byteRange }
    }
}

private extension Collection where Element == ByteRange {
    func contains(_ index: ByteCount) -> Bool {
        return contains { $0.contains(index) }
    }
}

private extension SourceKittenDictionary {
    func traverseWithParentsDepthFirst<T>(traverseBlock: ([SourceKittenDictionary], SourceKittenDictionary) -> [T]?)
        -> [T] {
        var result: [T] = []
        traverseWithParentDepthFirst(collectingValuesInto: &result,
                                     parents: [],
                                     traverseBlock: traverseBlock)
        return result
    }

    private func traverseWithParentDepthFirst<T>(
        collectingValuesInto array: inout [T],
        parents: [SourceKittenDictionary],
        traverseBlock: ([SourceKittenDictionary], SourceKittenDictionary) -> [T]?) {
        var updatedParents = parents
        updatedParents.append(self)

        substructure.forEach { subDict in
            subDict.traverseWithParentDepthFirst(collectingValuesInto: &array,
                                                 parents: updatedParents,
                                                 traverseBlock: traverseBlock)

            if let collectedValues = traverseBlock(updatedParents, subDict) {
                array += collectedValues
            }
        }
    }
}

private extension Array where Element == SourceKittenDictionary {
    func lastIgnoringCallAndArgument() -> Element? {
        guard SwiftVersion.current >= .fiveDotFour else {
            return last
        }

        return last { element in
            element.expressionKind != .call && element.expressionKind != .argument
        }
    }
}

// extracted from https://forums.swift.org/t/pitch-declaring-local-variables-as-lazy/9287/3
private class Lazy<Result> {
    private var computation: () -> Result
    fileprivate private(set) lazy var value: Result = computation()

    init(_ computation: @escaping @autoclosure () -> Result) {
        self.computation = computation
    }
}
