import Foundation
import SourceKittenFramework

public struct NoGuardReturnVoidRule: ASTRule, ConfigurationProviderRule, AutomaticTestableRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "no_guard_return_void",
        name: "No Guard Return Void",
        description: "Guard statements in void functions should not have a statement after the return.",
        kind: .style,
        nonTriggeringExamples: [
            "",
            "func test() {}",
            """
            func test() -> Result<String, Error> {
                func other() {}
                func otherVoid() -> Void {}
            }
            """,
            """
            func test() {
                if X {
                    return Logger.assertionFailure("")
                }

                let asdf = [1, 2, 3].filter { return true }
                return
            }
            """,
            """
            func test() {
                let file = File(path: "/nonexistent")
                guard file.exists() > 4 else {
                    print("File doesn't exist")
                    return
                }
            }
            """
        ],
        triggeringExamples: [
            """
            func test(text: String?) {
                guard let text = text else {
                    return↓ print("Should be non optional")
                }
            }
            """,
            """
            func test() -> Result<String, Error> {
                func other() {
                    guard false else {
                        return↓ assertionfailure("")
                    }
                }
                func otherVoid() -> Void {}
            }
            """,
            """
            func test() {
                guard conditionIsTrue else {
                    sideEffects()
                    return // comment
                }
                guard otherCondition else {
                    return↓ assertionfailure("")
                }
                differentSideEffect()
            }
            """,
            """
            func test() {
                guard otherCondition else {
                    return↓ assertionfailure(""); // comment
                }
                differentSideEffect()
            }
            """
        ]
    )

    public func validate(file: File, kind: SwiftDeclarationKind,
                         dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        guard SwiftDeclarationKind.functionKinds.contains(kind),
            dictionary.isVoidDeclaration(),
            let guardRanges = dictionary.guardStatementRanges(),
            !guardRanges.isEmpty
        else {
            return []
        }

        return guardRanges
            .map({ range in
                return file.syntaxMap.tokens.filter { range.contains($0.offset) && !$0.isComment }
            })
            .compactMap({ tokens in
                guard let last = tokens.last,
                    let lastKeyword = tokens.last(where: { $0.isKeyword }),
                    last != lastKeyword
                else {
                    return nil
                }

                let location = Location(file: file, characterOffset: lastKeyword.offset + lastKeyword.length)
                return StyleViolation(ruleDescription: type(of: self).description,
                                      severity: configuration.severity,
                                      location: location)
            })
    }
}

private extension Dictionary where Dictionary == [String: SourceKitRepresentable] {
    func isVoidDeclaration() -> Bool {
        return self["key.typename"] == nil || (self["key.typename"] as? String) == "Void"
    }

    func guardStatementRanges() -> [NSRange]? {
        let ranges = (self["key.substructure"] as? [[String: SourceKitRepresentable]])?
            .compactMap({ $0 })
            .filter({ $0.isGuardStatment() })
            .compactMap({ $0.range() })

        return ranges
    }
}

private extension SourceKitRepresentable where Self == [String: SourceKitRepresentable] {
    func isGuardStatment() -> Bool {
        return self["key.kind"] as? String == "source.lang.swift.stmt.guard"
    }

    func range() -> NSRange? {
        guard let offset = self["key.offset"] as? Int64, let length = self["key.length"] as? Int64 else {
            return nil
        }

        return NSRange(location: Int(offset), length: Int(length))
    }
}

private extension SyntaxToken {
    var isComment: Bool {
        return self.type == "source.lang.swift.syntaxtype.comment"
    }

    var isKeyword: Bool {
        return self.type == "source.lang.swift.syntaxtype.keyword"
    }
}
