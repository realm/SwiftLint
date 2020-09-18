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
        minSwiftVersion: .fourDotTwo,
        nonTriggeringExamples: [
            Example("""
            [1, 2].map { [weak self] num in
                self?.handle(num)
            }
            """),
            Example("""
            let failure: Failure = { [weak self, unowned delegate = self.delegate!] foo in
                delegate.handle(foo, self)
            }
            """),
            Example("""
            numbers.forEach({
                [weak handler] in
                handler?.handle($0)
            })
            """),
            Example("""
            withEnvironment(apiService: MockService(fetchProjectResponse: project)) {
                [Device.phone4_7inch, Device.phone5_8inch, Device.pad].forEach { device in
                    device.handle()
                }
            }
            """),
            Example("{ [foo] _ in foo.bar() }()"),
            Example("sizes.max().flatMap { [(offset: offset, size: $0)] } ?? []"),
            Example("""
            [1, 2].map { [self] num in
                handle(num)
            }
            """),
            Example("""
            [1, 2].map { [self, unowned delegate = self.delegate!] num in
                delegate.handle(num)
            }
            """),
            Example("""
            [1, 2].map {
                [ weak
                  delegate,
                  self
                ] num in
                delegate.handle(num)
            }
            """)
        ],
        triggeringExamples: [
            Example("""
            [1, 2].map { [↓weak self] num in
                print(num)
            }
            """),
            Example("""
            let failure: Failure = { [weak self, ↓unowned delegate = self.delegate!] foo in
                self?.handle(foo)
            }
            """),
            Example("""
            let failure: Failure = { [↓weak self, ↓unowned delegate = self.delegate!] foo in
                print(foo)
            }
            """),
            Example("""
            numbers.forEach({
                [weak handler] in
                print($0)
            })
            """),
            Example("""
            numbers.forEach({
                [self, weak handler] in
                print($0)
            })
            """),
            Example("""
            withEnvironment(apiService: MockService(fetchProjectResponse: project)) { [↓foo] in
                [Device.phone4_7inch, Device.phone5_8inch, Device.pad].forEach { device in
                    device.handle()
                }
            }
            """),
            Example("{ [↓foo] in _ }()")
        ]
    )

    private let captureListRegex = regex("^\\{\\s*\\[([^\\]]+)\\]")

    private let selfKeyword = "self"

    public func validate(file: SwiftLintFile, kind: SwiftExpressionKind,
                         dictionary: SourceKittenDictionary) -> [StyleViolation] {
        let contents = file.stringView
        guard kind == .closure,
            let offset = dictionary.offset,
            let length = dictionary.length,
            let closureByteRange = dictionary.byteRange,
            let closureRange = contents.byteRangeToNSRange(closureByteRange)
            else { return [] }

        let firstSubstructureOffset = dictionary.substructure.first?.offset ?? (offset + length)
        let captureListSearchLength = firstSubstructureOffset - offset
        let captureListSearchByteRange = ByteRange(location: offset, length: captureListSearchLength)
        guard let captureListSearchRange = contents.byteRangeToNSRange(captureListSearchByteRange),
            let match = captureListRegex.firstMatch(in: file.contents, options: [], range: captureListSearchRange)
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
                let word = item.trimmingCharacters(in: .whitespacesAndNewlines)
                guard word != selfKeyword else { return }
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

    private func identifierStrings(in file: SwiftLintFile, byteRange: ByteRange) -> Set<String> {
        let identifiers = file.syntaxMap
            .tokens(inByteRange: byteRange)
            .compactMap { token -> String? in
                guard token.kind == .identifier || token.kind == .keyword else { return nil }
                return file.contents(for: token)
            }
        return Set(identifiers)
    }

    private func violations(in file: SwiftLintFile, references: [(String, Int)],
                            identifiers: Set<String>, captureListRange: NSRange) -> [StyleViolation] {
        return references.compactMap { reference, location -> StyleViolation? in
            guard !identifiers.contains(reference) else { return nil }
            let offset = captureListRange.location + location
            let reason = "Unused reference \(reference) in a capture list should be removed."
            return StyleViolation(
                ruleDescription: Self.description,
                severity: configuration.severity,
                location: Location(file: file, characterOffset: offset),
                reason: reason
            )
        }
    }
}
