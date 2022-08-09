import Foundation
import SourceKittenFramework

public struct PreferSelfInStaticReferencesRule: SubstitutionCorrectableASTRule, OptInRule {
    public static let description = RuleDescription(
        identifier: "prefer_self_in_static_references",
        name: "Prefer Self in Static References",
        description: "Static references should be prefixed by `Self` instead of the class name.",
        kind: .style,
        nonTriggeringExamples: [
            Example("""
                class C {
                    static let primes = [2, 3, 5, 7]
                    func isPrime(i: Int) -> Bool { Self.primes.contains(i) }
            """),
            Example("""
                struct T {
                    static let i = 0
                }
                struct S {
                    static let i = 0
                }
                extension T {
                    static let j = S.i + T.i
                    static let k = { T.j }()
                }
            """),
            Example("""
                class `Self` {
                    static let i = 0
                    func f() -> Int { Self.i }
                }
            """),
            Example("""
                class C {
                    static private(set) var i = 0, j = C.i
                    static let k = { C.i }()
                    let h = C.i
                    @GreaterThan(C.j) var k: Int
                }
            """, excludeFromDocumentation: true),
            Example("""
                struct S {
                    struct T {
                        struct R {
                            static let i = 3
                        }
                    }
                    struct R {
                        static let j = S.T.R.i
                    }
                    static let j = Self.T.R.i + Self.R.j
                    let h = Self.T.R.i + Self.R.j
                }
            """, excludeFromDocumentation: true),
            Example("""
                class C {
                    static let s = 2
                    func f(i: Int = C.s) -> Int {
                        func g(@GreaterEqualThan(C.s) j: Int = C.s) -> Int { j }
                        return i + Self.s
                    }
                    func g() -> Any { C.self }
                }
            """, excludeFromDocumentation: true)
        ],
        triggeringExamples: [
            Example("""
                class C {
                    struct S {
                        static let i = 2
                        let h = ↓S.i
                    }
                    static let i = 1
                    let h = C.i
                    func f() -> Int { ↓C.i + h }
                }
            """),
            Example("""
                    struct S {
                        static let i = 1
                        static func f() -> Int { ↓S.i }
                        func g() -> Any { ↓S.self }
                    }
                    """),
            Example("""
                struct S {
                    struct T {
                        static let i = 3
                    }
                    struct R {
                        static let j = S.T.i
                    }
                    static let h = ↓S.T.i + ↓S.R.j
                }
            """)
        ],
        corrections: [
            Example("""
                struct S {
                    static let i = 1
                    static let j = ↓S.i
                    let k = ↓S.j
                    static func f(_ l: Int = ↓S.i) -> Int { l*↓S.j }
                    func g() { ↓S.i + ↓S.f() + k }
                }
            """): Example("""
                struct S {
                    static let i = 1
                    static let j = Self.i
                    let k = Self.j
                    static func f(_ l: Int = Self.i) -> Int { l*Self.j }
                    func g() { Self.i + Self.f() + k }
                }
            """)
        ]
    )

    private static let complexDeclarations: Set = [
        SwiftDeclarationKind.class,
        SwiftDeclarationKind.enum,
        SwiftDeclarationKind.struct
    ]

    private static let nestedKindsToIgnoreIfClass: Set = [
        SwiftDeclarationKind.varInstance,
        SwiftDeclarationKind.varStatic,
        SwiftDeclarationKind.varParameter
    ]

    public var configuration = SeverityConfiguration(.warning)
    public var configurationDescription = "N/A"

    public init() {}

    public init(configuration: Any) throws {
        throw ConfigurationError.unknownConfiguration
    }

    public func validate(file: SwiftLintFile,
                         kind: SwiftDeclarationKind,
                         dictionary: SourceKittenDictionary) -> [StyleViolation] {
        violationRanges(in: file, kind: kind, dictionary: dictionary)
            .compactMap(file.stringView.NSRangeToByteRange)
            .map { byteRange in
                StyleViolation(
                    ruleDescription: Self.description,
                    severity: configuration.severity,
                    location: Location(file: file, byteOffset: byteRange.location)
                )
            }
    }

    public func substitution(for violationRange: NSRange, in file: SwiftLintFile) -> (NSRange, String)? {
        (violationRange, "Self.")
    }

    public func violationRanges(in file: SwiftLintFile,
                                kind: SwiftDeclarationKind,
                                dictionary: SourceKittenDictionary) -> [NSRange] {
        guard Self.complexDeclarations.contains(kind),
              let name = dictionary.name,
              let bodyRange = dictionary.bodyByteRange else {
            return []
        }

        var rangesToIgnore = dictionary.substructure
            .flatMap { getSubstructuresToIgnore(in: $0, containedIn: kind) }
            .compactMap(\.byteRange)
            .unique
            .sorted { $0.location < $1.location }
        rangesToIgnore.append(ByteRange(location: bodyRange.upperBound, length: 0)) // Marks the end of the search

        let pattern = "(?<!\\.)\\b\(name)\\.\(kind == .class ? "(?!self)" : "")"
        var location = bodyRange.location
        return rangesToIgnore
            .flatMap { (range: ByteRange) -> [NSRange] in
                if range.location < location {
                    location = max(range.upperBound, location)
                    return []
                }
                let searchRange = ByteRange(location: location, length: range.lowerBound - location)
                location = range.upperBound
                return file.match(
                    pattern: pattern,
                    with: [.identifier],
                    range: file.stringView.byteRangeToNSRange(searchRange))
            }
    }

    private func getSubstructuresToIgnore(in structure: SourceKittenDictionary,
                                          containedIn parentKind: SwiftDeclarationKind) -> [SourceKittenDictionary] {
        guard let kind = structure.kind, let declarationKind = SwiftDeclarationKind(rawValue: kind) else {
            return []
        }
        if Self.complexDeclarations.contains(declarationKind) {
            return [structure]
        }
        if parentKind != .class {
            return []
        }
        var structures = structure.swiftAttributes
        if Self.nestedKindsToIgnoreIfClass.contains(declarationKind) {
            structures.append(structure)
            return structures
        }
        return structures + structure.substructure
            .flatMap { getSubstructuresToIgnore(in: $0, containedIn: parentKind) }
    }
}
