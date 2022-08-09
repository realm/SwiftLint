import Foundation
import SourceKittenFramework

public struct ImplicitGetterRule: ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "implicit_getter",
        name: "Implicit Getter",
        description: "Computed read-only properties and subscripts should avoid using the get keyword.",
        kind: .style,
        nonTriggeringExamples: ImplicitGetterRuleExamples.nonTriggeringExamples,
        triggeringExamples: ImplicitGetterRuleExamples.triggeringExamples
    )

    public func validate(file: SwiftLintFile) -> [StyleViolation] {
        let getTokens = findGetTokens(file: file)

        let violatingLocations = getTokens.compactMap { token -> (ByteCount, SwiftDeclarationKind?)? in
            // the last element is the deepest structure
            guard let dict = declarations(forByteOffset: token.offset,
                                          structureDictionary: file.structureDictionary).last else {
                return nil
            }

            // If there's a setter, `get` is allowed
            if SwiftVersion.current < .fiveDotTwo || dict.accessibility != nil {
                guard dict.setterAccessibility == nil else {
                    return nil
                }
            } else {
                guard let range = dict.byteRange.flatMap(file.stringView.byteRangeToNSRange) else {
                    return nil
                }

                let setTokens = findSetTokens(file: file, range: range)
                let hasSetToken = setTokens.contains { token in
                    // the last element is the deepest structure
                    guard let setDict = declarations(forByteOffset: token.offset,
                                                     structureDictionary: file.structureDictionary).last else {
                        return false
                    }

                    return setDict.offset == dict.offset
                }

                guard !hasSetToken else {
                    return nil
                }
            }

            // If there's another keyword after `get`, it's allowed (e.g. `get async`)
            if SwiftVersion.current >= .fiveDotFive {
                guard let byteRange = dict.byteRange else {
                    return nil
                }

                let nextToken = file.syntaxMap.tokens(inByteRange: byteRange)
                    .first { $0.offset > token.offset }

                let allowedKeywords: Set = ["throws", "async"]
                if let nextToken = nextToken,
                   allowedKeywords.contains(file.contents(for: nextToken) ?? "") {
                    return nil
                }
            }

            let kind = dict.declarationKind
            return (token.offset, kind)
        }

        return violatingLocations.map { offset, kind in
            let reason = kind.map { kind -> String in
                let kindString = kind == .functionSubscript ? "subscripts" : "properties"
                return "Computed read-only \(kindString) should avoid using the get keyword."
            }

            return StyleViolation(ruleDescription: Self.description,
                                  severity: configuration.severity,
                                  location: Location(file: file, byteOffset: offset),
                                  reason: reason)
        }
    }

    private func findGetTokens(file: SwiftLintFile) -> [SwiftLintSyntaxToken] {
        let pattern = "\\{[^\\{]*?\\s+get\\b"
        let attributesKinds: Set<SyntaxKind> = [.attributeBuiltin, .attributeID]
        return file.rangesAndTokens(matching: pattern).compactMap { _, tokens in
            let kinds = tokens.kinds
            guard let token = tokens.last,
                token.kind == .keyword,
                attributesKinds.isDisjoint(with: kinds) else {
                    return nil
            }

            return token
        }
    }

    private func findSetTokens(file: SwiftLintFile, range: NSRange?) -> [SwiftLintSyntaxToken] {
        let pattern = "\\bset\\b"
        return file.rangesAndTokens(matching: pattern).compactMap { _, tokens in
            guard tokens.count == 1,
                let token = tokens.last,
                token.kind == .keyword else {
                    return nil
            }

            return token
        }
    }
}

private extension ImplicitGetterRule {
    func declarations(forByteOffset byteOffset: ByteCount,
                      structureDictionary: SourceKittenDictionary) -> [SourceKittenDictionary] {
        var results = [SourceKittenDictionary]()
        let allowedKinds = SwiftDeclarationKind.variableKinds.subtracting([.varParameter])
            .union([.functionSubscript])

        func parse(dictionary: SourceKittenDictionary, parentKind: SwiftDeclarationKind?) {
            // Only accepts declarations which contains a body and contains the
            // searched byteOffset
            guard let kind = dictionary.declarationKind,
                let byteRange = dictionary.byteRange,
                byteRange.contains(byteOffset)
            else {
                return
            }

            if parentKind != .protocol && allowedKinds.contains(kind) {
                results.append(dictionary)
            }

            for dictionary in dictionary.substructure {
                parse(dictionary: dictionary, parentKind: kind)
            }
        }

        let dict = structureDictionary
        for dictionary in dict.substructure {
            parse(dictionary: dictionary, parentKind: nil)
        }

        return results
    }
}
