import Foundation
import SourceKittenFramework

public struct ClosureParameterPositionRule: ASTRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "closure_parameter_position",
        name: "Closure Parameter Position",
        description: "Closure parameters should be on the same line as opening brace.",
        kind: .style,
        nonTriggeringExamples: [
            Example("[1, 2].map { $0 + 1 }\n"),
            Example("[1, 2].map({ $0 + 1 })\n"),
            Example("[1, 2].map { number in\n number + 1 \n}\n"),
            Example("[1, 2].map { number -> Int in\n number + 1 \n}\n"),
            Example("[1, 2].map { (number: Int) -> Int in\n number + 1 \n}\n"),
            Example("[1, 2].map { [weak self] number in\n number + 1 \n}\n"),
            Example("[1, 2].something(closure: { number in\n number + 1 \n})\n"),
            Example("let isEmpty = [1, 2].isEmpty()\n"),
            Example("""
            rlmConfiguration.migrationBlock.map { rlmMigration in
                return { migration, schemaVersion in
                    rlmMigration(migration.rlmMigration, schemaVersion)
                }
            }
            """),
            Example("""
            let mediaView: UIView = { [weak self] index in
               return UIView()
            }(index)
            """)
        ],
        triggeringExamples: [
            Example("""
            [1, 2].map {
                ↓number in
                number + 1
            }
            """),
            Example("""
            [1, 2].map {
                ↓number -> Int in
                number + 1
            }
            """),
            Example("""
            [1, 2].map {
                (↓number: Int) -> Int in
                number + 1
            }
            """),
            Example("""
            [1, 2].map {
                [weak ↓self] ↓number in
                number + 1
            }
            """),
            Example("""
            [1, 2].map { [weak self]
                ↓number in
                number + 1
            }
            """),
            Example("""
            [1, 2].map({
                ↓number in
                number + 1
            })
            """),
            Example("""
            [1, 2].something(closure: {
                ↓number in
                number + 1
            })
            """),
            Example("""
            [1, 2].reduce(0) {
                ↓sum, ↓number in
                number + sum
            })
            """),
            Example("""
            f.completionHandler = {
                ↓thing in
                doStuff()
            }
            """),
            Example("""
            foo {
                [weak ↓self] in
                self?.bar()
            }
            """)
        ]
    )

    private static let openBraceRegex = regex("\\{")

    public func validate(file: SwiftLintFile) -> [StyleViolation] {
        return file.structureDictionary.traverseDepthFirst { subDict in
            guard let kind = self.kind(from: subDict) else { return nil }
            return validate(file: file, kind: kind, dictionary: subDict)
        }.unique.sorted(by: { $0.location < $1.location })
    }

    public func validate(file: SwiftLintFile, kind: SwiftExpressionKind,
                         dictionary: SourceKittenDictionary) -> [StyleViolation] {
        guard kind == .closure || kind == .call else {
            return []
        }

        guard let bodyLength = dictionary.bodyLength,
            bodyLength > 0
        else {
            return []
        }

        let nameOffset = dictionary.nameOffset ?? 0
        let nameLength = dictionary.nameLength ?? 0

        let captureLists = dictionary.substructure.flatMap { dict -> [SourceKittenDictionary] in
            if SwiftVersion.current >= .fiveDotSix, dict.expressionKind == .argument {
                return dict.substructure.filter { $0.declarationKind == .varLocal }
            }

            return dict.declarationKind == .varLocal ? [dict] : []
        }
        let parameters = dictionary.enclosedVarParameters + captureLists
        let rangeStart = nameOffset + nameLength
        let regex = Self.openBraceRegex

        // parameters from inner closures are reported on the top-level one, so we can't just
        // use the first and last parameters to check, we need to check all of them
        return parameters.compactMap { param -> StyleViolation? in
            guard let paramOffset = param.offset, paramOffset > rangeStart else {
                return nil
            }

            let rangeLength = paramOffset - rangeStart
            let contents = file.stringView

            let byteRange = ByteRange(location: rangeStart, length: rangeLength)
            guard let range = contents.byteRangeToNSRange(byteRange),
                let match = regex.matches(in: file.contents, options: [], range: range).last?.range,
                match.location != NSNotFound,
                let braceOffset = contents.NSRangeToByteRange(start: match.location, length: match.length)?.location,
                let (braceLine, _) = contents.lineAndCharacter(forByteOffset: braceOffset),
                let (paramLine, _) = contents.lineAndCharacter(forByteOffset: paramOffset),
                braceLine != paramLine
            else {
                return nil
            }

            return StyleViolation(ruleDescription: Self.description,
                                  severity: configuration.severity,
                                  location: Location(file: file, byteOffset: paramOffset))
        }
    }
}
