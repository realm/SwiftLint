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
            "[1, 2].map { $0 + 1 }\n",
            "[1, 2].map({ $0 + 1 })\n",
            "[1, 2].map { number in\n number + 1 \n}\n",
            "[1, 2].map { _ in\n 3 \n}\n",
            "[1, 2].something { number, idx in\n return number * idx\n}\n",
            "let isEmpty = [1, 2].isEmpty()\n",
            "violations.sorted(by: { lhs, rhs in \n return lhs.location > rhs.location\n})\n",
            "rlmConfiguration.migrationBlock.map { rlmMigration in\n" +
                "return { migration, schemaVersion in\n" +
                "rlmMigration(migration.rlmMigration, schemaVersion)\n" +
                "}\n" +
            "}",
            "genericsFunc { (a: Type, b) in\n" +
                "a + b\n" +
            "}\n",
            "var label: UILabel = { (lbl: UILabel) -> UILabel in\n" +
            "   lbl.backgroundColor = .red\n" +
            "   return lbl\n" +
            "}(UILabel())\n",
            "hoge(arg: num) { num in\n" +
            "  return num\n" +
            "}\n",
            """
            ({ (manager: FileManager) in
              print(manager)
            })(FileManager.default)
            """,
            """
            withPostSideEffect { input in
                if true { print("\\(input)") }
            }
            """,
            """
            viewModel?.profileImage.didSet(weak: self) { (self, profileImage) in
                self.profileImageView.image = profileImage
            }
            """
        ],
        triggeringExamples: [
            "[1, 2].map { ↓number in\n return 3\n}\n",
            "[1, 2].map { ↓number in\n return numberWithSuffix\n}\n",
            "[1, 2].map { ↓number in\n return 3 // number\n}\n",
            "[1, 2].map { ↓number in\n return 3 \"number\"\n}\n",
            "[1, 2].something { number, ↓idx in\n return number\n}\n",
            "genericsFunc { (↓number: TypeA, idx: TypeB) in return idx\n}\n",
            "hoge(arg: num) { ↓num in\n" +
            "}\n",
            "fooFunc { ↓아 in\n }",
            "func foo () {\n bar { ↓number in\n return 3\n}\n",
            """
            viewModel?.profileImage.didSet(weak: self) { (↓self, profileImage) in
                profileImageView.image = profileImage
            }
            """
        ],
        corrections: [
            "[1, 2].map { ↓number in\n return 3\n}\n":
                "[1, 2].map { _ in\n return 3\n}\n",
            "[1, 2].map { ↓number in\n return numberWithSuffix\n}\n":
                "[1, 2].map { _ in\n return numberWithSuffix\n}\n",
            "[1, 2].map { ↓number in\n return 3 // number\n}\n":
                "[1, 2].map { _ in\n return 3 // number\n}\n",
            "[1, 2].map { ↓number in\n return 3 \"number\"\n}\n":
                "[1, 2].map { _ in\n return 3 \"number\"\n}\n",
            "[1, 2].something { number, ↓idx in\n return number\n}\n":
                "[1, 2].something { number, _ in\n return number\n}\n",
            "genericsFunc(closure: { (↓int: Int) -> Void in // do something\n}\n":
                "genericsFunc(closure: { (_: Int) -> Void in // do something\n}\n",
            "genericsFunc { (↓a, ↓b: Type) -> Void in\n}\n":
                "genericsFunc { (_, _: Type) -> Void in\n}\n",
            "genericsFunc { (↓a: Type, ↓b: Type) -> Void in\n}\n":
                "genericsFunc { (_: Type, _: Type) -> Void in\n}\n",
            "genericsFunc { (↓a: Type, ↓b) -> Void in\n}\n":
                "genericsFunc { (_: Type, _) -> Void in\n}\n",
            "genericsFunc { (a: Type, ↓b) -> Void in\nreturn a\n}\n":
                "genericsFunc { (a: Type, _) -> Void in\nreturn a\n}\n",
            "hoge(arg: num) { ↓num in\n}\n":
                "hoge(arg: num) { _ in\n}\n",
            "func foo () {\n bar { ↓number in\n return 3\n}\n":
                "func foo () {\n bar { _ in\n return 3\n}\n",
            "class C {\n #if true\n func f() {\n [1, 2].map { ↓number in\n return 3\n }\n }\n #endif\n}":
                "class C {\n #if true\n func f() {\n [1, 2].map { _ in\n return 3\n }\n }\n #endif\n}"
        ]
    )

    public func validate(file: SwiftLintFile, kind: SwiftExpressionKind,
                         dictionary: SourceKittenDictionary) -> [StyleViolation] {
        return violationRanges(in: file, dictionary: dictionary, kind: kind).map { range, name in
            let reason = "Unused parameter \"\(name)\" in a closure should be replaced with _."
            return StyleViolation(ruleDescription: type(of: self).description,
                                  severity: configuration.severity,
                                  location: Location(file: file, characterOffset: range.location),
                                  reason: reason)
        }
    }

    public func violationRanges(in file: SwiftLintFile, kind: SwiftExpressionKind,
                                dictionary: SourceKittenDictionary) -> [NSRange] {
        return violationRanges(in: file, dictionary: dictionary, kind: kind).map { $0.range }
    }

    public func substitution(for violationRange: NSRange, in file: SwiftLintFile) -> (NSRange, String) {
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
            bodyLength > 0 else {
                return []
        }

        let rangeStart = nameOffset + nameLength
        let rangeLength = (offset + length) - (nameOffset + nameLength)
        let parameters = dictionary.enclosedVarParameters
        let contents = file.linesContainer

        return parameters.compactMap { param -> (NSRange, String)? in
            guard let paramOffset = param.offset,
                let name = param.name,
                name != "_",
                let regex = try? NSRegularExpression(pattern: name,
                                                     options: [.ignoreMetacharacters]),
                let range = contents.byteRangeToNSRange(start: rangeStart, length: rangeLength)
            else {
                return nil
            }

            let paramLength = name.lengthOfBytes(using: .utf8)

            let matches = regex.matches(in: file.contents, options: [], range: range).ranges()
            for range in matches {
                guard let byteRange = contents.NSRangeToByteRange(start: range.location,
                                                                  length: range.length),
                    // if it's the parameter declaration itself, we should skip
                    byteRange.location > paramOffset,
                    case let tokens = file.syntaxMap.tokens(inByteRange: byteRange) else {
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
            if let range = contents.byteRangeToNSRange(start: paramOffset, length: paramLength) {
                return (range, name)
            }
            return nil
        }
    }

    private func isClosure(dictionary: SourceKittenDictionary) -> Bool {
        return dictionary.name.flatMap { name -> Bool in
            let length = name.bridge().length
            let range = NSRange(location: 0, length: length)
            return regex("\\A[\\s\\(]*?\\{").firstMatch(in: name, options: [], range: range) != nil
        } ?? false
    }
}
