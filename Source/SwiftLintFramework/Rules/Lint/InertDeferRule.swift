import Foundation
import SourceKittenFramework

public struct InertDeferRule: ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "inert_defer",
        name: "Inert Defer",
        description: "If defer is at the end of its parent scope, it will be executed right where it is anyway.",
        kind: .lint,
        nonTriggeringExamples: [
            Example("""
            func example3() {
                defer { /* deferred code */ }

                print("other code")
            }
            """),
            Example("""
            func example4() {
                if condition {
                    defer { /* deferred code */ }
                    print("other code")
                }
            }
            """)
        ],
        triggeringExamples: [
            Example("""
            func example0() {
                ↓defer { /* deferred code */ }
            }
            """),
            Example("""
            func example1() {
                ↓defer { /* deferred code */ }
                // comment
            }
            """),
            Example("""
            func example2() {
                if condition {
                    ↓defer { /* deferred code */ }
                    // comment
                }
            }
            """)
        ]
    )

    public func validate(file: SwiftLintFile) -> [StyleViolation] {
        return file
            .match(pattern: "defer\\s*\\{", with: [.keyword])
            .filter(file.shouldReportViolation(for:))
            .map { range in
                StyleViolation(ruleDescription: Self.description, severity: configuration.severity,
                               location: Location(file: file, characterOffset: range.location))
            }
    }
}

private extension SwiftLintFile {
    func shouldReportViolation(for range: NSRange) -> Bool {
        guard let byteRange = stringView.NSRangeToByteRange(start: range.location, length: range.length),
            case let kinds = structureDictionary.kinds(forByteOffset: byteRange.upperBound),
            let brace = kinds.enumerated().lazy.reversed().first(where: isBrace),
            brace.offset > kinds.startIndex else {
            return false
        }

        let outerKindIndex = kinds.index(before: brace.offset)
        let outerKind = kinds[outerKindIndex]
        let braceEnd = brace.element.byteRange.upperBound
        let tokensRange = ByteRange(location: braceEnd, length: outerKind.byteRange.upperBound - braceEnd)
        let tokens = syntaxMap.tokens(inByteRange: tokensRange)
        return !tokens.contains(where: isNotComment)
    }
}

private func isBrace(offset: Int, element: (kind: String, byteRange: ByteRange)) -> Bool {
    return StatementKind(rawValue: element.kind) == .brace
}

private func isNotComment(token: SwiftLintSyntaxToken) -> Bool {
    guard let kind = token.kind else {
        return false
    }

    return !SyntaxKind.commentKinds.contains(kind)
}
