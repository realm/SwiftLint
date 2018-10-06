import Foundation
import SourceKittenFramework

public struct RedundantXCTAssertParameterRule: ASTRule, OptInRule, ConfigurationProviderRule, AutomaticTestableRule {

    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "redundant_xctassert_parameter",
        name: "Redundant XCTAssert Parameter",
        description: "XCTAssertNil/True/False() are preferred over using nil, true, or false as parameters.",
        kind: .idiomatic,
        nonTriggeringExamples: [
            "XCTAssertEqual(tested, expected)\n",
            "XCTAssertEqual(functionWithArgumentSupplied(animated: false), tested)\n",
            "XCTAssertEqual(tested, functionWithArgumentSupplied(data: nil))\n",
            "XCTAssertTrue(tested)\n",
            "XCTAssertFalse(tested)\n",
            "XCTAssertNil(tested)\n"
        ],
        triggeringExamples: [
            "↓XCTAssertEqual(tested, nil)\n",
            "↓XCTAssertEqual(tested, true)\n",
            "↓XCTAssertEqual(tested, false)\n",
            "↓XCTAssertEqual(nil, tested)\n",
            "↓XCTAssertEqual(true, tested)\n",
            "↓XCTAssertEqual(false, tested)\n",
            "↓XCTAssertEqual(reallyLongObjectName.parameter.toBeTested,\n nil)\n",
            "↓XCTAssertEqual(reallyLongObjectName.parameter.toBeTested,\n true)\n",
            "↓XCTAssertEqual(reallyLongObjectName.parameter.toBeTested,\n false)\n",
            "↓XCTAssertEqual(nil,\n reallyLongObjectName.parameter.toBeTested)\n",
            "↓XCTAssertEqual(true,\n reallyLongObjectName.parameter.toBeTested)\n",
            "↓XCTAssertEqual(false,\n reallyLongObjectName.parameter.toBeTested)\n"
        ]
    )

    public func validate(
        file: File,
        kind: SwiftExpressionKind,
        dictionary: [String: SourceKitRepresentable]
    ) -> [StyleViolation] {
        guard containsViolation(file: file, kind: kind, dictionary: dictionary),
            let offset = dictionary.offset else {
                return []
        }

        let location = Location(file: file, byteOffset: offset)
        return [
            StyleViolation(
                ruleDescription: type(of: self).description,
                severity: configuration.severity,
                location: location
            )
        ]
    }

    private func containsViolation(
        file: File,
        kind: SwiftExpressionKind,
        dictionary: [String: SourceKitRepresentable]
    ) -> Bool {
        guard kind == .call,
            dictionary.offset != nil,
            let name = dictionary.name,
            name.hasPrefix("XCTAssertEqual") else {
                return false
        }

        for argument in dictionary.enclosedArguments {
            if containsViolatingArgument(argument, for: file.contents) {
                return true
            }
        }

        return false
    }

    private func containsViolatingArgument(_ argument: [String: SourceKitRepresentable], for string: String) -> Bool {

        guard let offset = argument.offset,
            let length = argument.length,
            let range = string.byteRangeToNSRange(start: offset, length: length) else {

            return false
        }

        return regex("^(true|false|nil)$").firstMatch(in: string, options: [], range: range) != nil
    }

}
