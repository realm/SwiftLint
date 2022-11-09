import SwiftSyntax

struct CompilerProtocolInitRule: SwiftSyntaxRule, ConfigurationProviderRule {
    var configuration = SeverityConfiguration(.warning)

    init() {}

    static let description = RuleDescription(
        identifier: "compiler_protocol_init",
        name: "Compiler Protocol Init",
        description: Self.violationReason(
            protocolName: "such as `ExpressibleByArrayLiteral`",
            isPlural: true
        ),
        kind: .lint,
        nonTriggeringExamples: [
            Example("let set: Set<Int> = [1, 2]\n"),
            Example("let set = Set(array)\n")
        ],
        triggeringExamples: [
            Example("let set = ↓Set(arrayLiteral: 1, 2)\n"),
            Example("let set = ↓Set (arrayLiteral: 1, 2)\n"),
            Example("let set = ↓Set.init(arrayLiteral: 1, 2)\n"),
            Example("let set = ↓Set.init(arrayLiteral : 1, 2)\n")
        ]
    )

    private static func violationReason(protocolName: String, isPlural: Bool = false) -> String {
        return "The initializers declared in compiler protocol\(isPlural ? "s" : "") \(protocolName) " +
                "shouldn't be called directly."
    }

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(viewMode: .sourceAccurate)
    }
}

private extension CompilerProtocolInitRule {
    final class Visitor: ViolationsSyntaxVisitor {
        override func visitPost(_ node: FunctionCallExprSyntax) {
            guard node.trailingClosure == nil else {
                return
            }

            let arguments = node.argumentList.compactMap(\.label)
            guard ExpressibleByCompiler.possibleNumberOfArguments.contains(arguments.count) else {
                return
            }

            guard let name = node.functionName, ExpressibleByCompiler.allInitNames.contains(name) else {
                return
            }

            let argumentsNames = arguments.map(\.text)
            for compilerProtocol in ExpressibleByCompiler.allProtocols {
                guard compilerProtocol.initCallNames.contains(name),
                    compilerProtocol.match(arguments: argumentsNames) else {
                    continue
                }

                violations.append(ReasonedRuleViolation(
                    position: node.positionAfterSkippingLeadingTrivia,
                    reason: violationReason(protocolName: compilerProtocol.protocolName)
                ))
                return
            }
        }
    }
}

private extension FunctionCallExprSyntax {
    // doing this instead of calling `.description` as it's faster
    var functionName: String? {
        if let expr = calledExpression.as(IdentifierExprSyntax.self) {
            return expr.identifier.text
        } else if let expr = calledExpression.as(MemberAccessExprSyntax.self),
                  let base = expr.base?.as(IdentifierExprSyntax.self) {
            return base.identifier.text + "." + expr.name.text
        }

        // we don't care about other possible expressions as they wouldn't match the calls we're interested in
        return nil
    }
}

private struct ExpressibleByCompiler {
    let protocolName: String
    let initCallNames: Set<String>
    private let arguments: Set<[String]>

    init(protocolName: String, types: Set<String>, arguments: Set<[String]>) {
        self.protocolName = protocolName
        self.arguments = arguments

        initCallNames = Set(types.flatMap { [$0, "\($0).init"] })
    }

    static let allProtocols = [byArrayLiteral, byNilLiteral, byBooleanLiteral,
                               byFloatLiteral, byIntegerLiteral, byUnicodeScalarLiteral,
                               byExtendedGraphemeClusterLiteral, byStringLiteral,
                               byStringInterpolation, byDictionaryLiteral]

    static let possibleNumberOfArguments: Set<Int> = {
        allProtocols.reduce(into: Set<Int>()) { partialResult, entry in
            partialResult.insert(entry.arguments.count)
        }
    }()

    static let allInitNames: Set<String> = {
        allProtocols.reduce(into: Set<String>()) { partialResult, entry in
            partialResult.formUnion(entry.initCallNames)
        }
    }()

    func match(arguments: [String]) -> Bool {
        return self.arguments.contains(arguments)
    }

    private static let byArrayLiteral: ExpressibleByCompiler = {
        let types: Set = [
            "Array",
            "ArraySlice",
            "ContiguousArray",
            "IndexPath",
            "NSArray",
            "NSCountedSet",
            "NSMutableArray",
            "NSMutableOrderedSet",
            "NSMutableSet",
            "NSOrderedSet",
            "NSSet",
            "SBElementArray",
            "Set",
            "IndexSet"
        ]
        return Self(protocolName: "ExpressibleByArrayLiteral", types: types, arguments: [["arrayLiteral"]])
    }()

    private static let byNilLiteral = Self(
        protocolName: "ExpressibleByNilLiteral",
        types: ["Optional"],
        arguments: [["nilLiteral"]]
    )

    private static let byBooleanLiteral = Self(
        protocolName: "ExpressibleByBooleanLiteral",
        types: ["Bool", "NSDecimalNumber", "NSNumber", "ObjCBool"],
        arguments: [["booleanLiteral"]]
    )

    private static let byFloatLiteral = Self(
        protocolName: "ExpressibleByFloatLiteral",
        types: ["Decimal", "NSDecimalNumber", "NSNumber"],
        arguments: [["floatLiteral"]]
    )

    private static let byIntegerLiteral = Self(
        protocolName: "ExpressibleByIntegerLiteral",
        types: ["Decimal", "Double", "Float", "Float80", "NSDecimalNumber", "NSNumber"],
        arguments: [["integerLiteral"]]
    )

    private static let byUnicodeScalarLiteral = Self(
        protocolName: "ExpressibleByUnicodeScalarLiteral",
        types: ["StaticString", "String", "UnicodeScalar"],
        arguments: [["unicodeScalarLiteral"]]
    )

    private static let byExtendedGraphemeClusterLiteral = Self(
        protocolName: "ExpressibleByExtendedGraphemeClusterLiteral",
        types: ["Character", "StaticString", "String"],
        arguments: [["extendedGraphemeClusterLiteral"]]
    )

    private static let byStringLiteral = Self(
        protocolName: "ExpressibleByStringLiteral",
        types: ["CSLocalizedString", "NSMutableString", "NSString", "Selector", "StaticString", "String"],
        arguments: [["stringLiteral"]]
    )

    private static let byStringInterpolation = Self(
        protocolName: "ExpressibleByStringInterpolation",
        types: ["String"],
        arguments: [["stringInterpolation"], ["stringInterpolationSegment"]]
    )

    private static let byDictionaryLiteral = Self(
        protocolName: "ExpressibleByDictionaryLiteral",
        types: ["Dictionary", "DictionaryLiteral", "NSDictionary", "NSMutableDictionary"],
        arguments: [["dictionaryLiteral"]]
    )
}
