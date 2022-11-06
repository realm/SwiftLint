import Foundation
import SourceKittenFramework

struct RedundantVoidReturnRule: ConfigurationProviderRule, SubstitutionCorrectableASTRule {
    var configuration = SeverityConfiguration(.warning)

    init() {}

    static let description = RuleDescription(
        identifier: "redundant_void_return",
        name: "Redundant Void Return",
        description: "Returning Void in a function declaration is redundant",
        kind: .idiomatic,
        nonTriggeringExamples: [
            Example("func foo() {}\n"),
            Example("func foo() -> Int {}\n"),
            Example("func foo() -> Int -> Void {}\n"),
            Example("func foo() -> VoidResponse\n"),
            Example("let foo: (Int) -> Void\n"),
            Example("func foo() -> Int -> () {}\n"),
            Example("let foo: (Int) -> ()\n"),
            Example("func foo() -> ()?\n"),
            Example("func foo() -> ()!\n"),
            Example("func foo() -> Void?\n"),
            Example("func foo() -> Void!\n"),
            Example("""
            struct A {
                subscript(key: String) {
                    print(key)
                }
            }
            """)
        ],
        triggeringExamples: [
            Example("func foo()↓ -> Void {}\n"),
            Example("""
            protocol Foo {
              func foo()↓ -> Void
            }
            """),
            Example("func foo()↓ -> () {}\n"),
            Example("func foo()↓ -> ( ) {}"),
            Example("""
            protocol Foo {
              func foo()↓ -> ()
            }
            """)
        ],
        corrections: [
            Example("func foo()↓ -> Void {}\n"): Example("func foo() {}\n"),
            Example("protocol Foo {\n func foo()↓ -> Void\n}\n"): Example("protocol Foo {\n func foo()\n}\n"),
            Example("func foo()↓ -> () {}\n"): Example("func foo() {}\n"),
            Example("protocol Foo {\n func foo()↓ -> ()\n}\n"): Example("protocol Foo {\n func foo()\n}\n"),
            Example("protocol Foo {\n    #if true\n    func foo()↓ -> Void\n    #endif\n}\n"):
                Example("protocol Foo {\n    #if true\n    func foo()\n    #endif\n}\n")
        ]
    )

    private let pattern = "\\s*->\\s*(?:Void\\b|\\(\\s*\\))(?![?!])"
    private let excludingKinds = SyntaxKind.allKinds.subtracting([.typeidentifier])
    private let functionKinds = SwiftDeclarationKind.functionKinds.subtracting([.functionSubscript])

    func validate(file: SwiftLintFile, kind: SwiftDeclarationKind,
                  dictionary: SourceKittenDictionary) -> [StyleViolation] {
        return violationRanges(in: file, kind: kind, dictionary: dictionary).map {
            StyleViolation(ruleDescription: Self.description,
                           severity: configuration.severity,
                           location: Location(file: file, characterOffset: $0.location))
        }
    }

    func violationRanges(in file: SwiftLintFile, kind: SwiftDeclarationKind,
                         dictionary: SourceKittenDictionary) -> [NSRange] {
        guard functionKinds.contains(kind),
              containsVoidReturnTypeBasedOnTypeName(dictionary: dictionary),
            let nameOffset = dictionary.nameOffset,
            let nameLength = dictionary.nameLength,
            let length = dictionary.length,
            let offset = dictionary.offset,
            case let start = nameOffset + nameLength,
            case let end = dictionary.bodyOffset ?? offset + length,
            case let contents = file.stringView,
            case let byteRange = ByteRange(location: start, length: end - start),
            let range = contents.byteRangeToNSRange(byteRange),
            file.match(pattern: "->", excludingSyntaxKinds: excludingKinds, range: range).count == 1,
            let match = file.match(pattern: pattern, excludingSyntaxKinds: excludingKinds, range: range).first else {
                return []
        }

        return [match]
    }

    func substitution(for violationRange: NSRange, in file: SwiftLintFile) -> (NSRange, String)? {
        return (violationRange, "")
    }

    private func containsVoidReturnTypeBasedOnTypeName(dictionary: SourceKittenDictionary) -> Bool {
        guard let typeName = dictionary.typeName else {
            return false
        }

        return typeName == "Void" || typeName.components(separatedBy: .whitespaces).joined() == "()"
    }
}
