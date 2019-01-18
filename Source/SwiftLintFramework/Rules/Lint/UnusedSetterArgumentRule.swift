import Foundation
import SourceKittenFramework

public struct UnusedSetterArgumentRule: ConfigurationProviderRule, AutomaticTestableRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "unused_setter_argument",
        name: "Unused Setter Argument",
        description: "Setter argument is not used.",
        kind: .lint,
        nonTriggeringExamples: [
            """
            var aValue: String {
                get {
                    return Persister.shared.aValue
                }
                set {
                    Perister.shared.aValue = newValue
                }
            }
            """,
            """
            var aValue: String {
                set {
                    Perister.shared.aValue = newValue
                }
                get {
                    return Persister.shared.aValue
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
                    Perister.shared.aValue = aValue
                }
            }
            """,
            """
            var aValue: String {
                ↓set {
                    Perister.shared.aValue = aValue
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
                    Perister.shared.aValue = aValue
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
                    Perister.shared.aValue = aValue
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

            let propertyEndOffset = bodyOffset + bodyLength
            let setterByteRange: NSRange
            if setToken.offset > getToken.offset { // get {} set {}
                setterByteRange = NSRange(location: setToken.offset,
                                          length: propertyEndOffset - setToken.offset)
            } else { // set {} get {}
                setterByteRange = NSRange(location: setToken.offset,
                                          length: propertyEndOffset - setToken.offset)
            }

            guard let setterRange = contents.byteRangeToNSRange(start: setterByteRange.location,
                                                                length: setterByteRange.length) else {
                return nil
            }

            guard file.match(pattern: "\\bnewValue\\b", with: [.identifier], range: setterRange).isEmpty else {
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
