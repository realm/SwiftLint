import Foundation
import SourceKittenFramework

public struct ExplicitInitRule: SubstitutionCorrectableASTRule, ConfigurationProviderRule, OptInRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "explicit_init",
        name: "Explicit Init",
        description: "Explicitly calling .init() should be avoided.",
        kind: .idiomatic,
        nonTriggeringExamples: [
            Example("""
            import Foundation
            class C: NSObject {
                override init() {
                    super.init()
                }
            }
            """), // super
            Example("""
            struct S {
                let n: Int
            }
            extension S {
                init() {
                    self.init(n: 1)
                }
            }
            """), // self
            Example("""
            [1].flatMap(String.init)
            """), // pass init as closure
            Example("""
            [String.self].map { $0.init(1) }
            """), // initialize from a metatype value
            Example("""
            [String.self].map { type in type.init(1) }
            """), // initialize from a metatype value
            Example("""
            Observable.zip(obs1, obs2, resultSelector: MyType.init).asMaybe()
            """),
            Example("""
            Observable.zip(
              obs1,
              obs2,
              resultSelector: MyType.init
            ).asMaybe()
            """)
        ],
        triggeringExamples: [
            Example("""
            [1].flatMap{String↓.init($0)}
            """),
            Example("""
            [String.self].map { Type in Type↓.init(1) }
            """),  // Starting with capital letter assumes a type
            Example("""
            func foo() -> [String] {
                return [1].flatMap { String↓.init($0) }
            }
            """),
            Example("""
            Observable.zip(
              obs1,
              obs2,
              resultSelector: { MyType↓.init($0, $1) }
            ).asMaybe()
            """),
            Example("""
            let int = Int↓
            .init(1.0)
            """, excludeFromDocumentation: true),
            Example("""
            let int = Int↓


            .init(1.0)
            """, excludeFromDocumentation: true),
            Example("""
            let int = Int↓


                  .init(1.0)
            """, excludeFromDocumentation: true)
        ],
        corrections: [
            Example("""
            [1].flatMap{String↓.init($0)}
            """):
                Example("""
                [1].flatMap{String($0)}
                """),
            Example("""
            func foo() -> [String] {
                return [1].flatMap { String↓.init($0) }
            }
            """):
                Example("""
                func foo() -> [String] {
                    return [1].flatMap { String($0) }
                }
                """),
            Example("""
            class C {
            #if true
                func f() {
                    [1].flatMap{String↓.init($0)}
                }
            #endif
            }
            """):
                Example("""
                class C {
                #if true
                    func f() {
                        [1].flatMap{String($0)}
                    }
                #endif
                }
                """),
            Example("""
            let int = Int↓
            .init(1.0)
            """):
                Example("""
                let int = Int(1.0)
                """),
            Example("""
            let int = Int↓


            .init(1.0)
            """):
                Example("""
                let int = Int(1.0)
                """),
            Example("""
            let int = Int↓


                  .init(1.0)
            """):
                Example("""
                let int = Int(1.0)
                """),
            Example("""
            let int = Int↓


                  .init(1.0)



            """):
                Example("""
                let int = Int(1.0)



                """)
        ]
    )

    public func validate(file: SwiftLintFile, kind: SwiftExpressionKind,
                         dictionary: SourceKittenDictionary) -> [StyleViolation] {
        return violationRanges(in: file, kind: kind, dictionary: dictionary).map {
            StyleViolation(ruleDescription: Self.description,
                           severity: configuration.severity,
                           location: Location(file: file, characterOffset: $0.location))
        }
    }

    private let initializerWithType = regex("^[A-Z][^(]*\\.init$")

    public func violationRanges(in file: SwiftLintFile, kind: SwiftExpressionKind,
                                dictionary: SourceKittenDictionary) -> [NSRange] {
        func isExpected(_ name: String) -> Bool {
            let range = NSRange(location: 0, length: name.utf16.count)
            return !["super.init", "self.init"].contains(name)
                && initializerWithType.numberOfMatches(in: name, options: [], range: range) != 0
        }

        let length = ByteCount(".init".utf8.count)

        guard kind == .call,
            let name = dictionary.name, isExpected(name),
            let nameOffset = dictionary.nameOffset,
            let nameLength = dictionary.nameLength,
            let range = file.stringView
                .byteRangeToNSRange(ByteRange(location: nameOffset + nameLength - length, length: length))
            else { return [] }
        var count = 0
        while file.stringView.substring(with: NSRange(location: range.location - count - 1, length: 1))
            .filter({ $0.isNewline || $0.isWhitespace }).count == 1 {
            count += 1
        }

        return [NSRange(location: range.location - count, length: range.length + count)]
    }

    public func substitution(for violationRange: NSRange, in file: SwiftLintFile) -> (NSRange, String)? {
        return (violationRange, "")
    }
}
