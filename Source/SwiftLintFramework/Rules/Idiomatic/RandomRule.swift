import SourceKittenFramework

public struct RandomRule: ASTRule, OptInRule, ConfigurationProviderRule, AutomaticTestableRule {

    public var configuration = SeverityConfiguration(.warning)

    private let randomFunctions: Set<String> = [
        "arc4random",
        "arc4random_uniform",
        "drand48"
    ]

    public init() {}

    public static var description = RuleDescription(
        identifier: "random",
        name: "Random",
        description: "Prefer using `type.random` over C-based functions.",
        kind: .lint,
        minSwiftVersion: .fourDotTwo,
        nonTriggeringExamples: [
            "Int.random(in: 0..<10)\n",
            "Double.random(in: 8.6...111.34)\n",
            "Float.random(in: 0 ..< 1)\n"
        ],
        triggeringExamples: [
            "↓arc4random(10)\n",
            "↓arc4random_uniform(83)\n",
            "↓drand48(52)\n"
        ]
    )

    // MARK: - ASTRule

    public func validate(
        file: File,
        kind: SwiftDeclarationKind,
        dictionary: [String: SourceKitRepresentable]
    ) -> [StyleViolation] {

        return violationRanges(in: file, kind: kind, dictionary: dictionary).map { violation in

            let location = Location(file: file, characterOffset: violation.location)
            let ruleDescription = type(of: self).description

            return StyleViolation(
                ruleDescription: ruleDescription,
                severity: configuration.severity,
                location: location
            )
        }
    }

    // MARK: - Private

    private func violationRanges(
        in file: File,
        kind: SwiftDeclarationKind,
        dictionary: [String: SourceKitRepresentable]
    ) -> [NSRange] {

        // TODO: may be wrong type
        guard kind == .functionFree else { return [] }

        return dictionary.elements.compactMap { subDict -> NSRange? in
            guard
                let offset = subDict.offset,
                let length = subDict.length,
                let content = file.contents.bridge().substringWithByteRange(start: offset, length: length),
                randomFunctions.contains(content)
            else {
                return nil
            }

            return file.contents.bridge().byteRangeToNSRange(start: offset, length: length)
        }
    }

}
