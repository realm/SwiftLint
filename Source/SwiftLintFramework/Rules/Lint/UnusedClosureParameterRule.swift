import Foundation
import SourceKittenFramework

public struct UnusedClosureParameterRule: SubstitutionCorrectableASTRule, ConfigurationProviderRule,
                                          AutomaticTestableRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "unused_closure_parameter",
        name: "Unused Closure Parameter",
        description: "Unused parameter in a closure should be replaced with _.",
        kind: .lint,
        nonTriggeringExamples: [
            Example("[1, 2].map { $0 + 1 }\n"),
            Example("[1, 2].map({ $0 + 1 })\n"),
            Example("[1, 2].map { number in\n number + 1 \n}\n"),
            Example("[1, 2].map { _ in\n 3 \n}\n"),
            Example("[1, 2].something { number, idx in\n return number * idx\n}\n"),
            Example("let isEmpty = [1, 2].isEmpty()\n"),
            Example("violations.sorted(by: { lhs, rhs in \n return lhs.location > rhs.location\n})\n"),
            Example("rlmConfiguration.migrationBlock.map { rlmMigration in\n" +
                "return { migration, schemaVersion in\n" +
                "rlmMigration(migration.rlmMigration, schemaVersion)\n" +
                "}\n" +
            "}"),
            Example("genericsFunc { (a: Type, b) in\n" +
                "a + b\n" +
            "}\n"),
            Example("var label: UILabel = { (lbl: UILabel) -> UILabel in\n" +
            "   lbl.backgroundColor = .red\n" +
            "   return lbl\n" +
            "}(UILabel())\n"),
            Example("hoge(arg: num) { num in\n" +
            "  return num\n" +
            "}\n"),
            Example("""
            ({ (manager: FileManager) in
              print(manager)
            })(FileManager.default)
            """),
            Example("""
            withPostSideEffect { input in
                if true { print("\\(input)") }
            }
            """),
            Example("""
            viewModel?.profileImage.didSet(weak: self) { (self, profileImage) in
                self.profileImageView.image = profileImage
            }
            """)
        ],
        triggeringExamples: [
            Example("[1, 2].map { ↓number in\n return 3\n}\n"),
            Example("[1, 2].map { ↓number in\n return numberWithSuffix\n}\n"),
            Example("[1, 2].map { ↓number in\n return 3 // number\n}\n"),
            Example("[1, 2].map { ↓number in\n return 3 \"number\"\n}\n"),
            Example("[1, 2].something { number, ↓idx in\n return number\n}\n"),
            Example("genericsFunc { (↓number: TypeA, idx: TypeB) in return idx\n}\n"),
            Example("hoge(arg: num) { ↓num in\n" +
            "}\n"),
            Example("fooFunc { ↓아 in\n }"),
            Example("func foo () {\n bar { ↓number in\n return 3\n}\n"),
            Example("""
            viewModel?.profileImage.didSet(weak: self) { (↓self, profileImage) in
                profileImageView.image = profileImage
            }
            """)
        ],
        corrections: [
            Example("[1, 2].map { ↓number in\n return 3\n}\n"):
                Example("[1, 2].map { _ in\n return 3\n}\n"),
            Example("[1, 2].map { ↓number in\n return numberWithSuffix\n}\n"):
                Example("[1, 2].map { _ in\n return numberWithSuffix\n}\n"),
            Example("[1, 2].map { ↓number in\n return 3 // number\n}\n"):
                Example("[1, 2].map { _ in\n return 3 // number\n}\n"),
            Example("[1, 2].something { number, ↓idx in\n return number\n}\n"):
                Example("[1, 2].something { number, _ in\n return number\n}\n"),
            Example("genericsFunc(closure: { (↓int: Int) -> Void in // do something\n})\n"):
                Example("genericsFunc(closure: { (_: Int) -> Void in // do something\n})\n"),
            Example("genericsFunc { (↓a, ↓b: Type) -> Void in\n}\n"):
                Example("genericsFunc { (_, _: Type) -> Void in\n}\n"),
            Example("genericsFunc { (↓a: Type, ↓b: Type) -> Void in\n}\n"):
                Example("genericsFunc { (_: Type, _: Type) -> Void in\n}\n"),
            Example("genericsFunc { (↓a: Type, ↓b) -> Void in\n}\n"):
                Example("genericsFunc { (_: Type, _) -> Void in\n}\n"),
            Example("genericsFunc { (a: Type, ↓b) -> Void in\nreturn a\n}\n"):
                Example("genericsFunc { (a: Type, _) -> Void in\nreturn a\n}\n"),
            Example("hoge(arg: num) { ↓num in\n}\n"):
                Example("hoge(arg: num) { _ in\n}\n"),
            Example("""
            func foo () {
              bar { ↓number in
                return 3
              }
            }
            """):
                Example("""
                func foo () {
                  bar { _ in
                    return 3
                  }
                }
                """),
            Example("class C {\n #if true\n func f() {\n [1, 2].map { ↓number in\n return 3\n }\n }\n #endif\n}"):
                Example("class C {\n #if true\n func f() {\n [1, 2].map { _ in\n return 3\n }\n }\n #endif\n}")
        ]
    )

    public func validate(file: SwiftLintFile, kind: SwiftExpressionKind,
                         dictionary: SourceKittenDictionary) -> [StyleViolation] {
        return violationRanges(in: file, dictionary: dictionary, kind: kind).map { range, name in
            let reason = "Unused parameter \"\(name)\" in a closure should be replaced with _."
            return StyleViolation(ruleDescription: Self.description,
                                  severity: configuration.severity,
                                  location: Location(file: file, characterOffset: range.location),
                                  reason: reason)
        }
    }

    public func violationRanges(in file: SwiftLintFile, kind: SwiftExpressionKind,
                                dictionary: SourceKittenDictionary) -> [NSRange] {
        return violationRanges(in: file, dictionary: dictionary, kind: kind).map { $0.range }
    }

    public func substitution(for violationRange: NSRange, in file: SwiftLintFile) -> (NSRange, String)? {
        return (violationRange, "_")
    }

    private func violationRanges(in file: SwiftLintFile, dictionary: SourceKittenDictionary,
                                 kind: SwiftExpressionKind) -> [(range: NSRange, name: String)] {
        guard kind == .call,
            !isClosure(dictionary: dictionary),
            let offset = dictionary.offset,
            let length = dictionary.length,
            let nameOffset = dictionary.nameOffset,
            let nameLength = dictionary.nameLength,
            let bodyLength = dictionary.bodyLength,
            bodyLength > 0
        else {
            return []
        }

        let rangeStart = nameOffset + nameLength
        let rangeLength = (offset + length) - (nameOffset + nameLength)
        let byteRange = ByteRange(location: rangeStart, length: rangeLength)
        let parameters = dictionary.enclosedVarParameters
        let contents = file.stringView

        return parameters.compactMap { param -> (NSRange, String)? in
            self.rangeAndName(parameter: param, contents: contents, byteRange: byteRange, file: file)
        }
    }

    private func rangeAndName(parameter: SourceKittenDictionary, contents: StringView, byteRange: ByteRange,
                              file: SwiftLintFile) -> (range: NSRange, name: String)? {
        guard let paramOffset = parameter.offset,
            let name = parameter.name,
            name != "_",
            let regex = try? NSRegularExpression(pattern: name,
                                                 options: [.ignoreMetacharacters]),
            let range = contents.byteRangeToNSRange(byteRange)
        else {
            return nil
        }

        let paramLength = ByteCount(name.lengthOfBytes(using: .utf8))

        let matches = regex.matches(in: file.contents, options: [], range: range).ranges()
        for range in matches {
            guard let byteRange = contents.NSRangeToByteRange(start: range.location,
                                                              length: range.length),
                // if it's the parameter declaration itself, we should skip
                byteRange.location > paramOffset,
                case let tokens = file.syntaxMap.tokens(inByteRange: byteRange)
            else {
                continue
            }

            let token = tokens.first(where: { token -> Bool in
                return (token.kind == .identifier
                    || (token.kind == .keyword && name == "self")) &&
                    token.offset == byteRange.location &&
                    token.length == byteRange.length
            })

            // found a usage, there's no violation!
            guard token == nil else {
                return nil
            }
        }
        let violationByteRange = ByteRange(location: paramOffset, length: paramLength)
        return contents.byteRangeToNSRange(violationByteRange).map { range in
            return (range, name)
        }
    }

    private func isClosure(dictionary: SourceKittenDictionary) -> Bool {
        return dictionary.name.flatMap { name -> Bool in
            let range = name.fullNSRange
            return regex("\\A[\\s\\(]*?\\{").firstMatch(in: name, options: [], range: range) != nil
        } ?? false
    }
}
