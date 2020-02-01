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
            Example("init(a: Int, b: Int, c: Int, d: Int, e: Int, f: Int) {}"),
            Example("init (a: Int, b: Int, c: Int, d: Int, e: Int, f: Int) {}"),
            Example("`init`(a: Int, b: Int, c: Int, d: Int, e: Int, f: Int) {}"),
            Example("init?(a: Int, b: Int, c: Int, d: Int, e: Int, f: Int) {}"),
            Example("init?<T>(a: T, b: Int, c: Int, d: Int, e: Int, f: Int) {}"),
            Example("init?<T: String>(a: T, b: Int, c: Int, d: Int, e: Int, f: Int) {}"),
            Example("func f2(p1: Int, p2: Int) { }"),
            Example("func f(a: Int, b: Int, c: Int, d: Int, x: Int = 42) {}"),
            Example("""
            func f(a: [Int], b: Int, c: Int, d: Int, f: Int) -> [Int] {
                let s = a.flatMap { $0 as? [String: Int] } ?? []}}
            """),
            Example("override func f(a: Int, b: Int, c: Int, d: Int, e: Int, f: Int) {}")
        ],
        triggeringExamples: [
            Example("↓func f(a: Int, b: Int, c: Int, d: Int, e: Int, f: Int) {}"),
            Example("↓func initialValue(a: Int, b: Int, c: Int, d: Int, e: Int, f: Int) {}"),
            Example("↓func f(a: Int, b: Int, c: Int, d: Int, e: Int, f: Int = 2, g: Int) {}"),
            Example("""
            struct Foo {
                init(a: Int, b: Int, c: Int, d: Int, e: Int, f: Int) {}
                ↓func bar(a: Int, b: Int, c: Int, d: Int, e: Int, f: Int) {}}
            """)
        ]
    )

    public func validate(file: SwiftLintFile, kind: SwiftDeclarationKind,
                         dictionary: SourceKittenDictionary) -> [StyleViolation] {
        guard SwiftDeclarationKind.functionKinds.contains(kind) else {
            return []
        }

        let nameRange = ByteRange(location: dictionary.nameOffset ?? 0, length: dictionary.nameLength ?? 0)
        if functionIsInitializer(file: file, byteRange: nameRange) {
            return []
        }

        if functionIsOverride(attributes: dictionary.enclosedSwiftAttributes) {
            return []
        }

        let minThreshold = configuration.severityConfiguration.params.map({ $0.value }).min(by: <)

        let allParameterCount = allFunctionParameterCount(structure: dictionary.substructure, range: nameRange)
        if allParameterCount < minThreshold! {
            return []
        }

        var parameterCount = allParameterCount

        if configuration.ignoresDefaultParameters {
            parameterCount -= defaultFunctionParameterCount(file: file, byteRange: nameRange)
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

    private func allFunctionParameterCount(structure: [SourceKittenDictionary], range: ByteRange) -> Int {
        var parameterCount = 0
        for subDict in structure {
            guard subDict.kind != nil, let parameterOffset = subDict.offset else {
                continue
            }

            guard range.contains(parameterOffset) else {
                return parameterCount
            }

            if subDict.declarationKind == .varParameter {
                parameterCount += 1
            }
        }
        return parameterCount
    }

    private func defaultFunctionParameterCount(file: SwiftLintFile, byteRange: ByteRange) -> Int {
        let substring = file.stringView.substringWithByteRange(byteRange)!
        let equals = substring.filter { $0 == "=" }
        return equals.count
    }

    private func functionIsInitializer(file: SwiftLintFile, byteRange: ByteRange) -> Bool {
        guard let name = file.stringView
            .substringWithByteRange(byteRange),
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
