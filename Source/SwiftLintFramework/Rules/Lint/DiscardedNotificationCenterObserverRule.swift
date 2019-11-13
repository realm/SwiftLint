import Foundation
import SourceKittenFramework

public struct DiscardedNotificationCenterObserverRule: ASTRule, ConfigurationProviderRule, AutomaticTestableRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "discarded_notification_center_observer",
        name: "Discarded Notification Center Observer",
        description: "When registering for a notification using a block, the opaque observer that is " +
                     "returned should be stored so it can be removed later.",
        kind: .lint,
        nonTriggeringExamples: [
            "let foo = nc.addObserver(forName: .NSSystemTimeZoneDidChange, object: nil, queue: nil) { }\n",
            "let foo = nc.addObserver(forName: .NSSystemTimeZoneDidChange, object: nil, queue: nil, using: { })\n",
            "func foo() -> Any {\n" +
            "   return nc.addObserver(forName: .NSSystemTimeZoneDidChange, object: nil, queue: nil, using: { })\n" +
            "}\n",
            "var obs: [Any?] = []\n" +
            "obs.append(nc.addObserver(forName: .NSSystemTimeZoneDidChange, object: nil, queue: nil, using: { }))\n",
            "var obs: [String: Any?] = []\n" +
            "obs[\"foo\"] = nc.addObserver(forName: .NSSystemTimeZoneDidChange, object: nil, queue: nil, using: { })\n",
            "var obs: [Any?] = []\n" +
            "obs.append(nc.addObserver(forName: .NSSystemTimeZoneDidChange, object: nil, queue: nil, using: { }))\n",
            "func foo(_ notif: Any) {\n" +
            "   obs.append(notif)\n" +
            "}\n" +
            "foo(nc.addObserver(forName: .NSSystemTimeZoneDidChange, object: nil, queue: nil, using: { }))\n"
        ],
        triggeringExamples: [
            "↓nc.addObserver(forName: .NSSystemTimeZoneDidChange, object: nil, queue: nil) { }\n",
            "↓nc.addObserver(forName: .NSSystemTimeZoneDidChange, object: nil, queue: nil, using: { })\n",
            "@discardableResult func foo() -> Any {\n" +
            "   return ↓nc.addObserver(forName: .NSSystemTimeZoneDidChange, object: nil, queue: nil, using: { })\n" +
            "}\n"
        ]
    )

    public func validate(file: SwiftLintFile, kind: SwiftExpressionKind,
                         dictionary: SourceKittenDictionary) -> [StyleViolation] {
        return violationOffsets(in: file, dictionary: dictionary, kind: kind).map { location in
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severity,
                           location: Location(file: file, byteOffset: location))
        }
    }

    private func violationOffsets(in file: SwiftLintFile, dictionary: SourceKittenDictionary,
                                  kind: SwiftExpressionKind) -> [Int] {
        guard kind == .call,
            let name = dictionary.name,
            name.hasSuffix(".addObserver"),
            case let arguments = dictionary.enclosedArguments,
            case let argumentsNames = arguments.compactMap({ $0.name }),
            argumentsNames == ["forName", "object", "queue"] ||
                argumentsNames == ["forName", "object", "queue", "using"],
            let offset = dictionary.offset,
            let range = file.linesContainer.byteRangeToNSRange(start: 0, length: offset) else {
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

        return [offset]
    }
}

private extension SourceKittenDictionary {
    func functions(forByteOffset byteOffset: Int) -> [SourceKittenDictionary] {
        return structures(forByteOffset: byteOffset)
            .filter { $0.declarationKind.map(SwiftDeclarationKind.functionKinds.contains) == true }
    }
}
