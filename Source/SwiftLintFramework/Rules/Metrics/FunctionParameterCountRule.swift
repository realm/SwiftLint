import Foundation
import SourceKittenFramework

public struct FunctionParameterCountRule: ASTRule, ConfigurationProviderRule {
    public var configuration = FunctionParameterCountConfiguration(warning: 5, error: 8)

    public init() {}

    public static let description = RuleDescription(
        identifier: "function_parameter_count",
        name: "Function Parameter Count",
        description: "Number of function parameters should be low.",
        kind: .metrics,
        nonTriggeringExamples: [
            "init(a: Int, b: Int, c: Int, d: Int, e: Int, f: Int) {}",
            "init (a: Int, b: Int, c: Int, d: Int, e: Int, f: Int) {}",
            "`init`(a: Int, b: Int, c: Int, d: Int, e: Int, f: Int) {}",
            "init?(a: Int, b: Int, c: Int, d: Int, e: Int, f: Int) {}",
            "init?<T>(a: T, b: Int, c: Int, d: Int, e: Int, f: Int) {}",
            "init?<T: String>(a: T, b: Int, c: Int, d: Int, e: Int, f: Int) {}",
            "func f2(p1: Int, p2: Int) { }",
            "func f(a: Int, b: Int, c: Int, d: Int, x: Int = 42) {}",
            "func f(a: [Int], b: Int, c: Int, d: Int, f: Int) -> [Int] {\n" +
                "let s = a.flatMap { $0 as? [String: Int] } ?? []}}",
            "override func f(a: Int, b: Int, c: Int, d: Int, e: Int, f: Int) {}"
        ],
        triggeringExamples: [
            "↓func f(a: Int, b: Int, c: Int, d: Int, e: Int, f: Int) {}",
            "↓func initialValue(a: Int, b: Int, c: Int, d: Int, e: Int, f: Int) {}",
            "↓func f(a: Int, b: Int, c: Int, d: Int, e: Int, f: Int = 2, g: Int) {}",
            "struct Foo {\n" +
                "init(a: Int, b: Int, c: Int, d: Int, e: Int, f: Int) {}\n" +
                "↓func bar(a: Int, b: Int, c: Int, d: Int, e: Int, f: Int) {}}"
        ]
    )

    public func validate(file: SwiftLintFile, kind: SwiftDeclarationKind,
                         dictionary: SourceKittenDictionary) -> [StyleViolation] {
        guard SwiftDeclarationKind.functionKinds.contains(kind) else {
            return []
        }

        let nameOffset = dictionary.nameOffset ?? 0
        let length = dictionary.nameLength ?? 0

        if functionIsInitializer(file: file, byteOffset: nameOffset, byteLength: length) {
            return []
        }

        if functionIsOverride(attributes: dictionary.enclosedSwiftAttributes) {
            return []
        }

        let minThreshold = configuration.severityConfiguration.params.map({ $0.value }).min(by: <)

        let allParameterCount = allFunctionParameterCount(structure: dictionary.substructure, offset: nameOffset,
                                                          length: length)
        if allParameterCount < minThreshold! {
            return []
        }

        var parameterCount = allParameterCount

        if configuration.ignoresDefaultParameters {
            parameterCount -= defaultFunctionParameterCount(file: file, byteOffset: nameOffset, byteLength: length)
        }

        for parameter in configuration.severityConfiguration.params where parameterCount > parameter.value {
            let offset = dictionary.offset ?? 0
            let reason = "Function should have \(configuration.severityConfiguration.warning) parameters or less: " +
                         "it currently has \(parameterCount)"
            return [StyleViolation(ruleDescription: type(of: self).description,
                                   severity: parameter.severity,
                                   location: Location(file: file, byteOffset: offset),
                                   reason: reason)]
        }

        return []
    }

    private func allFunctionParameterCount(structure: [SourceKittenDictionary],
                                           offset: Int, length: Int) -> Int {
        var parameterCount = 0
        for subDict in structure {
            guard subDict.kind != nil,
                let parameterOffset = subDict.offset else {
                    continue
            }

            guard offset..<(offset + length) ~= parameterOffset else {
                return parameterCount
            }

            if subDict.declarationKind == .varParameter {
                parameterCount += 1
            }
        }
        return parameterCount
    }

    private func defaultFunctionParameterCount(file: SwiftLintFile, byteOffset: Int, byteLength: Int) -> Int {
        let substring = file.linesContainer.substringWithByteRange(start: byteOffset, length: byteLength)!
        let equals = substring.filter { $0 == "=" }
        return equals.count
    }

    private func functionIsInitializer(file: SwiftLintFile, byteOffset: Int, byteLength: Int) -> Bool {
        guard let name = file.contents.bridge()
            .substringWithByteRange(start: byteOffset, length: byteLength),
            name.hasPrefix("init"),
            let funcName = name.components(separatedBy: CharacterSet(charactersIn: "<(")).first else {
            return false
        }
        if funcName == "init" { // fast path
            return true
        }
        let nonAlphas = CharacterSet.alphanumerics.inverted
        let alphaNumericName = funcName.components(separatedBy: nonAlphas).joined()
        return alphaNumericName == "init"
    }

    private func functionIsOverride(attributes: [SwiftDeclarationAttributeKind]) -> Bool {
        return attributes.contains(.override)
    }
}
