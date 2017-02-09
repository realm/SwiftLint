//
//  CompilerProtocolInitRule.swift
//  SwiftLint
//
//  Created by Marcelo Fabri on 12/31/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct CompilerProtocolInitRule: ASTRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "compiler_protocol_init",
        name: "Compiler Protocol Init",
        description: "The initializers declared in compiler protocols such as `ExpressibleByArrayLiteral` " +
                     "shouldn't be called directly.",
        nonTriggeringExamples: [
            "let set: Set<Int> = [1, 2]\n",
            "let set = Set(array)\n"
        ],
        triggeringExamples: [
            "let set = ↓Set(arrayLiteral: 1, 2)\n",
            "let set = ↓Set.init(arrayLiteral: 1, 2)\n"
        ]
    )

    public func validate(file: File, kind: SwiftExpressionKind,
                         dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        return violationRanges(in: file, kind: kind, dictionary: dictionary).map {
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severity,
                           location: Location(file: file, characterOffset: $0.location))
        }
    }

    private func violationRanges(in file: File, kind: SwiftExpressionKind,
                                 dictionary: [String: SourceKitRepresentable]) -> [NSRange] {
        guard kind == .call, let name = dictionary.name else {
            return []
        }

        for compilerProtocol in ExpressibleByCompiler.allProtocols {
            guard compilerProtocol.initCallNames.contains(name),
                case let arguments = dictionary.enclosedArguments.flatMap({ $0.name }),
                compilerProtocol.match(arguments: arguments),
                let offset = dictionary.offset,
                let length = dictionary.length,
                let range = file.contents.bridge().byteRangeToNSRange(start: offset, length: length) else {
                    continue
            }

            return [range]
        }

        return []
    }
}

private struct ExpressibleByCompiler {
    private let protocolName: String
    let initCallNames: Set<String>
    private let arguments: [[String]]

    init(protocolName: String, types: Set<String>, arguments: [[String]]) {
        self.protocolName = protocolName
        self.arguments = arguments

        initCallNames = Set(types.flatMap { [$0, "\($0).init"] })
    }

    static let allProtocols = [byArrayLiteral, byNilLiteral, byBooleanLiteral,
                               byFloatLiteral, byIntegerLiteral, byUnicodeScalarLiteral,
                               byExtendedGraphemeClusterLiteral, byStringLiteral,
                               byStringInterpolation, byDictionaryLiteral]

    func match(arguments: [String]) -> Bool {
        return self.arguments.contains { $0 == arguments }
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
            "Set"
        ]
        return ExpressibleByCompiler(protocolName: "ExpressibleByArrayLiteral",
                                     types: types, arguments: [["arrayLiteral"]])
    }()

    private static let byNilLiteral = ExpressibleByCompiler(protocolName: "ExpressibleByNilLiteral",
                                                            types: ["ImplicitlyUnwrappedOptional", "Optional"],
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
