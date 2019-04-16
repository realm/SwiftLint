import Foundation
import SourceKittenFramework

public struct NoReturnVoidRule: ASTRule, ConfigurationProviderRule, AutomaticTestableRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "no_return_void",
        name: "No Return Void",
        description: "Avoid returning a function.",
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
            """
        ],
        triggeringExamples: []
    )

    public func validate(file: File, kind: SwiftDeclarationKind,
                         dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        guard SwiftDeclarationKind.functionKinds.contains(kind),
            let offset = dictionary.offset, let nameOffset = dictionary.nameOffset,
            dictionary["key.typename"] == nil || (dictionary["key.typename"] as? String) == "Void" else
        {
                return []
        }

        print(toJSON(dictionary))
        print(offset)
        print(nameOffset)
        return []
    }
}
