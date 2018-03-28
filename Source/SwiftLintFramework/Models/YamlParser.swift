//
//  YAMLLoader.swift
//  SwiftLint
//
//  Created by Scott Hoyt on 1/1/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation
import Yams

// MARK: - YamlParsingError

internal enum YamlParserError: Error, Equatable {
    case yamlParsing(String)
}

internal func == (lhs: YamlParserError, rhs: YamlParserError) -> Bool {
    switch (lhs, rhs) {
    case let (.yamlParsing(lhs), .yamlParsing(rhs)):
        return lhs == rhs
    }
}

// MARK: - YamlParser

public struct YamlParser {
    public static func parse(_ yaml: String,
                             env: [String: String] = ProcessInfo.processInfo.environment) throws -> [String: Any] {
        do {
            return try Yams.load(yaml: yaml, .default,
                                 .swiftlintContructor(env: env)) as? [String: Any] ?? [:]
        } catch {
            throw YamlParserError.yamlParsing("\(error)")
        }
    }
}

private extension Constructor {
    static func swiftlintContructor(env: [String: String]) -> Constructor {
        return Constructor(customMap(env: env))
    }

    static func customMap(env: [String: String]) -> Constructor.ScalarMap {
        var map = Constructor.defaultScalarMap
        map[.str] = String.constructExpandingEnvVars(env: env)
        map[.bool] = Bool.constructUsingOnlyTrueAndFalse

        return map
    }
}

private extension String {
    static func constructExpandingEnvVars(env: [String: String]) -> (_ node: Node.Scalar) -> String? {
        return { (node: Node.Scalar) -> String? in
//            assert(node.isScalar)
            return node.string.expandingEnvVars(env: env)
        }
    }

    func expandingEnvVars(env: [String: String]) -> String {
        var result = self
        for (key, value) in env {
            result = result.replacingOccurrences(of: "${\(key)}", with: value)
        }

        return result
    }
}

private extension Bool {
    static func constructUsingOnlyTrueAndFalse(from node: Node.Scalar) -> Bool? {
//        assert(node.isScalar)
        switch node.string.lowercased() {
        case "true":
            return true
        case "false":
            return false
        default:
            return nil
        }
    }
}

private extension Node {
    var isScalar: Bool {
        if case .scalar = self {
            return true
        }
        return false
    }
}
