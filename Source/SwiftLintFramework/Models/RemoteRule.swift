import Foundation
import Socket
import SourceKittenFramework

public final class RemoteRule {
    public let description: PluginDescription
    private let executable: String
    public let configuration: Any?

    public var ruleDescription: RuleDescription {
        return description.ruleDescription
    }

    public init(description: PluginDescription, executable: String, configuration: Any?) {
        self.description = description
        self.executable = executable
        self.configuration = configuration
    }

    public func validate(file: File) -> [StyleViolation] {
        let payload = Payload(structure: Lazy(file.structure.dictionary),
                              syntaxMap: Lazy(file.syntaxMap.tokens),
                              path: file.path,
                              contents: Lazy(file.contents),
                              configuration: configuration)
        return validate(payload: payload, file: file)
    }

    private func validate(payload: Payload, file: File) -> [StyleViolation] {
        do {
            let socket = try Socket.create(family: .unix, type: .stream, proto: .unix)
            try socket.connect(to: "/tmp/\(ruleDescription.identifier).socket")

            let data = try payload.asJSONData(input: description.requiredInformation)
            try socket.write(from: data)

            var readData = Data()
            _ = try socket.read(into: &readData)

            guard let json = try JSONSerialization.jsonObject(with: readData) as? [[String: Any]] else {
                return []
            }

            return json.compactMap { dictionary -> StyleViolation? in
                let severity = (dictionary["severity"] as? String).flatMap(ViolationSeverity.init) ?? .warning
                guard let location = parseLocation(from: dictionary, file: file) else {
                    return nil
                }

                return StyleViolation(ruleDescription: ruleDescription,
                                      severity: severity,
                                      location: location,
                                      reason: dictionary["reason"] as? String)
            }
        } catch {
            return []
        }
    }
}

internal extension Array where Element == RemoteRule {
    var identifiers: [String] {
        return map { $0.ruleDescription.identifier }
    }
}

private func parseLocation(from dictionary: [String: Any],
                           file: File) -> Location? {
    if let byteOffset = dictionary["byte_offset"] as? Int {
        return Location(file: file, byteOffset: byteOffset)
    } else if let characterOffset = dictionary["character_offset"] as? Int {
        return Location(file: file, characterOffset: characterOffset)
    } else if let location = dictionary["location"] as? [String: Int],
        let line = location["line"] {
        return Location(file: file.path, line: line, character: location["character"] ?? 1)
    }

    return nil
}

private struct Payload {
    let structure: Lazy<[String: SourceKitRepresentable]>
    let syntaxMap: Lazy<[SyntaxToken]>
    let path: String?
    let contents: Lazy<String>
    let configuration: Any?

    func asJSONData(input: Set<PluginRequiredInput>) throws -> Data {
        return try JSONSerialization.data(withJSONObject: asJSONDictionary(input: input))
    }

    private func asJSONDictionary(input: Set<PluginRequiredInput>) -> [String: Any] {
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
