import Foundation
import SourceKittenFramework

public struct WeakComputedProperyRule: ASTRule, CorrectableRule, ConfigurationProviderRule, AutomaticTestableRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "weak_computed_property",
        name: "Weak Computed Property",
        description: "Adding weak to a computed property has no effect.",
        kind: .lint,
        minSwiftVersion: .fourDotOne,
        nonTriggeringExamples: [
            "    weak var delegate: SomeProtocol?",
            "    var delegate: SomeProtocol?",
            """
                weak var delegate: SomeProtocol? {
                    didSet {
                        update(with: delegate)
                    }
                }
            """,
            """
                weak var delegate: SomeProtocol? {
                    willSet {
                        update(with: delegate)
                    }
                }
            """
        ].map(wrapExample),
        triggeringExamples: [
            "    weak var delegate: SomeProtocol? { return bar() }",
            """
                private weak var _delegate: SomeProtocol?

                ↓weak var delegate: SomeProtocol? {
                    get { return _delegate }
                    set { _delegate = newValue }
                }
            """
        ].map(wrapExample),
        corrections: [
            wrapExample("    ↓weak var delegate: SomeProtocol? { return bar() }"):
                wrapExample("    var delegate: SomeProtocol? { return bar() }"),
            wrapExample("""
                            private weak var _delegate: SomeProtocol?

                            ↓weak var delegate: SomeProtocol? {
                                get { return _delegate }
                                set { _delegate = newValue }
                            }
                        """):
                wrapExample("""
                                private weak var _delegate: SomeProtocol?

                                var delegate: SomeProtocol? {
                                    get { return _delegate }
                                    set { _delegate = newValue }
                                }
                            """)
        ]
    )

    // MARK: - ASTRule

    public func validate(file: File,
                         kind: SwiftDeclarationKind,
                         dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        return violationRanges(in: file, kind: kind, dictionary: dictionary).map {
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severity,
                           location: Location(file: file, characterOffset: $0.location))
        }
    }

    // MARK: - CorrectableRule

    public func correct(file: File) -> [Correction] {
        let violatingRanges = file.ruleEnabled(violatingRanges: violationRanges(in: file), for: self)
        guard !violatingRanges.isEmpty else { return [] }

        let description = type(of: self).description
        var corrections = [Correction]()
        var contents = file.contents
        for range in violatingRanges {
            var rangeToRemove = range
            let contentsNSString = contents.bridge()
            if let byteRange = contentsNSString.NSRangeToByteRange(start: range.location, length: range.length),
                let nextToken = file.syntaxMap.tokens.first(where: { $0.offset > byteRange.location }),
                let nextTokenLocation = contentsNSString.byteRangeToNSRange(start: nextToken.offset, length: 0) {
                rangeToRemove.length = nextTokenLocation.location - range.location
            }

            contents = contentsNSString.replacingCharacters(in: rangeToRemove, with: "")
            let location = Location(file: file, characterOffset: range.location)
            corrections.append(Correction(ruleDescription: description, location: location))
        }

        file.write(contents)
        return corrections
    }

    // MARK: - Private

    private let allowedKinds = SwiftDeclarationKind.variableKinds.subtracting([.varParameter])

    private func violationRanges(in file: File) -> [NSRange] {
        return violationRanges(in: file, dictionary: file.structure.dictionary).sorted {
            $0.location > $1.location
        }
    }

    private func violationRanges(in file: File,
                                 dictionary: [String: SourceKitRepresentable]) -> [NSRange] {
        let ranges = dictionary.substructure.flatMap { subDict -> [NSRange] in
            var ranges = violationRanges(in: file, dictionary: subDict)

            if let kind = subDict.kind.flatMap(SwiftDeclarationKind.init(rawValue:)) {
                ranges += violationRanges(in: file, kind: kind, dictionary: subDict)
            }

            return ranges
        }

        return ranges.unique
    }

    private func violationRanges(in file: File,
                                 kind: SwiftDeclarationKind,
                                 dictionary: [String: SourceKitRepresentable]) -> [NSRange] {
        guard allowedKinds.contains(kind),
            let bodyOffset = dictionary.bodyOffset,
            let bodyLength = dictionary.bodyLength, bodyLength > 0,
            let weakAttribute = dictionary.swiftAttributes.first(where: { $0.isWeakAttribute }),
            let attributeOffset = weakAttribute.offset,
            let attributeLength = weakAttribute.length, attributeLength > 0,
            case let contents = file.contents.bridge(),
            let attributeRange = contents.byteRangeToNSRange(start: attributeOffset, length: attributeLength),
            let bodyRange = contents.byteRangeToNSRange(start: bodyOffset, length: bodyLength),
            !containsObserverToken(in: bodyRange, file: file, propertyStructure: dictionary) else {
                return []
        }

        return [attributeRange]
    }

    private func containsObserverToken(in range: NSRange, file: File,
                                       propertyStructure: [String: SourceKitRepresentable]) -> Bool {
        let tokens = file.rangesAndTokens(matching: "\\b(?:didSet|willSet)\\b", range: range).keywordTokens()
        return tokens.contains(where: { token -> Bool in
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

private extension Dictionary where Key == String, Value == SourceKitRepresentable {
    var isWeakAttribute: Bool {
        return attribute.flatMap(SwiftDeclarationAttributeKind.init) == .weak
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

private func wrapExample(_ text: String) -> String {
    return """
    class Foo {
    \(text)
    }
    """
}
