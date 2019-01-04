import Foundation
import SourceKittenFramework

internal struct RemoteRulePayload {
    let structure: Lazy<[String: SourceKitRepresentable]>
    let syntaxMap: Lazy<[SyntaxToken]>
    let path: String?
    let contents: Lazy<String?>
    let configuration: Any?

    func asJSONData(input: Set<PluginRequiredInput>) throws -> Data {
        return try JSONSerialization.data(withJSONObject: asJSONDictionary(input: input))
    }

    func asJSONDictionary(input: Set<PluginRequiredInput>) -> [String: Any] {
        var json = [String: Any]()
        if input.contains(.structure) {
            json["structure"] = structure.value
        }
        if input.contains(.syntaxMap) {
            json["syntax_map"] = syntaxMap.value.map { $0.dictionaryValue }
        }

        json["path"] = path
        json["configuration"] = configuration
        if path == nil {
            json["contents"] = contents.value
        }

        return json
    }
}

extension RemoteRulePayload {
    init?(json: [String: Any]) {
        let rawStructure = json["structure"]
        let structure = rawStructure.map(convertingIntsToInt64) as? [String: SourceKitRepresentable] ?? [:]
        let syntaxMap = (json["syntax_map"] as? [[String: Any]])?.compactMap(SyntaxToken.init(json:)) ?? []
        let path = json["path"] as? String
        let contents = json["contents"] as? String
        let configuration = json["configuration"]

        if path == nil && contents == nil {
            return nil
        }

        self.init(structure: Lazy(structure), syntaxMap: Lazy(syntaxMap),
                  path: path, contents: Lazy(contents), configuration: configuration)
    }
}

private func convertingIntsToInt64(value: Any) -> Any {
    switch value {
    case let value as Int:
        return Int64(value)
    case let values as [Any]:
        return values.map(convertingIntsToInt64)
    case let values as [String: Any]:
        return values.mapValues(convertingIntsToInt64)
    case let value as String:
        return value
    case let value as Int64:
        return value
    case let value as Bool:
        return value
    default:
        return value
    }
}

private extension SyntaxToken {
    init?(json: [String: Any]) {
        guard let type = json["type"] as? String,
            let offset = json["offset"] as? Int,
            let length = json["length"] as? Int else {
                return nil
        }

        self.init(type: type, offset: offset, length: length)
    }
}
