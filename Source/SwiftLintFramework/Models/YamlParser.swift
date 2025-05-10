import Foundation
import Yams

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
            throw Issue.yamlParsing("\(error)")
        }
    }
}

private extension Constructor {
    static func swiftlintConstructor(env: [String: String]) -> Constructor {
        Constructor(customScalarMap(env: env))
    }

    static func customScalarMap(env: [String: String]) -> ScalarMap {
        var map = defaultScalarMap
        map[.str] = { $0.string.expandingEnvVars(env: env) }
        map[.bool] = {
            switch $0.string.expandingEnvVars(env: env).lowercased() {
            case "true": true
            case "false": false
            default: nil
            }
        }
        map[.int] = { Int($0.string.expandingEnvVars(env: env)) }
        map[.float] = { Double($0.string.expandingEnvVars(env: env)) }
        return map
    }
}

private extension String {
    func expandingEnvVars(env: [String: String]) -> String {
        guard contains("${") else {
            // No environment variables used.
            return self
        }
        return env.reduce(into: self) { result, envVar in
            result = result.replacingOccurrences(of: "${\(envVar.key)}", with: envVar.value)
        }
    }
}
