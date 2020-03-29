import Foundation
import SourceKittenFramework

public struct ComputedAccessorsOrderRule: ConfigurationProviderRule {
    public var configuration = ComputedAccessorsOrderRuleConfiguration()

    public init() {}

    public static let description = RuleDescription(
        identifier: "computed_accessors_order",
        name: "Computed Accessors Order",
        description: "Getter and setters in computed properties and subscripts should be in a consistent order.",
        kind: .style,
        minSwiftVersion: .fourDotOne,
        nonTriggeringExamples: ComputedAccessorsOrderRuleExamples.nonTriggeringExamples,
        triggeringExamples: ComputedAccessorsOrderRuleExamples.triggeringExamples
    )

    public func validate(file: SwiftLintFile) -> [StyleViolation] {
        let getTokens = findKeywordTokens(keyword: "get", file: file)

        let violatingLocations = getTokens.compactMap { getToken -> (ByteCount, SwiftDeclarationKind?)? in
            // the last element is the deepest structure
            guard let dict = declarations(forByteOffset: getToken.offset,
                                          structureDictionary: file.structureDictionary).last else {
                return nil
            }

            guard let range = dict.byteRange.map(file.stringView.byteRangeToNSRange) else {
                return nil
            }

            let setTokens = findKeywordTokens(keyword: "set", file: file, range: range)
            let setToken = setTokens.first { token in
                // the last element is the deepest structure
                guard let setDict = declarations(forByteOffset: token.offset,
                                                 structureDictionary: file.structureDictionary).last else {
                    return false
                }

                return setDict.offset == dict.offset
            }

            let tokensInOrder = [getToken, setToken].compactMap { $0?.offset }.sorted()
            let expectedOrder: [ByteCount]
            switch configuration.order {
            case .getSet:
                expectedOrder = [getToken, setToken].compactMap { $0?.offset }
            case .setGet:
                expectedOrder = [setToken, getToken].compactMap { $0?.offset }
            }

            guard tokensInOrder != expectedOrder else {
                return nil
            }

            let kind = dict.declarationKind
            return (tokensInOrder[0], kind)
        }

        return violatingLocations.map { offset, kind in
            let reason = kind.map { kind -> String in
                let kindString = kind == .functionSubscript ? "subscripts" : "properties"
                let orderString: String
                switch configuration.order {
                case .getSet:
                    orderString = "getter and then the setter"
                case .setGet:
                    orderString = "setter and then the getter"
                }
                return "Computed \(kindString) should declare first the \(orderString)."
            }

            return StyleViolation(ruleDescription: type(of: self).description,
                                  severity: configuration.severityConfiguration.severity,
                                  location: Location(file: file, byteOffset: offset),
                                  reason: reason)
        }
    }

    private func findKeywordTokens(keyword: String,
                                   file: SwiftLintFile,
                                   range: NSRange? = nil) -> [SwiftLintSyntaxToken] {
        let pattern = "\\b\(keyword)\\b"
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

private extension ComputedAccessorsOrderRule {
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
