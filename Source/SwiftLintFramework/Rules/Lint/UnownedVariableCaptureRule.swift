import Foundation
import SourceKittenFramework

public struct UnownedVariableCaptureRule: ASTRule, OptInRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "unowned_variable_capture",
        name: "Unowned Variable Capture",
        description: "Prefer capturing references as weak to avoid potential crashes.",
        kind: .lint,
        nonTriggeringExamples: [
            Example("foo { [weak self] in _ }"),
            Example("foo { [weak self] param in _ }"),
            Example("foo { [weak bar] in _ }"),
            Example("foo { [weak bar] param in _ }"),
            Example("foo { bar in _ }"),
            Example("foo { $0 }")
        ],
        triggeringExamples: [
            Example("foo { [↓unowned self] in _ }"),
            Example("foo { [↓unowned bar] in _ }"),
            Example("foo { [bar, ↓unowned self] in _ }")
        ]
    )

    public func validate(file: SwiftLintFile, kind: SwiftExpressionKind,
                         dictionary: SourceKittenDictionary) -> [StyleViolation] {
        guard kind == .closure, let bodyRange = dictionary.bodyByteRange,
            case let contents = file.stringView,
            let closureRange = contents.byteRangeToNSRange(bodyRange),
            let inTokenRange = file.match(pattern: "\\bin\\b", with: [.keyword], range: closureRange).first,
            let inTokenByteRange = contents.NSRangeToByteRange(start: inTokenRange.location,
                                                               length: inTokenRange.length)
        else {
            return []
        }

        let length = inTokenByteRange.location - bodyRange.location
        let variables = localVariableDeclarations(inByteRange: ByteRange(location: bodyRange.location, length: length),
                                                  structureDictionary: file.structureDictionary)
        let unownedVariableOffsets = variables.compactMap { dictionary in
            return dictionary.swiftAttributes.first { attributeDict in
                guard attributeDict.attribute.flatMap(SwiftDeclarationAttributeKind.init) == .weak,
                    let attributeByteRange = attributeDict.byteRange
                else {
                    return false
                }

                return contents.substringWithByteRange(attributeByteRange) == "unowned"
            }?.offset
        }.unique

        return unownedVariableOffsets.map { offset in
            return StyleViolation(ruleDescription: Self.description,
                                  severity: configuration.severity,
                                  location: Location(file: file, byteOffset: offset))
        }
    }

    private func localVariableDeclarations(inByteRange byteRange: ByteRange,
                                           structureDictionary: SourceKittenDictionary) -> [SourceKittenDictionary] {
        return structureDictionary.traverseBreadthFirst { dictionary in
            guard dictionary.declarationKind == .varLocal,
                let variableByteRange = dictionary.byteRange,
                byteRange.intersects(variableByteRange)
            else {
                return nil
            }
            return [dictionary]
        }
    }
}
