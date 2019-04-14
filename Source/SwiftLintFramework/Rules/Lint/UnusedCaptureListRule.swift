import Foundation
import SourceKittenFramework

public struct UnusedCaptureListRule: ASTRule, ConfigurationProviderRule, AutomaticTestableRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static var description = RuleDescription(
        identifier: "unused_capture_list",
        name: "Unused Capture List",
        description: "Unused reference in capture list should be removed.",
        kind: .lint,
        nonTriggeringExamples: [
            """
            [1, 2].map { [weak self] num in
                self?.handle(num)
            }
            """,
            """
            let failure: Failure = { [weak self, unowned delegate = self.delegate!] foo in
                delegate.handle(foo, self)
            }
            """
        ],
        triggeringExamples: [
            """
            [1, 2].map { [weak ↓self] num in
                print(num)
            }
            """,
            """
            let failure: Failure = { [weak self, unowned ↓delegate = self.delegate!] foo in
                self?.handle(foo)
            }
            """,
            """
            let failure: Failure = { [weak ↓self, unowned ↓delegate = self.delegate!] foo in
                print(foo)
            }
            """
        ]
    )

    private let captureListRegex = regex("^\\{\\h*\\[([^\\]]+)\\]")

    public func validate(file: File, kind: SwiftExpressionKind,
                         dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        let contents = file.contents.bridge()
        guard kind == .closure,
            let offset = dictionary.offset,
            let length = dictionary.length,
            let closureRange = contents.byteRangeToNSRange(start: offset, length: length),
            let match = captureListRegex.firstMatch(in: file.contents, options: [], range: closureRange) else { return [] }

        let captureListRange = match.range(at: 1)
        guard captureListRange.location != NSNotFound else { return [] }

        let captureList = contents.substring(with: captureListRange)
        let references = referencesFromCaptureList(captureList)

        let restOfClosureLocation = captureListRange.location + captureListRange.length + 1
        let restOfClosureLength = closureRange.length - (restOfClosureLocation - closureRange.location)
        let restOfClosureRange = NSRange(location: restOfClosureLocation, length: restOfClosureLength)
        guard let restOfClosureByteRange = contents
            .NSRangeToByteRange(start: restOfClosureRange.location, length: restOfClosureRange.length) else { return [] }

        let tokens = file.syntaxMap.tokens(inByteRange: restOfClosureByteRange)
        let identifiers = tokens
            .compactMap { token -> String? in
                guard token.type == SyntaxKind.identifier.rawValue,
                    let range = contents.byteRangeToNSRange(start: token.offset, length: token.length)
                    else { return nil }
                return contents.substring(with: range)
            }
        print(references)
        print(identifiers)
        return []
    }

    // MARK: - Private

    private func referencesFromCaptureList(_ captureList: String) -> [String] {
        return captureList.components(separatedBy: ",")
            .compactMap {
                $0.components(separatedBy: "=").first?
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .components(separatedBy: .whitespaces)
                    .last
            }
    }
}
