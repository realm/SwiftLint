import Foundation
import SourceKittenFramework

public struct TypeNameRule: ASTRule, ConfigurationProviderRule {
    public var configuration = NameConfiguration(minLengthWarning: 3,
                                                 minLengthError: 0,
                                                 maxLengthWarning: 40,
                                                 maxLengthError: 1000)

    public init() {}

    public static let description = RuleDescription(
        identifier: "type_name",
        name: "Type Name",
        description: "Type name should only contain alphanumeric characters, start with an " +
                     "uppercase character and span between 3 and 40 characters in length.",
        kind: .idiomatic,
        nonTriggeringExamples: TypeNameRuleExamples.nonTriggeringExamples,
        triggeringExamples: TypeNameRuleExamples.triggeringExamples
    )

    private let typeKinds = SwiftDeclarationKind.typeKinds

    public func validate(file: SwiftLintFile, kind: SwiftDeclarationKind,
                         dictionary: SourceKittenDictionary) -> [StyleViolation] {
        guard typeKinds.contains(kind),
            let name = dictionary.name,
            let offset = dictionary.nameOffset else {
                return []
        }

        return validate(name: name, dictionary: dictionary, file: file, offset: offset)
    }

    private func validate(name: String, dictionary: SourceKittenDictionary = SourceKittenDictionary([:]),
                          file: SwiftLintFile, offset: ByteCount) -> [StyleViolation] {
        guard !configuration.excluded.contains(name) else {
            return []
        }

        let name = name
            .nameStrippingLeadingUnderscoreIfPrivate(dictionary)
            .nameStrippingTrailingSwiftUIPreviewProvider(dictionary)
        let allowedSymbols = configuration.allowedSymbols.union(.alphanumerics)
        if !allowedSymbols.isSuperset(of: CharacterSet(charactersIn: name)) {
            return [StyleViolation(ruleDescription: Self.description,
                                   severity: .error,
                                   location: Location(file: file, byteOffset: offset),
                                   reason: "Type name should only contain alphanumeric characters: '\(name)'")]
        } else if configuration.validatesStartWithLowercase &&
            name.first?.isLowercase == true {
            return [StyleViolation(ruleDescription: Self.description,
                                   severity: .error,
                                   location: Location(file: file, byteOffset: offset),
                                   reason: "Type name should start with an uppercase character: '\(name)'")]
        } else if let severity = severity(forLength: name.count) {
            return [StyleViolation(ruleDescription: Self.description,
                                   severity: severity,
                                   location: Location(file: file, byteOffset: offset),
                                   reason: "Type name should be between \(configuration.minLengthThreshold) and " +
                "\(configuration.maxLengthThreshold) characters long: '\(name)'")]
        }

        return []
    }
}

private extension String {
    func nameStrippingTrailingSwiftUIPreviewProvider(_ dictionary: SourceKittenDictionary) -> String {
        guard dictionary.inheritedTypes.contains("PreviewProvider"),
            hasSuffix("_Previews"),
            let lastPreviewsIndex = lastIndex(of: "_Previews")
            else { return self }

        return substring(from: 0, length: lastPreviewsIndex)
    }
}
