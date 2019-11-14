import Foundation
import SourceKittenFramework

public struct StrongIBOutletRule: ConfigurationProviderRule, ASTRule, SubstitutionCorrectableASTRule, OptInRule,
    AutomaticTestableRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "strong_iboutlet",
        name: "Strong IBOutlet",
        description: "@IBOutlets shouldn't be declared as weak.",
        kind: .lint,
        nonTriggeringExamples: [
            "@IBOutlet var label: UILabel?",
            "weak var label: UILabel?"
        ].map { wrapExample($0) },
        triggeringExamples: [
            "@IBOutlet ↓weak var label: UILabel?",
            "@IBOutlet ↓unowned var label: UILabel!",
            "@IBOutlet ↓weak var textField: UITextField?"
        ].map { wrapExample($0) },
        corrections: [
            "@IBOutlet ↓weak var label: UILabel?": "@IBOutlet var label: UILabel?",
            "@IBOutlet ↓unowned var label: UILabel!": "@IBOutlet var label: UILabel!",
            "@IBOutlet ↓weak var textField: UITextField?": "@IBOutlet var textField: UITextField?"
        ].reduce(into: [Example: Example]()) { $0[wrapExample($1.key)] = wrapExample($1.value) }
    )

    public func validate(file: SwiftLintFile, kind: SwiftDeclarationKind,
                         dictionary: SourceKittenDictionary) -> [StyleViolation] {
        return violationRanges(in: file, kind: kind, dictionary: dictionary).map {
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severity,
                           location: Location(file: file, characterOffset: $0.location))
        }
    }

    public func violationRanges(in file: SwiftLintFile, kind: SwiftDeclarationKind,
                                dictionary: SourceKittenDictionary) -> [NSRange] {
        guard kind == .varInstance && dictionary.enclosedSwiftAttributes.contains(.iboutlet),
            let weakAttribute = dictionary.swiftAttributes.first(where: {
                $0.attribute == SwiftDeclarationAttributeKind.weak.rawValue
            }),
            let byteRange = weakAttribute.byteRange,
            let range = file.stringView.byteRangeToNSRange(byteRange)
            else { return [] }
        return [range]
    }

    public func substitution(for violationRange: NSRange, in file: SwiftLintFile) -> (NSRange, String)? {
        return (NSRange(location: violationRange.location, length: violationRange.length + 1), "")
    }
}

private func wrapExample(_ text: String, file: StaticString = #file, line: UInt = #line) -> Example {
    return Example("""
    class ViewController: UIViewController {
        \(text)
    }
    """, file: file, line: line)
}
