import SourceKittenFramework

public struct NotificationCenterDetachmentRule: ASTRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "notification_center_detachment",
        name: "Notification Center Detachment",
        description: "An object should only remove itself as an observer in `deinit`.",
        kind: .lint,
        nonTriggeringExamples: NotificationCenterDetachmentRuleExamples.nonTriggeringExamples,
        triggeringExamples: NotificationCenterDetachmentRuleExamples.triggeringExamples
    )

    public func validate(file: SwiftLintFile, kind: SwiftDeclarationKind,
                         dictionary: SourceKittenDictionary) -> [StyleViolation] {
        guard kind == .class else {
            return []
        }

        return violationOffsets(file: file, dictionary: dictionary).map { offset in
            StyleViolation(ruleDescription: Self.description,
                           severity: configuration.severity,
                           location: Location(file: file, byteOffset: offset))
        }
    }

    private func violationOffsets(file: SwiftLintFile,
                                  dictionary: SourceKittenDictionary) -> [ByteCount] {
        return dictionary.substructure.flatMap { subDict -> [ByteCount] in
            // complete detachment is allowed on `deinit`
            if subDict.declarationKind == .functionMethodInstance,
                subDict.name == "deinit" {
                return []
            }

            if subDict.expressionKind == .call,
                subDict.name == methodName,
                parameterIsSelf(dictionary: subDict, file: file),
                let offset = subDict.offset {
                return [offset]
            }

            return violationOffsets(file: file, dictionary: subDict)
        }
    }

    private var methodName = "NotificationCenter.default.removeObserver"

    private func parameterIsSelf(dictionary: SourceKittenDictionary, file: SwiftLintFile) -> Bool {
        guard let bodyRange = dictionary.bodyByteRange,
            case let tokens = file.syntaxMap.tokens(inByteRange: bodyRange),
            tokens.kinds == [.keyword],
            let token = tokens.first
        else {
            return false
        }

        let body = file.contents(for: token)
        return body == "self"
    }
}
