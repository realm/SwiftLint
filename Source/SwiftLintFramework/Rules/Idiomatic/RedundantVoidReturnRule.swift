import Foundation
import SourceKittenFramework

public struct RedundantVoidReturnRule: ConfigurationProviderRule, SubstitutionCorrectableASTRule,
                                       AutomaticTestableRule {
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
    private let excludingKinds = SyntaxKind.allKinds.subtracting([.typeidentifier])

    public func validate(file: File, kind: SwiftDeclarationKind,
                         dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        return violationRanges(in: file, kind: kind, dictionary: dictionary).map {
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severity,
                           location: Location(file: file, characterOffset: $0.location))
        }
    }

    public func violationRanges(in file: File, kind: SwiftDeclarationKind,
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

    public func substitution(for violationRange: NSRange, in file: File) -> (NSRange, String) {
        return (violationRange, "")
    }
}
