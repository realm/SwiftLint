import Foundation
import SourceKittenFramework

public struct RedundantVoidReturnRule: ASTRule, ConfigurationProviderRule, CorrectableRule, AutomaticTestableRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "redundant_void_return",
        name: "Redundant Void Return",
        description: "Returning Void in a function declaration is redundant.",
        kind: .idiomatic,
        nonTriggeringExamples: [
            "func foo() {}\n",
            "func foo() -> Int {}\n",
            "func foo() -> Int -> Void {}\n",
            "func foo() -> VoidResponse\n",
            "let foo: Int -> Void\n",
            "func foo() -> Int -> () {}\n",
            "let foo: Int -> ()\n",
            "func foo() -> ()?\n",
            "func foo() -> ()!\n",
            "func foo() -> Void?\n",
            "func foo() -> Void!\n"
        ],
        triggeringExamples: [
            "func foo()↓ -> Void {}\n",
            """
            protocol Foo {
              func foo()↓ -> Void
            }
            """,
            "func foo()↓ -> () {}\n",
            """
            protocol Foo {
              func foo()↓ -> ()
            }
            """
        ],
        corrections: [
            "func foo()↓ -> Void {}\n": "func foo() {}\n",
            "protocol Foo {\n func foo()↓ -> Void\n}\n": "protocol Foo {\n func foo()\n}\n",
            "func foo()↓ -> () {}\n": "func foo() {}\n",
            "protocol Foo {\n func foo()↓ -> ()\n}\n": "protocol Foo {\n func foo()\n}\n",
            "protocol Foo {\n    #if true\n    func foo()↓ -> Void\n    #endif\n}\n":
            "protocol Foo {\n    #if true\n    func foo()\n    #endif\n}\n"
        ]
    )

    private let pattern = "\\s*->\\s*(?:Void\\b|\\(\\s*\\))(?![?!])"

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
        guard SwiftDeclarationKind.functionKinds.contains(kind),
            let nameOffset = dictionary.nameOffset,
            let nameLength = dictionary.nameLength,
            let length = dictionary.length,
            let offset = dictionary.offset,
            case let start = nameOffset + nameLength,
            case let end = dictionary.bodyOffset ?? offset + length,
            case let contents = file.contents.bridge(),
            let range = contents.byteRangeToNSRange(start: start, length: end - start),
            file.match(pattern: "->", excludingSyntaxKinds: excludingKinds, range: range).count == 1,
            let match = file.match(pattern: pattern, excludingSyntaxKinds: excludingKinds, range: range).first else {
                return []
        }

        return [match]
    }

    private let excludingKinds = SyntaxKind.allKinds.subtracting([.typeidentifier])

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
}
