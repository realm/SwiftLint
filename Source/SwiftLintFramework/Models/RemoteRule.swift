import Foundation
import Socket
import SourceKittenFramework

public final class RemoteRule {
    public let description: RuleDescription
    private let executable: String
    private let configuration: Any?

    public init(description: RuleDescription, executable: String, configuration: Any?) {
        self.description = description
        self.executable = executable
        self.configuration = configuration
    }

    public func validate(file: File) -> [StyleViolation] {
        let payload = Payload(structure: file.structure.dictionary,
                              syntaxMap: file.syntaxMap.tokens,
                              path: file.path,
                              contents: file.contents,
                              configuration: configuration)
        return validate(payload: payload, file: file)
    }

    private func validate(payload: Payload, file: File) -> [StyleViolation] {
        do {
            let socket = try Socket.create(family: .unix, type: .stream, proto: .unix)
            try socket.connect(to: "/tmp/\(description.identifier).socket")

            let data = try payload.asJSONData()
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

                return StyleViolation(ruleDescription: description,
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
        return map { $0.description.identifier }
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
    let structure: [String: SourceKitRepresentable]
    let syntaxMap: [SyntaxToken]
    let path: String?
    let contents: String
    let configuration: Any?

    func asJSONData() throws -> Data {
        return try JSONSerialization.data(withJSONObject: asJSONDictionary())
    }

    func asJSONDictionary() -> [String: Any] {
        var json = [
            "structure": structure,
            "syntax_map": syntaxMap.map { $0.dictionaryValue }
        ] as [String: Any]
        json["path"] = path
        json["configuration"] = configuration
        if path == nil {
            json["contents"] = contents
        }

        return json
    }
}
