import SwiftSyntax

public struct CompilerProtocolInitRule: SwiftSyntaxRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
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
            Example("let set = ↓Set.init(arrayLiteral: 1, 2)\n")
        ]
    )

    private static func violationReason(protocolName: String, isPlural: Bool = false) -> String {
        return "The initializers declared in compiler protocol\(isPlural ? "s" : "") \(protocolName) " +
                "shouldn't be called directly."
    }

    public func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(viewMode: .sourceAccurate)
    }
}

private extension CompilerProtocolInitRule {
    final class Visitor: ViolationsSyntaxVisitor {
        override func visitPost(_ node: FunctionCallExprSyntax) {
            let arguments = node.argumentList.compactMap { $0.label?.withoutTrivia().text }
            guard ExpressibleByCompiler.possibleNumberOfArguments.contains(arguments.count) else {
                return
            }

            let name = node.calledExpression.withoutTrivia().description

            for compilerProtocol in ExpressibleByCompiler.allProtocols {
                guard compilerProtocol.initCallNames.contains(name),
                    compilerProtocol.match(arguments: arguments) else {
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
        var args: Set<Int> = []
        for entry in allProtocols {
            for argument in entry.arguments {
                args.insert(argument.count)
            }
        }
        return args
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
        return ExpressibleByCompiler(protocolName: "ExpressibleByArrayLiteral",
                                     types: types, arguments: [["arrayLiteral"]])
    }()

    private static let byNilLiteral = ExpressibleByCompiler(protocolName: "ExpressibleByNilLiteral",
                                                            types: ["Optional"],
                                                            arguments: [["nilLiteral"]])

    private static let byBooleanLiteral = ExpressibleByCompiler(protocolName: "ExpressibleByBooleanLiteral",
                                                                types: ["Bool", "NSDecimalNumber",
                                                                        "NSNumber", "ObjCBool"],
                                                                arguments: [["booleanLiteral"]])

    private static let byFloatLiteral = ExpressibleByCompiler(protocolName: "ExpressibleByFloatLiteral",
                                                              types: ["Decimal", "NSDecimalNumber", "NSNumber"],
                                                              arguments: [["floatLiteral"]])

    private static let byIntegerLiteral = ExpressibleByCompiler(protocolName: "ExpressibleByIntegerLiteral",
                                                                types: ["Decimal", "Double", "Float", "Float80",
                                                                        "NSDecimalNumber", "NSNumber"],
                                                                arguments: [["integerLiteral"]])

    private static let byUnicodeScalarLiteral = ExpressibleByCompiler(protocolName: "ExpressibleByUnicodeScalarLiteral",
                                                                      types: ["StaticString", "String",
                                                                              "UnicodeScalar"],
                                                                      arguments: [["unicodeScalarLiteral"]])

    private static let byExtendedGraphemeClusterLiteral =
        ExpressibleByCompiler(protocolName: "ExpressibleByExtendedGraphemeClusterLiteral",
                              types: ["Character", "StaticString", "String"],
                              arguments: [["extendedGraphemeClusterLiteral"]])

    private static let byStringLiteral = ExpressibleByCompiler(protocolName: "ExpressibleByStringLiteral",
                                                               types: ["CSLocalizedString", "NSMutableString",
                                                                       "NSString", "Selector",
                                                                       "StaticString", "String"],
                                                               arguments: [["stringLiteral"]])

    private static let byStringInterpolation = ExpressibleByCompiler(protocolName: "ExpressibleByStringInterpolation",
                                                                     types: ["String"],
                                                                     arguments: [["stringInterpolation"],
                                                                                 ["stringInterpolationSegment"]])

    private static let byDictionaryLiteral = ExpressibleByCompiler(protocolName: "ExpressibleByDictionaryLiteral",
                                                                   types: ["Dictionary", "DictionaryLiteral",
                                                                           "NSDictionary", "NSMutableDictionary"],
                                                                   arguments: [["dictionaryLiteral"]])
}
