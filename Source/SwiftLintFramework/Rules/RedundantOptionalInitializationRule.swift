import Foundation
import SourceKittenFramework

public struct RedundantOptionalInitializationRule: ASTRule, CorrectableRule, ConfigurationProviderRule,
                                                   AutomaticTestableRule {

    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "redundant_optional_initialization",
        name: "Redundant Optional Initialization",
        description: "Initializing an optional variable with nil is redundant.",
        kind: .idiomatic,
        nonTriggeringExamples: [
            "var myVar: Int?\n",
            "let myVar: Int? = nil\n",
            "var myVar: Int? = 0\n",
            "func foo(bar: Int? = 0) { }\n",
            "var myVar: Optional<Int>\n",
            "let myVar: Optional<Int> = nil\n",
            "var myVar: Optional<Int> = 0\n",
            // properties with body should be ignored
            "var foo: Int? {\n" +
            "   if bar != nil { }\n" +
            "   return 0\n" +
            "}\n",
            // properties with a closure call
            "var foo: Int? = {\n" +
            "   if bar != nil { }\n" +
            "   return 0\n" +
            "}()\n",
            // lazy variables need to be initialized
            "lazy var test: Int? = nil",
            // local variables
            "func funcName() {\n    var myVar: String?\n}",
            "func funcName() {\n    let myVar: String? = nil\n}"
        ],
        triggeringExamples: triggeringExamples,
        corrections: corrections
    )

    private static let triggeringExamples: [String] = {
        let commonExamples = [
            "var myVar: Int?↓ = nil\n",
            "var myVar: Optional<Int>↓ = nil\n",
            "var myVar: Int?↓=nil\n",
            "var myVar: Optional<Int>↓=nil\n"
        ]

        guard SwiftVersion.current >= .fourDotOne else {
            return commonExamples
        }

        return commonExamples + [
            "func funcName() {\n    var myVar: String?↓ = nil\n}"
        ]
    }()

    private static let corrections: [String: String] = {
        var corrections = [
            "var myVar: Int?↓ = nil\n": "var myVar: Int?\n",
            "var myVar: Optional<Int>↓ = nil\n": "var myVar: Optional<Int>\n",
            "var myVar: Int?↓=nil\n": "var myVar: Int?\n",
            "var myVar: Optional<Int>↓=nil\n": "var myVar: Optional<Int>\n",
            "class C {\n#if true\nvar myVar: Int?↓ = nil\n#endif\n}":
            "class C {\n#if true\nvar myVar: Int?\n#endif\n}"
        ]

        guard SwiftVersion.current >= .fourDotOne else {
            return corrections
        }

        corrections["func foo() {\n    var myVar: String?↓ = nil\n}"] = "func foo() {\n    var myVar: String?\n}"
        return corrections
    }()

    private let pattern = "\\s*=\\s*nil\\b"

    public func validate(file: File, kind: SwiftDeclarationKind,
                         dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        return violationRanges(in: file, kind: kind, dictionary: dictionary).map {
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severity,
                           location: Location(file: file, characterOffset: $0.location))
        }
    }

    private func violationRanges(in file: File, kind: SwiftDeclarationKind,
                                 dictionary: [String: SourceKitRepresentable]) -> [NSRange] {
        guard SwiftDeclarationKind.variableKinds.contains(kind),
            let type = dictionary.typeName,
            typeIsOptional(type),
            !dictionary.enclosedSwiftAttributes.contains(.lazy),
            dictionary.isMutableVariable(file: file),
            let range = range(for: dictionary, file: file),
            let match = file.match(pattern: pattern, with: [.keyword], range: range).first,
            match.location == range.location + range.length - match.length else {
                return []
        }

        return [match]
    }

    private func range(for dictionary: [String: SourceKitRepresentable], file: File) -> NSRange? {
        guard let offset = dictionary.offset,
            let length = dictionary.length else {
                return nil
        }

        let contents = file.contents.bridge()
        if let bodyOffset = dictionary.bodyOffset {
            return contents.byteRangeToNSRange(start: offset, length: bodyOffset - offset)
        } else {
            return contents.byteRangeToNSRange(start: offset, length: length)
        }
    }

    private func violationRanges(in file: File, dictionary: [String: SourceKitRepresentable]) -> [NSRange] {
        let ranges = dictionary.substructure.flatMap { subDict -> [NSRange] in
            var ranges = violationRanges(in: file, dictionary: subDict)
            if let kind = subDict.kind.flatMap(SwiftDeclarationKind.init(rawValue:)) {
                ranges += violationRanges(in: file, kind: kind, dictionary: subDict)
            }

            return ranges
        }

        return ranges.unique
    }

    private func violationRanges(in file: File) -> [NSRange] {
        return violationRanges(in: file, dictionary: file.structure.dictionary).sorted { lhs, rhs in
            lhs.location < rhs.location
        }
    }

    public func correct(file: File) -> [Correction] {
        let violatingRanges = file.ruleEnabled(violatingRanges: violationRanges(in: file), for: self)
        var correctedContents = file.contents
        var adjustedLocations = [Int]()

        for violatingRange in violatingRanges.reversed() {
            if let indexRange = correctedContents.nsrangeToIndexRange(violatingRange) {
                correctedContents = correctedContents.replacingCharacters(in: indexRange, with: "")
                adjustedLocations.insert(violatingRange.location, at: 0)
            }
        }

        file.write(correctedContents)

        return adjustedLocations.map {
            Correction(ruleDescription: type(of: self).description,
                       location: Location(file: file, characterOffset: $0))
        }
    }

    private func typeIsOptional(_ type: String) -> Bool {
        return type.hasSuffix("?") || type.hasPrefix("Optional<")
    }

}

extension Dictionary where Key == String, Value == SourceKitRepresentable {
    fileprivate func isMutableVariable(file: File) -> Bool {
        return setterAccessibility != nil || (isLocal && isVariable(file: file))
    }

    private var isLocal: Bool {
        return accessibility == nil && setterAccessibility == nil
    }

    private func isVariable(file: File) -> Bool {
        guard let start = offset, let length = length,
            case let contents = file.contents.bridge(),
            let range = contents.byteRangeToNSRange(start: start, length: length),
            !file.match(pattern: "\\Avar\\b", with: [.keyword], range: range).isEmpty else {
                return false
        }

        return true
    }
}
