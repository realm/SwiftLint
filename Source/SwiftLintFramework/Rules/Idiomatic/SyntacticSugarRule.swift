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
            Example("let x: [Int]"),
            Example("let x: [Int: String]"),
            Example("let x: Int?"),
            Example("func x(a: [Int], b: Int) -> [Int: Any]"),
            Example("let x: Int!"),
            Example("""
            extension Array {
              func x() { }
            }
            """),
            Example("""
            extension Dictionary {
              func x() { }
            }
            """),
            Example("let x: CustomArray<String>"),
            Example("var currentIndex: Array<OnboardingPage>.Index?"),
            Example("func x(a: [Int], b: Int) -> Array<Int>.Index"),
            Example("unsafeBitCast(nonOptionalT, to: Optional<T>.self)"),
            Example("type is Optional<String>.Type"),
            Example("let x: Foo.Optional<String>")
        ],
        triggeringExamples: [
            Example("let x: ↓Array<String>"),
            Example("let x: ↓Dictionary<Int, String>"),
            Example("let x: ↓Optional<Int>"),
            Example("let x: ↓ImplicitlyUnwrappedOptional<Int>"),
            Example("func x(a: ↓Array<Int>, b: Int) -> [Int: Any]"),
            Example("func x(a: [Int], b: Int) -> ↓Dictionary<Int, String>"),
            Example("func x(a: ↓Array<Int>, b: Int) -> ↓Dictionary<Int, String>"),
            Example("let x = ↓Array<String>.array(of: object)"),
            Example("let x: ↓Swift.Optional<String>")
        ],
        corrections: [
            Example("let x: Array<String>"): Example("let x: [String]"),
            Example("let x: Array< String >"): Example("let x: [ String ]"),
            Example("let x: Dictionary<Int, String>"): Example("let x: [Int: String]"),
            Example("let x: Dictionary<Int , String>"): Example("let x: [Int : String]"),
            Example("let x: Optional<Int>"): Example("let x: Int?"),
            Example("let x: Optional< Int >"): Example("let x: Int?"),
            Example("let x: ImplicitlyUnwrappedOptional<Int>"): Example("let x: Int!"),
            Example("let x: ImplicitlyUnwrappedOptional< Int >"): Example("let x: Int!"),
            Example("func x(a: Array<Int>, b: Int) -> [Int: Any]"): Example("func x(a: [Int], b: Int) -> [Int: Any]"),
            Example("func x(a: [Int], b: Int) -> Dictionary<Int, String>"):
                Example("func x(a: [Int], b: Int) -> [Int: String]"),
            Example("let x = Array<String>.array(of: object)"): Example("let x = [String].array(of: object)"),
            Example("let x: Swift.Optional<String>"): Example("let x: String?")
        ]
    )

    public func validate(file: SwiftLintFile) -> [StyleViolation] {
        let contents = file.stringView
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

    public func substitution(for violationRange: NSRange, in file: SwiftLintFile) -> (NSRange, String)? {
        let contents = file.stringView
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
        let contents = file.stringView
        return regex(pattern).matches(in: contents).compactMap { result in
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
        let contents = file.stringView

        // avoid triggering when referring to an associatedtype
        let start = range.location + range.length
        let restOfFileRange = NSRange(location: start, length: contents.nsString.length - start)
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
