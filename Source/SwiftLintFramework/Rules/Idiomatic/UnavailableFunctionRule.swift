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
            Example("""
            class ViewController: UIViewController {
              @available(*, unavailable)
              public required init?(coder aDecoder: NSCoder) {
                fatalError("init(coder:) has not been implemented")
              }
            }
            """),
            Example("""
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
            """)
        ],
        triggeringExamples: [
            Example("""
            class ViewController: UIViewController {
              public required ↓init?(coder aDecoder: NSCoder) {
                fatalError("init(coder:) has not been implemented")
              }
            }
            """),
            Example("""
            class ViewController: UIViewController {
              public required ↓init?(coder aDecoder: NSCoder) {
                let reason = "init(coder:) has not been implemented"
                fatalError(reason)
              }
            }
            """)
        ]
    )

    public func validate(file: SwiftLintFile, kind: SwiftDeclarationKind,
                         dictionary: SourceKittenDictionary) -> [StyleViolation] {
        guard SwiftDeclarationKind.functionKinds.contains(kind) else {
            return []
        }

        let containsFatalError = dictionary.substructure.contains { dict -> Bool in
            return dict.expressionKind == .call && dict.name == "fatalError"
        }

        guard let offset = dictionary.offset, containsFatalError,
            !isFunctionUnavailable(file: file, dictionary: dictionary),
            let bodyRange = dictionary.bodyByteRange,
            let range = file.stringView.byteRangeToNSRange(bodyRange),
            file.match(pattern: "\\breturn\\b", with: [.keyword], range: range).isEmpty else {
                return []
        }

        return [
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severity,
                           location: Location(file: file, byteOffset: offset))
        ]
    }

    private func isFunctionUnavailable(file: SwiftLintFile, dictionary: SourceKittenDictionary) -> Bool {
        return dictionary.swiftAttributes.contains { dict -> Bool in
            guard dict.attribute.flatMap(SwiftDeclarationAttributeKind.init(rawValue:)) == .available,
                let byteRange = dict.byteRange,
                let contents = file.stringView.substringWithByteRange(byteRange) else {
                    return false
            }

            return contents.contains("unavailable")
        }
    }
}
