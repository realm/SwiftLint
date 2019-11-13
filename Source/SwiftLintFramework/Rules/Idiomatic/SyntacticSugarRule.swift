import Foundation
import SourceKittenFramework

public struct SyntacticSugarRule: SubstitutionCorrectableRule, ConfigurationProviderRule, AutomaticTestableRule {
    public var configuration = SeverityConfiguration(.warning)

    private var pattern: String {
        let types = ["Optional", "ImplicitlyUnwrappedOptional", "Array", "Dictionary"]
        let negativeLookBehind = "(?:(?<!\\.)|Swift\\.)"
        return negativeLookBehind + "\\b(" + types.joined(separator: "|") + ")\\s*<.*?>"
    }

    public init() {}

    public static let description = RuleDescription(
        identifier: "syntactic_sugar",
        name: "Syntactic Sugar",
        description: "Shorthand syntactic sugar should be used, i.e. [Int] instead of Array<Int>.",
        kind: .idiomatic,
        nonTriggeringExamples: [
            "let x: [Int]",
            "let x: [Int: String]",
            "let x: Int?",
            "func x(a: [Int], b: Int) -> [Int: Any]",
            "let x: Int!",
            """
            extension Array {
              func x() { }
            }
            """,
            """
            extension Dictionary {
              func x() { }
            }
            """,
            "let x: CustomArray<String>",
            "var currentIndex: Array<OnboardingPage>.Index?",
            "func x(a: [Int], b: Int) -> Array<Int>.Index",
            "unsafeBitCast(nonOptionalT, to: Optional<T>.self)",
            "type is Optional<String>.Type",
            "let x: Foo.Optional<String>"
        ],
        triggeringExamples: [
            "let x: ↓Array<String>",
            "let x: ↓Dictionary<Int, String>",
            "let x: ↓Optional<Int>",
            "let x: ↓ImplicitlyUnwrappedOptional<Int>",
            "func x(a: ↓Array<Int>, b: Int) -> [Int: Any]",
            "func x(a: [Int], b: Int) -> ↓Dictionary<Int, String>",
            "func x(a: ↓Array<Int>, b: Int) -> ↓Dictionary<Int, String>",
            "let x = ↓Array<String>.array(of: object)",
            "let x: ↓Swift.Optional<String>"
        ],
        corrections: [
            "let x: Array<String>": "let x: [String]",
            "let x: Array< String >": "let x: [ String ]",
            "let x: Dictionary<Int, String>": "let x: [Int: String]",
            "let x: Dictionary<Int , String>": "let x: [Int : String]",
            "let x: Optional<Int>": "let x: Int?",
            "let x: Optional< Int >": "let x: Int?",
            "let x: ImplicitlyUnwrappedOptional<Int>": "let x: Int!",
            "let x: ImplicitlyUnwrappedOptional< Int >": "let x: Int!",
            "func x(a: Array<Int>, b: Int) -> [Int: Any]": "func x(a: [Int], b: Int) -> [Int: Any]",
            "func x(a: [Int], b: Int) -> Dictionary<Int, String>": "func x(a: [Int], b: Int) -> [Int: String]",
            "let x = Array<String>.array(of: object)": "let x = [String].array(of: object)",
            "let x: Swift.Optional<String>": "let x: String?"
        ]
    )

    public func validate(file: SwiftLintFile) -> [StyleViolation] {
        let contents = file.linesContainer
        return violationResults(in: file).map {
            let typeString = contents.substring(with: $0.range(at: 1))
            return StyleViolation(ruleDescription: type(of: self).description,
                                  severity: configuration.severity,
                                  location: Location(file: file, characterOffset: $0.range.location),
                                  reason: message(for: typeString))
        }
    }

    public func violationRanges(in file: SwiftLintFile) -> [NSRange] {
        return violationResults(in: file).map { $0.range }
    }

    public func substitution(for violationRange: NSRange, in file: SwiftLintFile) -> (NSRange, String) {
        let contents = file.linesContainer
        let declaration = contents.substring(with: violationRange)
        let originalRange = NSRange(location: 0, length: declaration.count)
        var substitutionResult = declaration
        guard
            let typeRange = regex(pattern).firstMatch(in: declaration, options: [], range: originalRange)?.range(at: 1)
            else {
                return (violationRange, substitutionResult)
        }

        let containerType = declaration.bridge().substring(with: typeRange)

        switch containerType {
        case "Optional":
            let genericType = declaration.bridge().substring(from: typeRange.upperBound)
                .replacingOccurrences(of: " ", with: "")
                .replacingOccurrences(of: "<", with: "")
                .replacingOccurrences(of: ">", with: "")
            substitutionResult = "\(genericType)?"
        case "ImplicitlyUnwrappedOptional":
            let genericType = declaration.bridge().substring(from: typeRange.upperBound)
                .replacingOccurrences(of: " ", with: "")
                .replacingOccurrences(of: "<", with: "")
                .replacingOccurrences(of: ">", with: "")
            substitutionResult = "\(genericType)!"
        case "Array":
            substitutionResult = declaration.bridge().substring(from: typeRange.upperBound)
                .replacingOccurrences(of: "<", with: "[")
                .replacingOccurrences(of: ">", with: "]")
        case "Dictionary":
            substitutionResult = declaration.bridge().substring(from: typeRange.upperBound)
                .replacingOccurrences(of: "<", with: "[")
                .replacingOccurrences(of: ">", with: "]")
                .replacingOccurrences(of: ",", with: ":")
        default:
            break
        }

        return (violationRange, substitutionResult)
    }

    private func violationResults(in file: SwiftLintFile) -> [NSTextCheckingResult] {
        let excludingKinds = SyntaxKind.commentAndStringKinds
        let contents = file.linesContainer
        let range = NSRange(location: 0, length: contents.length)

        return regex(pattern).matches(in: file.contents, options: [], range: range).compactMap { result in
            let range = result.range
            guard let byteRange = contents.NSRangeToByteRange(start: range.location, length: range.length) else {
                return nil
            }

            let kinds = file.syntaxMap.kinds(inByteRange: byteRange)
            guard excludingKinds.isDisjoint(with: kinds),
                isValidViolation(range: range, file: file) else {
                    return nil
            }

            return result
        }
    }

    private func isValidViolation(range: NSRange, file: SwiftLintFile) -> Bool {
        let contents = file.linesContainer

        // avoid triggering when referring to an associatedtype
        let start = range.location + range.length
        let restOfFileRange = NSRange(location: start, length: contents.length - start)
        if regex("\\s*\\.").firstMatch(in: file.contents, options: [],
                                       range: restOfFileRange)?.range.location == start {
            guard let byteOffset = contents.NSRangeToByteRange(start: range.location,
                                                               length: range.length)?.location else {
                return false
            }

            let kinds = file.structureDictionary.structures(forByteOffset: byteOffset).compactMap { $0.expressionKind }
            guard kinds.contains(.call) else {
                return false
            }

            if let (range, kinds) = file.match(pattern: "\\s*\\.(?:self|Type)", range: restOfFileRange).first,
                range.location == start, kinds == [.keyword] || kinds == [.identifier] {
                return false
            }
        }

        return true
    }

    private func message(for originalType: String) -> String {
        let typeString: String
        let sugaredType: String

        switch originalType {
        case "Optional":
            typeString = "Optional<Int>"
            sugaredType = "Int?"
        case "ImplicitlyUnwrappedOptional":
            typeString = "ImplicitlyUnwrappedOptional<Int>"
            sugaredType = "Int!"
        case "Array":
            typeString = "Array<Int>"
            sugaredType = "[Int]"
        case "Dictionary":
            typeString = "Dictionary<String, Int>"
            sugaredType = "[String: Int]"
        default:
            return type(of: self).description.description
        }

        return "Shorthand syntactic sugar should be used, i.e. \(sugaredType) instead of \(typeString)."
    }
}
