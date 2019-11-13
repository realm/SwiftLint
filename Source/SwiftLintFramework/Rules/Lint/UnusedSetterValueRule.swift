import Foundation
import SourceKittenFramework

public struct UnusedSetterValueRule: ConfigurationProviderRule, AutomaticTestableRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "unused_setter_value",
        name: "Unused Setter Value",
        description: "Setter value is not used.",
        kind: .lint,
        nonTriggeringExamples: [
            """
            var aValue: String {
                get {
                    return Persister.shared.aValue
                }
                set {
                    Persister.shared.aValue = newValue
                }
            }
            """,
            """
            var aValue: String {
                set {
                    Persister.shared.aValue = newValue
                }
                get {
                    return Persister.shared.aValue
                }
            }
            """,
            """
            var aValue: String {
                get {
                    return Persister.shared.aValue
                }
                set(value) {
                    Persister.shared.aValue = value
                }
            }
            """
        ],
        triggeringExamples: [
            """
            var aValue: String {
                get {
                    return Persister.shared.aValue
                }
                ↓set {
                    Persister.shared.aValue = aValue
                }
            }
            """,
            """
            var aValue: String {
                ↓set {
                    Persister.shared.aValue = aValue
                }
                get {
                    return Persister.shared.aValue
                }
            }
            """,
            """
            var aValue: String {
                get {
                    return Persister.shared.aValue
                }
                ↓set {
                    Persister.shared.aValue = aValue
                }
            }
            """,
            """
            var aValue: String {
                get {
                    let newValue = Persister.shared.aValue
                    return newValue
                }
                ↓set {
                    Persister.shared.aValue = aValue
                }
            }
            """,
            """
            var aValue: String {
                get {
                    return Persister.shared.aValue
                }
                ↓set(value) {
                    Persister.shared.aValue = aValue
                }
            }
            """
        ]
    )

    public func validate(file: SwiftLintFile) -> [StyleViolation] {
        let setTokens = file.rangesAndTokens(matching: "\\bset\\b").keywordTokens()

        let violatingLocations = setTokens.compactMap { setToken -> Int? in
            // the last element is the deepest structure
            guard let dict = declarations(forByteOffset: setToken.offset,
                                          structureDictionary: file.structureDictionary).last,
                let bodyOffset = dict.bodyOffset, let bodyLength = dict.bodyLength,
                case let contents = file.linesContainer,
                let propertyRange = contents.byteRangeToNSRange(start: bodyOffset, length: bodyLength),
                let getToken = findGetToken(in: propertyRange, file: file, propertyStructure: dict) else {
                    return nil
            }

            let argument = findNamedArgument(after: setToken, file: file)

            let propertyEndOffset = bodyOffset + bodyLength
            let setterByteRange: NSRange
            if setToken.offset > getToken.offset { // get {} set {}
                let startOfBody: Int
                if let argumentToken = argument?.token {
                    startOfBody = argumentToken.offset + argumentToken.length
                } else {
                    startOfBody = setToken.offset
                }
                setterByteRange = NSRange(location: startOfBody,
                                          length: propertyEndOffset - startOfBody)
            } else { // set {} get {}
                let startOfBody: Int
                if let argumentToken = argument?.token {
                    startOfBody = argumentToken.offset + argumentToken.length
                } else {
                    startOfBody = setToken.offset
                }
                setterByteRange = NSRange(location: startOfBody,
                                          length: getToken.offset - startOfBody)
            }

            guard let setterRange = contents.byteRangeToNSRange(start: setterByteRange.location,
                                                                length: setterByteRange.length) else {
                return nil
            }

            let argumentName = argument?.name ?? "newValue"
            guard file.match(pattern: "\\b\(argumentName)\\b", with: [.identifier], range: setterRange).isEmpty else {
                return nil
            }

            return setToken.offset
        }

        return violatingLocations.map { offset in
            return StyleViolation(ruleDescription: type(of: self).description,
                                  severity: configuration.severity,
                                  location: Location(file: file, byteOffset: offset))
        }
    }

    private func findNamedArgument(after token: SwiftLintSyntaxToken,
                                   file: SwiftLintFile) -> (name: String, token: SwiftLintSyntaxToken)? {
        guard let firstToken = file.syntaxMap.tokens.first(where: { $0.offset > token.offset }),
            firstToken.kind == .identifier else {
                return nil
        }

        let declaration = file.structureDictionary.structures(forByteOffset: firstToken.offset)
            .first(where: { $0.offset == firstToken.offset && $0.length == firstToken.length })

        guard let name = declaration?.name else {
            return nil
        }

        return (name, firstToken)
    }

    private func findGetToken(in range: NSRange, file: SwiftLintFile,
                              propertyStructure: SourceKittenDictionary) -> SwiftLintSyntaxToken? {
        let getTokens = file.rangesAndTokens(matching: "\\bget\\b", range: range).keywordTokens()
        return getTokens.first(where: { token -> Bool in
            // the last element is the deepest structure
            guard let dict = declarations(forByteOffset: token.offset,
                                          structureDictionary: file.structureDictionary).last,
                propertyStructure.value.isEqualTo(dict.value) else {
                    return false
            }

            return true
        })
    }

    private func declarations(forByteOffset byteOffset: Int,
                              structureDictionary: SourceKittenDictionary) -> [SourceKittenDictionary] {
        var results = [SourceKittenDictionary]()
        let allowedKinds = SwiftDeclarationKind.variableKinds.subtracting([.varParameter])

        func parse(dictionary: SourceKittenDictionary, parentKind: SwiftDeclarationKind?) {
            // Only accepts declarations which contains a body and contains the
            // searched byteOffset
            guard let kind = dictionary.declarationKind,
                let bodyOffset = dictionary.bodyOffset,
                let bodyLength = dictionary.bodyLength,
                case let byteRange = NSRange(location: bodyOffset, length: bodyLength),
                NSLocationInRange(byteOffset, byteRange) else {
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

private extension Array where Element == (NSRange, [SwiftLintSyntaxToken]) {
    func keywordTokens() -> [SwiftLintSyntaxToken] {
        return compactMap { _, tokens in
            guard let token = tokens.last, token.kind == .keyword else {
                return nil
            }
            return token
        }
    }
}
