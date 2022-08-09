import Foundation
import SourceKittenFramework

public struct AnonymousArgumentInMultilineClosureRule: ASTRule, OptInRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "anonymous_argument_in_multiline_closure",
        name: "Anonymous Argument in Multiline Closure",
        description: "Use named arguments in multiline closures",
        kind: .idiomatic,
        nonTriggeringExamples: [
            Example("closure { $0 }"),
            Example("closure { print($0) }"),
            Example("""
            closure { arg in
                print(arg)
            }
            """),
            Example("""
            closure { arg in
                nestedClosure { $0 + arg }
            }
            """)
        ],
        triggeringExamples: [
            Example("""
            closure {
                print(↓$0)
            }
            """)
        ]
    )

    public func validate(file: SwiftLintFile, kind: SwiftExpressionKind,
                         dictionary: SourceKittenDictionary) -> [StyleViolation] {
        guard kind == .closure,
              dictionary.enclosedVarParameters.isEmpty,
              let range = dictionary.bodyByteRange,
              let (initialLine, _) = file.stringView.lineAndCharacter(forByteOffset: range.lowerBound),
              let (finalLine, _) = file.stringView.lineAndCharacter(forByteOffset: range.upperBound),
              initialLine != finalLine,
              let bodyNSRange = file.stringView.byteRangeToNSRange(range) else {
                return []
        }

        let matches = file.match(pattern: "\\$0", with: [.identifier], range: bodyNSRange).filter { range in
            guard range.length == 2,
                  let byteRange = file.stringView.NSRangeToByteRange(range) else {
                return false
            }

            // do not trigger for nested closures
            let expressions = closureExpressions(forByteOffset: byteRange.location, structureDictionary: dictionary)
            return expressions.isEmpty
        }

        return matches.map {
            StyleViolation(ruleDescription: Self.description,
                           severity: configuration.severity,
                           location: Location(file: file, characterOffset: $0.location))
        }
    }

    private func closureExpressions(forByteOffset byteOffset: ByteCount,
                                    structureDictionary: SourceKittenDictionary) -> [SourceKittenDictionary] {
        return structureDictionary.traverseBreadthFirst { dictionary in
            guard dictionary.expressionKind == .closure,
                let byteRange = dictionary.byteRange,
                byteRange.contains(byteOffset)
            else {
                return nil
            }
            return [dictionary]
        }
    }
}
