import Foundation
import SourceKittenFramework

public struct KeyPathExpressionAsFunctionRule: ASTRule, ConfigurationProviderRule, AutomaticTestableRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "key_path_expression_as_function",
        name: "Key Path Expression as Function",
        description: "Discouraged explicit usage of the default separator.",
        kind: .idiomatic,
        minSwiftVersion: .fiveDotTwo,
        nonTriggeringExamples: [
            Example("let emails = users.map(\\.email)"),
            Example("let admins = users.filter(\\.isAdmin)"),
            Example("let ones = users.filter { _ in 1 }"),
            Example("let emails = users.map { $0.email() }"),
            Example("""
            let emails = users.map { user in
                user.email()
            }
            """)
        ],
        triggeringExamples: [
            Example("let emails = users.map ↓{ $0.email }"),
            Example("let emails = users.map(↓{ $0.email })"),
            Example("let admins = users.filter(where: ↓{ $0.isAdmin })"),
            Example("""
            let emails = users.map ↓{ user in
              user.email
            }
            """)
        ]
    )

    // MARK: - ASTRule

    public func validate(file: SwiftLintFile,
                         kind: SwiftExpressionKind,
                         dictionary: SourceKittenDictionary) -> [StyleViolation] {
        guard SwiftVersion.current >= type(of: self).description.minSwiftVersion else {
            return []
        }

        return violationRanges(in: file, kind: kind, dictionary: dictionary).map {
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severity,
                           location: Location(file: file, byteOffset: $0))
        }
    }

    private func violationRanges(in file: SwiftLintFile,
                                 kind: SwiftExpressionKind,
                                 dictionary: SourceKittenDictionary) -> [ByteCount] {
        guard kind == .call else {
            return []
        }

        let closures = dictionary.substructure.compactMap { dictionary -> SourceKittenDictionary? in
            if dictionary.isClosure {
                return dictionary
            }

            if dictionary.isClosureArgument {
                return dictionary.substructure.first
            }

            return nil
        }

        return closures.compactMap { dictionary in
            guard !dictionary.containsMethodCall, !dictionary.containsMutedArguments else {
                return nil
            }

            return dictionary.offset
        }
    }
}

private extension SourceKittenDictionary {
    var isClosure: Bool {
        return kind.flatMap(SwiftExpressionKind.init(rawValue:)) == .closure
    }

    var isClosureArgument: Bool {
        return kind.flatMap(SwiftExpressionKind.init(rawValue:)) == .argument &&
            substructure.count == 1 &&
            substructure.allSatisfy { $0.isClosure }
    }

    var containsMethodCall: Bool {
        return substructure.contains { dictionary in
            dictionary.kind.flatMap(SwiftExpressionKind.init(rawValue:)) == .call
        }
    }

    var containsMutedArguments: Bool {
        return substructure.contains { dictionary in
            dictionary.kind.flatMap(SwiftDeclarationKind.init(rawValue:)) == .varParameter &&
                dictionary.name == nil
        }
    }
}
