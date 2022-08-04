import Foundation
import SourceKittenFramework

public struct StrongIBOutletRule: ConfigurationProviderRule, ASTRule, SubstitutionCorrectableASTRule, OptInRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "strong_iboutlet",
        name: "Strong IBOutlet",
        description: "@IBOutlets shouldn't be declared as weak.",
        kind: .lint,
        nonTriggeringExamples: [
            wrapExample("@IBOutlet var label: UILabel?"),
            wrapExample("weak var label: UILabel?")
        ],
        triggeringExamples: [
            wrapExample("@IBOutlet ↓weak var label: UILabel?"),
            wrapExample("@IBOutlet ↓unowned var label: UILabel!"),
            wrapExample("@IBOutlet ↓weak var textField: UITextField?")
        ],
        corrections: [
            wrapExample("@IBOutlet ↓weak var label: UILabel?"):
                wrapExample("@IBOutlet var label: UILabel?"),
            wrapExample("@IBOutlet ↓unowned var label: UILabel!"):
                wrapExample("@IBOutlet var label: UILabel!"),
            wrapExample("@IBOutlet ↓weak var textField: UITextField?"):
                wrapExample("@IBOutlet var textField: UITextField?")
        ]
    )

    public func validate(file: SwiftLintFile, kind: SwiftDeclarationKind,
                         dictionary: SourceKittenDictionary) -> [StyleViolation] {
        return violationRanges(in: file, kind: kind, dictionary: dictionary).map {
            StyleViolation(ruleDescription: Self.description,
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
