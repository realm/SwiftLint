import Foundation
import SourceKittenFramework

public struct UnusedCaptureListRule: ASTRule, ConfigurationProviderRule, AutomaticTestableRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static var description = RuleDescription(
        identifier: "unused_capture_list",
        name: "Unused Capture List",
        description: "Unused reference in a capture list should be removed.",
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
            """,
            "{ [foo] in foo.bar() }()",
            "sizes.max().flatMap { [(offset: offset, size: $0)] } ?? []"
        ],
        triggeringExamples: [
            """
            [1, 2].map { [↓weak self] num in
                print(num)
            }
            """,
            """
            let failure: Failure = { [weak self, ↓unowned delegate = self.delegate!] foo in
                self?.handle(foo)
            }
            """,
            """
            let failure: Failure = { [↓weak self, ↓unowned delegate = self.delegate!] foo in
                print(foo)
            }
            """,
            "{ [↓foo] in _ }()"
        ]
    )

    private let captureListRegex = regex("^\\{\\h*\\[([^\\]]+)\\].*\\bin\\b")

    public func validate(file: File, kind: SwiftExpressionKind,
                         dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        let contents = file.contents.bridge()
        guard kind == .closure,
            let offset = dictionary.offset,
            let length = dictionary.length,
            let closureRange = contents.byteRangeToNSRange(start: offset, length: length),
            let match = captureListRegex.firstMatch(in: file.contents, options: [], range: closureRange)
            else { return [] }

        let captureListRange = match.range(at: 1)
        guard captureListRange.location != NSNotFound,
            captureListRange.length > 0 else { return [] }

        let captureList = contents.substring(with: captureListRange)
        let references = referencesAndLocationsFromCaptureList(captureList)

        let restOfClosureLocation = captureListRange.location + captureListRange.length + 1
        let restOfClosureLength = closureRange.length - (restOfClosureLocation - closureRange.location)
        let restOfClosureRange = NSRange(location: restOfClosureLocation, length: restOfClosureLength)
        guard let restOfClosureByteRange = contents
            .NSRangeToByteRange(start: restOfClosureRange.location, length: restOfClosureRange.length)
            else { return [] }

        let identifiers = identifierStrings(in: file, byteRange: restOfClosureByteRange)
        return violations(in: file, references: references,
                          identifiers: identifiers, captureListRange: captureListRange)
    }

    // MARK: - Private

    private func referencesAndLocationsFromCaptureList(_ captureList: String) -> [(String, Int)] {
        var locationOffset = 0
        return captureList.components(separatedBy: ",")
            .reduce(into: [(String, Int)]()) { referencesAndLocations, item in
                let item = item.bridge()
                let range = item.rangeOfCharacter(from: CharacterSet.whitespacesAndNewlines.inverted)
                guard range.location != NSNotFound else { return }

                let location = range.location + locationOffset
                locationOffset += item.length + 1 // 1 for comma
                let reference = item.components(separatedBy: "=")
                    .first?
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .components(separatedBy: .whitespaces)
                    .last
                if let reference = reference {
                    referencesAndLocations.append((reference, location))
                }
            }
    }

    private func identifierStrings(in file: File, byteRange: NSRange) -> [String] {
        let contents = file.contents.bridge()
        return file.syntaxMap
            .tokens(inByteRange: byteRange)
            .compactMap { token -> String? in
                guard token.type == SyntaxKind.identifier.rawValue || token.type == SyntaxKind.keyword.rawValue,
                    let range = contents.byteRangeToNSRange(start: token.offset, length: token.length)
                    else { return nil }
                return contents.substring(with: range)
            }
    }

    private func violations(in file: File, references: [(String, Int)],
                            identifiers: [String], captureListRange: NSRange) -> [StyleViolation] {
        return references.compactMap { reference, location -> StyleViolation? in
            guard !identifiers.contains(reference) else { return nil }
            let offset = captureListRange.location + location
            let reason = "Unused reference \(reference) in a capture list should be removed."
            return StyleViolation(
                ruleDescription: type(of: self).description,
                severity: configuration.severity,
                location: Location(file: file, characterOffset: offset),
                reason: reason
            )
        }
    }
}
