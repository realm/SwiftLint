import Foundation
import SourceKittenFramework

public struct ExplicitInitRule: ASTRule, ConfigurationProviderRule, CorrectableRule, OptInRule, AutomaticTestableRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "explicit_init",
        name: "Explicit Init",
        description: "Explicitly calling .init() should be avoided.",
        kind: .idiomatic,
        nonTriggeringExamples: [
            "import Foundation; class C: NSObject { override init() { super.init() }}", // super
            "struct S { let n: Int }; extension S { init() { self.init(n: 1) } }",      // self
            "[1].flatMap(String.init)",                   // pass init as closure
            "[String.self].map { $0.init(1) }",           // initialize from a metatype value
            "[String.self].map { type in type.init(1) }",  // initialize from a metatype value
            "Observable.zip(obs1, obs2, resultSelector: MyType.init).asMaybe()",
            """
            Observable.zip(
              obs1,
              obs2,
              resultSelector: MyType.init
            ).asMaybe()
            """
        ],
        triggeringExamples: [
            "[1].flatMap{String↓.init($0)}",
            "[String.self].map { Type in Type↓.init(1) }", // starting with capital assumes as type,
            """
            func foo() -> [String] {
              return [1].flatMap { String↓.init($0) }
            }
            """,
            """
            Observable.zip(
              obs1,
              obs2,
              resultSelector: { MyType.init($0, $1) }
            ).asMaybe()
            """
        ],
        corrections: [
            "[1].flatMap{String↓.init($0)}": "[1].flatMap{String($0)}",
            "func foo() -> [String] {\n    return [1].flatMap { String↓.init($0) }\n}":
                "func foo() -> [String] {\n    return [1].flatMap { String($0) }\n}",
            "class C {\n#if true\nfunc f() {\n[1].flatMap{String.init($0)}\n}\n#endif\n}":
                "class C {\n#if true\nfunc f() {\n[1].flatMap{String($0)}\n}\n#endif\n}"
        ]
    )

    public func validate(file: File, kind: SwiftExpressionKind,
                         dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        return violationRanges(in: file, kind: kind, dictionary: dictionary).map {
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severity,
                           location: Location(file: file, characterOffset: $0.location))
        }
    }

    private let initializerWithType = regex("^[A-Z][^(]*\\.init$")

    private func violationRanges(in file: File, kind: SwiftExpressionKind,
                                 dictionary: [String: SourceKitRepresentable]) -> [NSRange] {
        func isExpected(_ name: String) -> Bool {
            let range = NSRange(location: 0, length: name.utf16.count)
            return !["super.init", "self.init"].contains(name)
                && initializerWithType.numberOfMatches(in: name, options: [], range: range) != 0
        }

        let length = ".init".utf8.count

        guard kind == .call,
            let name = dictionary.name, isExpected(name),
            let nameOffset = dictionary.nameOffset,
            let nameLength = dictionary.nameLength,
            let range = file.contents.bridge()
                .byteRangeToNSRange(start: nameOffset + nameLength - length, length: length)
            else { return [] }
        return [range]
    }

    private func violationRanges(in file: File, dictionary: [String: SourceKitRepresentable]) -> [NSRange] {
        let ranges = dictionary.substructure.flatMap { subDict -> [NSRange] in
            var ranges = violationRanges(in: file, dictionary: subDict)
            if let kind = subDict.kind.flatMap(SwiftExpressionKind.init(rawValue:)) {
                ranges += violationRanges(in: file, kind: kind, dictionary: subDict)
            }

            return ranges
        }

        return ranges.unique
    }

    private func violationRanges(in file: File) -> [NSRange] {
        return violationRanges(in: file, dictionary: file.structure.dictionary).sorted { lhs, rhs in
            lhs.location > rhs.location
        }
    }

    public func correct(file: File) -> [Correction] {
        let matches = violationRanges(in: file)
            .filter { !file.ruleEnabled(violatingRanges: [$0], for: self).isEmpty }
        guard !matches.isEmpty else { return [] }

        let description = type(of: self).description
        var corrections = [Correction]()
        var contents = file.contents
        for range in matches {
            contents = contents.bridge().replacingCharacters(in: range, with: "")
            let location = Location(file: file, characterOffset: range.location)
            corrections.append(Correction(ruleDescription: description, location: location))
        }

        file.write(contents)
        return corrections
    }
}
