//
//  FunctionParameterCountRule.swift
//  SwiftLint
//
//  Created by Denis Lebedev on 26/01/2016.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct FunctionParameterCountRule: ASTRule, ConfigurationProviderRule {
    public var configuration = SeverityLevelsConfiguration(warning: 5, error: 8)

    public init() {}

    public static let description = RuleDescription(
        identifier: "function_parameter_count",
        name: "Function Parameter Count",
        description: "Number of function parameters should be low.",
        nonTriggeringExamples: [
            "init(a: Int, b: Int, c: Int, d: Int, e: Int, f: Int) {}",
            "`init`(a: Int, b: Int, c: Int, d: Int, e: Int, f: Int) {}",
            "init?(a: Int, b: Int, c: Int, d: Int, e: Int, f: Int) {}",
            "func f2(p1: Int, p2: Int) { }",
            "func f(a: Int, b: Int, c: Int, d: Int, x: Int = 42) {}",
            "func f(a: [Int], b: Int, c: Int, d: Int, f: Int) -> [Int] {\n" +
                "let s = a.flatMap { $0 as? [String: Int] } ?? []}}"
        ],
        triggeringExamples: [
            "func f(a: Int, b: Int, c: Int, d: Int, e: Int, f: Int) {}",
            "func f(a: Int, b: Int, c: Int, d: Int, e: Int, f: Int = 2, g: Int) {}",
            "struct Foo {\n" +
                "init(a: Int, b: Int, c: Int, d: Int, e: Int, f: Int) {}\n" +
                "func bar(a: b, c: Int, d: Int, e: Int, f: Int, g: Int) {}}"
        ]
    )

    public func validateFile(_ file: File, kind: SwiftDeclarationKind,
                             dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        if !functionKinds.contains(kind) {
            return []
        }

        let nameOffset = Int(dictionary["key.nameoffset"] as? Int64 ?? 0)
        let length = Int(dictionary["key.namelength"] as? Int64 ?? 0)
        let substructure = dictionary["key.substructure"] as? [SourceKitRepresentable] ?? []

        if functionIsInitializer(file, offset: nameOffset, length: length) {
            return []
        }

        let minThreshold = configuration.params.map({ $0.value }).min(by: <)

        let allParameterCount =
            allFunctionParameterCount(substructure, offset: nameOffset, length: length)
        if allParameterCount < minThreshold! {
            return []
        }

        let parameterCount = allParameterCount -
            defaultFunctionParameterCount(file, offset: nameOffset, length: length)

        for parameter in configuration.params where parameterCount > parameter.value {
            let offset = Int(dictionary["key.offset"] as? Int64 ?? 0)
            return [StyleViolation(ruleDescription: type(of: self).description,
                severity: parameter.severity,
                location: Location(file: file, byteOffset: offset),
                reason: "Function should have \(configuration.warning) parameters or less: " +
                    "it currently has \(parameterCount)")]
        }

        return []
    }

    fileprivate func allFunctionParameterCount(_ structure: [SourceKitRepresentable],
                                           offset: Int, length: Int) -> Int {
        var parameterCount = 0
        for substructure in structure {
            guard let subDict = substructure as? [String: SourceKitRepresentable],
                let key = subDict["key.kind"] as? String,
                let parameterOffset = subDict["key.offset"] as? Int64 else {
                    continue
            }

            guard offset..<offset+length ~= Int(parameterOffset) else {
                return parameterCount
            }

            if SwiftDeclarationKind(rawValue: key) == .varParameter {
                parameterCount += 1
            }
        }
        return parameterCount
    }

    fileprivate func defaultFunctionParameterCount(_ file: File, offset: Int, length: Int) -> Int {
        let equalCharacter = Character("=")
        return (file.contents as NSString)
            .substringWithByteRange(start: offset, length: length)?
            .characters.filter { $0 == equalCharacter }.count ?? 0
    }

    fileprivate func functionIsInitializer(_ file: File, offset: Int, length: Int) -> Bool {
        if let function = (file.contents as NSString)
            .substringWithByteRange(start: offset, length: length), function.hasPrefix("init") {
            return true
        }
        return false
    }

    fileprivate let functionKinds: [SwiftDeclarationKind] = [
        .functionAccessorAddress,
        .functionAccessorDidset,
        .functionAccessorGetter,
        .functionAccessorMutableaddress,
        .functionAccessorSetter,
        .functionAccessorWillset,
        .functionConstructor,
        .functionDestructor,
        .functionFree,
        .functionMethodClass,
        .functionMethodInstance,
        .functionMethodStatic,
        .functionOperator,
        .functionSubscript
    ]
}
