import Foundation
import Yams

// MARK: - YamlParsingError

internal enum YamlParserError: Error, Equatable {
    case yamlParsing(String)
}

// MARK: - YamlParser

/// An interface for parsing YAML.
public struct YamlParser {
    /// Parses the input YAML string as an untyped dictionary.
    ///
    /// - parameter yaml: YAML-formatted string.
    /// - parameter env:  The environment to use to expand variables in the YAML.
    ///
    /// - returns: The parsed YAML as an untyped dictionary.
    ///
    /// - throws: Throws if the `yaml` string provided could not be parsed.
    public static func parse(_ yaml: String,
                             env: [String: String] = ProcessInfo.processInfo.environment) throws -> [String: Any] {
        do {
            return try Yams.load(yaml: yaml, .default,
                                 .swiftlintConstructor(env: env)) as? [String: Any] ?? [:]
        } catch {
            throw YamlParserError.yamlParsing("\(error)")
        }
    }
}

private extension Constructor {
    static func swiftlintConstructor(env: [String: String]) -> Constructor {
        return Constructor(customScalarMap(env: env))
    }

    static func customScalarMap(env: [String: String]) -> ScalarMap {
        var map = defaultScalarMap
        map[.str] = String.constructExpandingEnvVars(env: env)
        map[.bool] = Bool.constructUsingOnlyTrueAndFalse

        return map
    }
}

private extension String {
    static func constructExpandingEnvVars(env: [String: String]) -> (_ scalar: Node.Scalar) -> String? {
        return { (scalar: Node.Scalar) -> String? in
            return scalar.string.expandingEnvVars(env: env)
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
    static func constructUsingOnlyTrueAndFalse(from scalar: Node.Scalar) -> Bool? {
        switch scalar.string.lowercased() {
        case "true":
            return true
        case "false":
            return false
        default:
            return nil
        }
    }
}
