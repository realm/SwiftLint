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

    public func validate(file: File) -> [StyleViolation] {
        let setTokens = file.rangesAndTokens(matching: "\\bset\\b").keywordTokens()

        let violatingLocations = setTokens.compactMap { setToken -> Int? in
            // the last element is the deepest structure
            guard let dict = declarations(forByteOffset: setToken.offset, structure: file.structure).last,
                let bodyOffset = dict.bodyOffset, let bodyLength = dict.bodyLength,
                case let contents = file.contents.bridge(),
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

    private func findNamedArgument(after token: SyntaxToken,
                                   file: File) -> (name: String, token: SyntaxToken)? {
        guard let firstToken = file.syntaxMap.tokens.first(where: { $0.offset > token.offset }),
            SyntaxKind(rawValue: firstToken.type) == .identifier else {
                return nil
        }

        let declaration = file.structure.structures(forByteOffset: firstToken.offset)
            .first(where: { $0.offset == firstToken.offset && $0.length == firstToken.length })

        guard let name = declaration?.name else {
            return nil
        }

        return (name, firstToken)
    }

    private func findGetToken(in range: NSRange, file: File,
                              propertyStructure: [String: SourceKitRepresentable]) -> SyntaxToken? {
        let getTokens = file.rangesAndTokens(matching: "\\bget\\b", range: range).keywordTokens()
        return getTokens.first(where: { token -> Bool in
            // the last element is the deepest structure
            guard let dict = declarations(forByteOffset: token.offset, structure: file.structure).last,
                propertyStructure.isEqualTo(dict) else {
                    return false
            }

            return true
        })
    }

    private func declarations(forByteOffset byteOffset: Int,
                              structure: Structure) -> [[String: SourceKitRepresentable]] {
        var results = [[String: SourceKitRepresentable]]()
        let allowedKinds = SwiftDeclarationKind.variableKinds.subtracting([.varParameter])

        func parse(dictionary: [String: SourceKitRepresentable], parentKind: SwiftDeclarationKind?) {
            // Only accepts declarations which contains a body and contains the
            // searched byteOffset
            guard let kindString = dictionary.kind,
                let kind = SwiftDeclarationKind(rawValue: kindString),
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

        for dictionary in structure.dictionary.substructure {
            parse(dictionary: dictionary, parentKind: nil)
        }

        return results
    }
}

private extension Array where Element == (NSRange, [SyntaxToken]) {
    func keywordTokens() -> [SyntaxToken] {
        return compactMap { _, tokens in
            guard let token = tokens.last,
                SyntaxKind(rawValue: token.type) == .keyword else {
                    return nil
            }

            return token
        }
    }
}
