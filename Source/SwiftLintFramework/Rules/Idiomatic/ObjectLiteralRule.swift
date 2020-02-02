import SourceKittenFramework

public struct ObjectLiteralRule: ASTRule, ConfigurationProviderRule, OptInRule {
    public var configuration = ObjectLiteralConfiguration()

    public init() {}

    public static let description = RuleDescription(
        identifier: "object_literal",
        name: "Object Literal",
        description: "Prefer object literals over image and color inits.",
        kind: .idiomatic,
        nonTriggeringExamples: [
            Example("let image = #imageLiteral(resourceName: \"image.jpg\")"),
            Example("let color = #colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)"),
            Example("let image = UIImage(named: aVariable)"),
            Example("let image = UIImage(named: \"interpolated \\(variable)\")"),
            Example("let color = UIColor(red: value, green: value, blue: value, alpha: 1)"),
            Example("let image = NSImage(named: aVariable)"),
            Example("let image = NSImage(named: \"interpolated \\(variable)\")"),
            Example("let color = NSColor(red: value, green: value, blue: value, alpha: 1)")
        ],
        triggeringExamples: ["", ".init"].flatMap { (method: String) -> [Example] in
            ["UI", "NS"].flatMap { (prefix: String) -> [Example] in
                [
                    Example("let image = ↓\(prefix)Image\(method)(named: \"foo\")"),
                    Example("let color = ↓\(prefix)Color\(method)(red: 0.3, green: 0.3, blue: 0.3, alpha: 1)"),
                    // swiftlint:disable:next line_length
                    Example("let color = ↓\(prefix)Color\(method)(red: 100 / 255.0, green: 50 / 255.0, blue: 0, alpha: 1)"),
                    Example("let color = ↓\(prefix)Color\(method)(white: 0.5, alpha: 1)")
                ]
            }
        }
    )

    public func validate(file: SwiftLintFile, kind: SwiftExpressionKind,
                         dictionary: SourceKittenDictionary) -> [StyleViolation] {
        guard kind == .call,
            let offset = dictionary.offset,
            (configuration.imageLiteral && isImageNamedInit(dictionary: dictionary, file: file)) ||
                (configuration.colorLiteral && isColorInit(dictionary: dictionary, file: file)) else {
            return []
        }

        return [
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severityConfiguration.severity,
                           location: Location(file: file, byteOffset: offset))
        ]
    }

    private func isImageNamedInit(dictionary: SourceKittenDictionary, file: SwiftLintFile) -> Bool {
        guard let name = dictionary.name,
            inits(forClasses: ["UIImage", "NSImage"]).contains(name),
            case let arguments = dictionary.enclosedArguments,
            arguments.compactMap({ $0.name }) == ["named"],
            let argument = arguments.first,
            case let kinds = kinds(forArgument: argument, file: file),
            kinds == [.string] else {
                return false
        }

        return true
    }

    private func isColorInit(dictionary: SourceKittenDictionary, file: SwiftLintFile) -> Bool {
        guard let name = dictionary.name,
            inits(forClasses: ["UIColor", "NSColor"]).contains(name),
            case let arguments = dictionary.enclosedArguments,
            case let argumentsNames = arguments.compactMap({ $0.name }),
            argumentsNames == ["red", "green", "blue", "alpha"] || argumentsNames == ["white", "alpha"],
            validateColorKinds(arguments: arguments, file: file) else {
                return false
        }

        return true
    }

    private func inits(forClasses names: [String]) -> [String] {
        return names.flatMap { name in
            [
                name,
                name + ".init"
            ]
        }
    }

    private func validateColorKinds(arguments: [SourceKittenDictionary], file: SwiftLintFile) -> Bool {
        for dictionary in arguments where kinds(forArgument: dictionary, file: file) != [.number] {
            return false
        }

        return true
    }

    private func kinds(forArgument argument: SourceKittenDictionary, file: SwiftLintFile) -> Set<SyntaxKind> {
        return argument.bodyByteRange.map { Set(file.syntaxMap.kinds(inByteRange: $0)) } ?? []
    }
}
