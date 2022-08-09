import Foundation
import SourceKittenFramework

public struct DiscardedNotificationCenterObserverRule: ASTRule, ConfigurationProviderRule,
    OptInRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "discarded_notification_center_observer",
        name: "Discarded Notification Center Observer",
        description: "When registering for a notification using a block, the opaque observer that is " +
                     "returned should be stored so it can be removed later.",
        kind: .lint,
        nonTriggeringExamples: [
            Example("let foo = nc.addObserver(forName: .NSSystemTimeZoneDidChange, object: nil, queue: nil) { }\n"),
            Example("""
            let foo = nc.addObserver(forName: .NSSystemTimeZoneDidChange, object: nil, queue: nil, using: { })
            """),
            Example("func foo() -> Any {\n" +
            "   return nc.addObserver(forName: .NSSystemTimeZoneDidChange, object: nil, queue: nil, using: { })\n" +
            "}\n"),
            Example("var obs: [Any?] = []\n" +
            "obs.append(nc.addObserver(forName: .NSSystemTimeZoneDidChange, object: nil, queue: nil, using: { }))\n"),
            Example("""
            var obs: [String: Any?] = []
            obs["foo"] = nc.addObserver(forName: .NSSystemTimeZoneDidChange, object: nil, queue: nil, using: { })
            """),
            Example("var obs: [Any?] = []\n" +
            "obs.append(nc.addObserver(forName: .NSSystemTimeZoneDidChange, object: nil, queue: nil, using: { }))\n"),
            Example("func foo(_ notif: Any) {\n" +
            "   obs.append(notif)\n" +
            "}\n" +
            "foo(nc.addObserver(forName: .NSSystemTimeZoneDidChange, object: nil, queue: nil, using: { }))\n"),
            Example("""
            var obs: [NSObjectProtocol] = [
               nc.addObserver(forName: .NSSystemTimeZoneDidChange, object: nil, queue: nil, using: { }),
               nc.addObserver(forName: .CKAccountChanged, object: nil, queue: nil, using: { })
            ]
            """)
        ],
        triggeringExamples: [
            Example("↓nc.addObserver(forName: .NSSystemTimeZoneDidChange, object: nil, queue: nil) { }\n"),
            Example("↓nc.addObserver(forName: .NSSystemTimeZoneDidChange, object: nil, queue: nil, using: { })\n"),
            Example("""
            @discardableResult func foo() -> Any {
               return ↓nc.addObserver(forName: .NSSystemTimeZoneDidChange, object: nil, queue: nil, using: { })
            }
            """)
        ]
    )

    public func validate(file: SwiftLintFile, kind: SwiftExpressionKind,
                         dictionary: SourceKittenDictionary) -> [StyleViolation] {
        return violationOffsets(in: file, dictionary: dictionary, kind: kind).map { location in
            StyleViolation(ruleDescription: Self.description,
                           severity: configuration.severity,
                           location: Location(file: file, byteOffset: location))
        }
    }

    private func violationOffsets(in file: SwiftLintFile, dictionary: SourceKittenDictionary,
                                  kind: SwiftExpressionKind) -> [ByteCount] {
        guard kind == .call,
            let name = dictionary.name,
            name.hasSuffix(".addObserver"),
            case let arguments = dictionary.enclosedArguments,
            case let argumentsNames = arguments.compactMap({ $0.name }),
            argumentsNames == ["forName", "object", "queue"] ||
                argumentsNames == ["forName", "object", "queue", "using"],
            let offset = dictionary.offset,
            let range = file.stringView.byteRangeToNSRange(ByteRange(location: 0, length: offset)) else {
                return []
        }

        if let lastMatch = regex("\\b[^\\(]+").matches(in: file.contents, options: [], range: range).last?.range,
            lastMatch.location == range.length - lastMatch.length - 1 {
            return []
        }

        if let lastMatch = regex("\\s?=\\s*").matches(in: file.contents, options: [], range: range).last?.range,
            lastMatch.location == range.length - lastMatch.length {
            return []
        }

        if let lastMatch = file.match(pattern: "\\breturn\\s+", with: [.keyword], range: range).last,
            lastMatch.location == range.length - lastMatch.length,
            let lastFunction = file.structureDictionary.functions(forByteOffset: offset).last,
            !lastFunction.enclosedSwiftAttributes.contains(.discardableResult) {
            return []
        }

        let kinds = file.structureDictionary.kinds(forByteOffset: offset)
        if kinds.count >= 2 && SwiftExpressionKind(rawValue: kinds[kinds.count - 2].0) == .array {
            return []
        }

        return [offset]
    }
}

private extension SourceKittenDictionary {
    func functions(forByteOffset byteOffset: ByteCount) -> [SourceKittenDictionary] {
        return structures(forByteOffset: byteOffset)
            .filter { $0.declarationKind.map(SwiftDeclarationKind.functionKinds.contains) == true }
    }
}
