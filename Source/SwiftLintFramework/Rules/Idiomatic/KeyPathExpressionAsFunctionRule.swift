import Foundation
import SourceKittenFramework

public struct KeyPathExpressionAsFunctionRule: ASTRule, OptInRule, ConfigurationProviderRule, AutomaticTestableRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "key_path_expression_as_function",
        name: "Key Path Expression as Function",
        description: "Prefer using key paths instead of closures when possible.",
        kind: .idiomatic,
        minSwiftVersion: .fiveDotTwo,
        nonTriggeringExamples: [
            Example("let emails = users.map(\\.email)"),
            Example("let admins = users.filter(\\.isAdmin)"),
            Example("let all = users.filter { _ in true }"),
            Example("let emails = users.map { $0.email() }"),
            Example("""
            let violatingRanges = violatingRanges.filter { range in
                let region = fileRegions.first {
                    $0.contains(Location(file: self, characterOffset: range.location))
                }
                return region?.isRuleEnabled(rule) ?? true
            }
            """),
            Example("let ones = values.filter { $0 == 1 }")
        ],
        triggeringExamples: [
            Example("let emails = users.map ↓{ $0.email }"),
            Example("let emails = users.map(↓{ $0.email })"),
            Example("let admins = users.filter(where: ↓{ $0.isAdmin })")
        ]
    )

    // MARK: - ASTRule

    public func validate(file: SwiftLintFile,
                         kind: SwiftExpressionKind,
                         dictionary: SourceKittenDictionary) -> [StyleViolation] {
        guard SwiftVersion.current >= Self.description.minSwiftVersion else {
            return []
        }

        return violationRanges(in: file, kind: kind, dictionary: dictionary).map {
            StyleViolation(ruleDescription: Self.description,
                           severity: configuration.severity,
                           location: Location(file: file, byteOffset: $0))
        }
    }

    private func violationRanges(in file: SwiftLintFile,
                                 kind: SwiftExpressionKind,
                                 dictionary: SourceKittenDictionary) -> [ByteCount] {
        guard kind == .call else {
            return []
        }

        let closures = dictionary.substructure.compactMap { dictionary -> SourceKittenDictionary? in
            if dictionary.isClosure {
                return dictionary
            }

            if dictionary.isClosureArgument {
                return dictionary.substructure.first
            }

            return nil
        }

        return closures.compactMap { dictionary -> ByteCount? in
            guard let offset = dictionary.offset,
                  let bodyOffset = dictionary.bodyOffset,
                  let bodyLength = dictionary.bodyLength,
                  bodyLength > 0,
                  case let byteRange = ByteRange(location: bodyOffset, length: bodyLength),
                  let range = file.stringView.byteRangeToNSRange(byteRange) else {
                return nil
            }

            // Right now, this rule only catches cases where $0 is used (instead of named parameters) for simplicity
            guard !file.match(pattern: #"\A\s*\$0\.\w+\b\s*\z"#, with: [.identifier, .identifier],
                              range: range).isEmpty else {
                return nil
            }

            return offset
        }
    }
}

private extension SourceKittenDictionary {
    var isClosure: Bool {
        return kind.flatMap(SwiftExpressionKind.init(rawValue:)) == .closure
    }

    var isClosureArgument: Bool {
        return kind.flatMap(SwiftExpressionKind.init(rawValue:)) == .argument &&
            substructure.count == 1 &&
            substructure.allSatisfy { $0.isClosure }
    }
}
