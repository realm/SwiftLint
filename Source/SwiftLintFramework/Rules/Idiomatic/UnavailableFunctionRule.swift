import Foundation
import SourceKittenFramework

public struct UnavailableFunctionRule: ASTRule, ConfigurationProviderRule, OptInRule, AutomaticTestableRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "unavailable_function",
        name: "Unavailable Function",
        description: "Unimplemented functions should be marked as unavailable.",
        kind: .idiomatic,
        minSwiftVersion: .fourDotOne,
        nonTriggeringExamples: [
            """
            class ViewController: UIViewController {
              @available(*, unavailable)
              public required init?(coder aDecoder: NSCoder) {
                fatalError("init(coder:) has not been implemented")
              }
            }
            """,
            """
            func jsonValue(_ jsonString: String) -> NSObject {
               let data = jsonString.data(using: .utf8)!
               let result = try! JSONSerialization.jsonObject(with: data, options: [])
               if let dict = (result as? [String: Any])?.bridge() {
                return dict
               } else if let array = (result as? [Any])?.bridge() {
                return array
               }
               fatalError()
            }
            """
        ],
        triggeringExamples: [
            """
            class ViewController: UIViewController {
              public required ↓init?(coder aDecoder: NSCoder) {
                fatalError("init(coder:) has not been implemented")
              }
            }
            """,
            """
            class ViewController: UIViewController {
              public required ↓init?(coder aDecoder: NSCoder) {
                let reason = "init(coder:) has not been implemented"
                fatalError(reason)
              }
            }
            """
        ]
    )

    public func validate(file: File, kind: SwiftDeclarationKind,
                         dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        guard SwiftDeclarationKind.functionKinds.contains(kind) else {
            return []
        }

        let containsFatalError = dictionary.substructure.contains { dict -> Bool in
            return dict.kind.flatMap(SwiftExpressionKind.init(rawValue:)) == .call && dict.name == "fatalError"
        }

        guard let offset = dictionary.offset, containsFatalError,
            !isFunctionUnavailable(file: file, dictionary: dictionary),
            let bodyOffset = dictionary.bodyOffset, let bodyLength = dictionary.bodyLength,
            let range = file.contents.bridge().byteRangeToNSRange(start: bodyOffset, length: bodyLength),
            file.match(pattern: "\\breturn\\b", with: [.keyword], range: range).isEmpty else {
                return []
        }

        return [
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severity,
                           location: Location(file: file, byteOffset: offset))
        ]
    }

    private func isFunctionUnavailable(file: File, dictionary: [String: SourceKitRepresentable]) -> Bool {
        return dictionary.swiftAttributes.contains { dict -> Bool in
            guard dict.attribute.flatMap(SwiftDeclarationAttributeKind.init(rawValue:)) == .available,
                let offset = dict.offset, let length = dict.length,
                let contents = file.contents.bridge().substringWithByteRange(start: offset, length: length) else {
                    return false
            }

            return contents.contains("unavailable")
        }
    }
}
