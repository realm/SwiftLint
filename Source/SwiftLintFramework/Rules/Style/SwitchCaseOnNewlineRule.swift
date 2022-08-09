import SourceKittenFramework

private func wrapInSwitch(_ str: String, file: StaticString = #file, line: UInt = #line) -> Example {
    return Example("""
    switch foo {
        \(str)
    }
    """, file: file, line: line)
}

public struct SwitchCaseOnNewlineRule: ASTRule, ConfigurationProviderRule, OptInRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "switch_case_on_newline",
        name: "Switch Case on Newline",
        description: "Cases inside a switch should always be on a newline",
        kind: .style,
        nonTriggeringExamples: [
            Example("/*case 1: */return true"),
            Example("//case 1:\n return true"),
            Example("let x = [caseKey: value]"),
            Example("let x = [key: .default]"),
            Example("if case let .someEnum(value) = aFunction([key: 2]) { }"),
            Example("guard case let .someEnum(value) = aFunction([key: 2]) { }"),
            Example("for case let .someEnum(value) = aFunction([key: 2]) { }"),
            Example("enum Environment {\n case development\n}"),
            Example("enum Environment {\n case development(url: URL)\n}"),
            Example("enum Environment {\n case development(url: URL) // staging\n}"),

            wrapInSwitch("case 1:\n return true"),
            wrapInSwitch("default:\n return true"),
            wrapInSwitch("case let value:\n return true"),
            wrapInSwitch("case .myCase: // error from network\n return true"),
            wrapInSwitch("case let .myCase(value) where value > 10:\n return false"),
            wrapInSwitch("case let .myCase(value)\n where value > 10:\n return false"),
            wrapInSwitch("""
            case let .myCase(code: lhsErrorCode, description: _)
             where lhsErrorCode > 10:
            return false
            """),
            wrapInSwitch("case #selector(aFunction(_:)):\n return false\n"),
            Example("""
            do {
              let loadedToken = try tokenManager.decodeToken(from: response)
              return loadedToken
            } catch { throw error }
            """)
        ],
        triggeringExamples: [
            wrapInSwitch("↓case 1: return true"),
            wrapInSwitch("↓case let value: return true"),
            wrapInSwitch("↓default: return true"),
            wrapInSwitch("↓case \"a string\": return false"),
            wrapInSwitch("↓case .myCase: return false // error from network"),
            wrapInSwitch("↓case let .myCase(value) where value > 10: return false"),
            wrapInSwitch("↓case #selector(aFunction(_:)): return false\n"),
            wrapInSwitch("↓case let .myCase(value)\n where value > 10: return false"),
            wrapInSwitch("↓case .first,\n .second: return false")
        ]
    )

    public func validate(file: SwiftLintFile, kind: StatementKind,
                         dictionary: SourceKittenDictionary) -> [StyleViolation] {
        guard kind == .switch else {
            return []
        }

        return dictionary.substructure.compactMap { dictionary in
            validateCase(file: file, dictionary: dictionary)
        }
    }

    private func validateCase(file: SwiftLintFile, dictionary: SourceKittenDictionary) -> StyleViolation? {
        guard dictionary.kind.flatMap(StatementKind.init) == .case,
              let offset = dictionary.offset,
              let length = dictionary.length,
              let lastElement = dictionary.elements.last,
              let lastElementOffset = lastElement.offset,
              let lastElementLength = lastElement.length,
              case let start = lastElementOffset + lastElementLength,
              case let rangeLength = offset + length - start,
              case let byteRange = ByteRange(location: start, length: rangeLength),
              let firstToken = firstNonCommentToken(inByteRange: byteRange, file: file),
              let (tokenLine, _) = file.stringView.lineAndCharacter(forByteOffset: firstToken.offset),
              let (caseEndLine, _) = file.stringView.lineAndCharacter(forByteOffset: start),
              tokenLine == caseEndLine else {
            return nil
        }

        return StyleViolation(ruleDescription: Self.description,
                              severity: configuration.severity,
                              location: Location(file: file, byteOffset: offset))
    }

    private func firstNonCommentToken(inByteRange byteRange: ByteRange, file: SwiftLintFile) -> SwiftLintSyntaxToken? {
        return file.syntaxMap.tokens(inByteRange: byteRange).first { token -> Bool in
            guard let kind = token.kind else {
                return false
            }

            return !SyntaxKind.commentKinds.contains(kind)
        }
    }
}
