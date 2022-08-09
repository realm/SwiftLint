import SourceKittenFramework

public struct ForWhereRule: ASTRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "for_where",
        name: "For Where",
        description: "`where` clauses are preferred over a single `if` inside a `for`.",
        kind: .idiomatic,
        nonTriggeringExamples: [
            Example("""
            for user in users where user.id == 1 { }
            """),
            // if let
            Example("""
            for user in users {
              if let id = user.id { }
            }
            """),
            // if var
            Example("""
            for user in users {
              if var id = user.id { }
            }
            """),
            // if with else
            Example("""
            for user in users {
              if user.id == 1 { } else { }
            }
            """),
            // if with else if
            Example("""
            for user in users {
              if user.id == 1 {
              } else if user.id == 2 { }
            }
            """),
            // if is not the only expression inside for
            Example("""
            for user in users {
              if user.id == 1 { }
              print(user)
            }
            """),
            // if a variable is used
            Example("""
            for user in users {
              let id = user.id
              if id == 1 { }
            }
            """),
            // if something is after if
            Example("""
            for user in users {
              if user.id == 1 { }
              return true
            }
            """),
            // condition with multiple clauses
            Example("""
            for user in users {
              if user.id == 1 && user.age > 18 { }
            }
            """),
            // if case
            Example("""
            for (index, value) in array.enumerated() {
              if case .valueB(_) = value {
                return index
              }
            }
            """)
        ],
        triggeringExamples: [
            Example("""
            for user in users {
              ↓if user.id == 1 { return true }
            }
            """),
            Example("""
            for subview in subviews {
                ↓if !(subview is UIStackView) {
                    subview.removeConstraints(subview.constraints)
                    subview.removeFromSuperview()
                }
            }
            """)
        ]
    )

    private static let commentKinds = SyntaxKind.commentAndStringKinds

    public func validate(file: SwiftLintFile, kind: StatementKind,
                         dictionary: SourceKittenDictionary) -> [StyleViolation] {
        guard kind == .forEach,
            let subDictionary = forBody(dictionary: dictionary),
            subDictionary.substructure.count == 1,
            let bodyDictionary = subDictionary.substructure.first,
            bodyDictionary.statementKind == .if,
            isOnlyOneIf(dictionary: bodyDictionary),
            isOnlyIfInsideFor(forDictionary: subDictionary, ifDictionary: bodyDictionary, file: file),
            !isComplexCondition(dictionary: bodyDictionary, file: file),
            let offset = bodyDictionary .offset else {
                return []
        }

        return [
            StyleViolation(ruleDescription: Self.description,
                           severity: configuration.severity,
                           location: Location(file: file, byteOffset: offset))
        ]
    }

    private func forBody(dictionary: SourceKittenDictionary) -> SourceKittenDictionary? {
        return dictionary.substructure.first(where: { subDict -> Bool in
            subDict.statementKind == .brace
        })
    }

    private func isOnlyOneIf(dictionary: SourceKittenDictionary) -> Bool {
        let substructure = dictionary.substructure
        let onlyOneBlock = substructure.filter { $0.statementKind == .brace }.count == 1
        let noOtherIf = substructure.allSatisfy { $0.statementKind != .if }
        return onlyOneBlock && noOtherIf
    }

    private func isOnlyIfInsideFor(forDictionary: SourceKittenDictionary,
                                   ifDictionary: SourceKittenDictionary,
                                   file: SwiftLintFile) -> Bool {
        guard let offset = forDictionary.offset,
            let length = forDictionary.length,
            let ifOffset = ifDictionary.offset,
            let ifLength = ifDictionary.length else {
                return false
        }

        let beforeIfRange = ByteRange(location: offset, length: ifOffset - offset)
        let ifFinalPosition = ifOffset + ifLength
        let afterIfRange = ByteRange(location: ifFinalPosition, length: offset + length - ifFinalPosition)
        let allKinds = file.syntaxMap.kinds(inByteRange: beforeIfRange) +
            file.syntaxMap.kinds(inByteRange: afterIfRange)

        let doesntContainComments = !allKinds.contains { kind in
            !Self.commentKinds.contains(kind)
        }

        return doesntContainComments
    }

    private func isComplexCondition(dictionary: SourceKittenDictionary, file: SwiftLintFile) -> Bool {
        let kind = "source.lang.swift.structure.elem.condition_expr"
        return dictionary.elements.contains { element in
            guard element.kind == kind,
                let range = element.byteRange.flatMap(file.stringView.byteRangeToNSRange)
            else {
                return false
            }

            let containsKeyword = file.match(pattern: "\\blet|var|case\\b", with: [.keyword], range: range).isNotEmpty
            if containsKeyword {
                return true
            }

            return file.match(pattern: "\\|\\||&&", with: [], range: range).isNotEmpty
        }
    }
}
