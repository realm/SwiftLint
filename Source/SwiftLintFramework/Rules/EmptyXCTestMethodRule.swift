import Foundation
import SourceKittenFramework

public struct EmptyXCTestMethodRule: Rule, OptInRule, ConfigurationProviderRule {

    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "empty_xctest_method",
        name: "Empty XCTest Method",
        description: "Empty XCTest method should be avoided.",
        kind: .idiomatic,
        nonTriggeringExamples: EmptyXCTestMethodRuleExamples.nonTriggeringExamples,
        triggeringExamples: EmptyXCTestMethodRuleExamples.triggeringExamples
    )

    public func validate(file: File) -> [StyleViolation] {
        return testClasses(in: file).flatMap { violations(in: file, for: $0) }
    }

    // MARK: - Private

    private func testClasses(in file: File) -> [[String: SourceKitRepresentable]] {
        return file.structure.dictionary.substructure.filter { dictionary in
            guard
                let kind = dictionary.kind,
                SwiftDeclarationKind(rawValue: kind) == .class else { return false }

            return !dictionary.inheritedTypes.filter { $0 == "XCTestCase" }.isEmpty
        }
    }

    private func violations(in file: File,
                            for dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        return dictionary.substructure.compactMap { subDictionary -> StyleViolation? in
            guard
                let kind = subDictionary.kind,
                let swiftKind = SwiftDeclarationKind(rawValue: kind),
                SwiftDeclarationKind.functionKinds.contains(swiftKind),
                let name = subDictionary.name, isXCTestMethod(name),
                subDictionary.enclosedVarParameters.isEmpty,
                let offset = subDictionary.offset,
                let bodyOffset = subDictionary.bodyOffset,
                let bodyLength = subDictionary.bodyLength,
                case let bodyContent = file.contents.bridge(),
                let startLine = bodyContent.lineAndCharacter(forByteOffset: bodyOffset)?.line,
                let endLine = bodyContent.lineAndCharacter(forByteOffset: bodyOffset + bodyLength)?.line,
                case let (_, lineCount) = file.exceedsLineCountExcludingCommentsAndWhitespace(startLine, endLine, 0),
                lineCount < 1 else { return nil }

            return StyleViolation(ruleDescription: type(of: self).description,
                                  severity: configuration.severity,
                                  location: Location(file: file, byteOffset: offset))
        }
    }

    private func isXCTestMethod(_ method: String) -> Bool {
        return method.hasPrefix("test") || method == "setUp()" || method == "tearDown()"
    }
}
