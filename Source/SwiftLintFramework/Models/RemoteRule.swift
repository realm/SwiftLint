import Foundation
import Socket
import SourceKittenFramework

public final class RemoteRule {
    public let description: PluginDescription
    public let configuration: Any?

    public var ruleDescription: RuleDescription {
        return description.ruleDescription
    }

    public init(description: PluginDescription, configuration: Any?) {
        self.description = description
        self.configuration = configuration
    }

    public func validate(file: File) -> [StyleViolation] {
        let payload = RemoteRulePayload(structure: Lazy(file.structure.dictionary),
                                        syntaxMap: Lazy(file.syntaxMap.tokens),
                                        path: file.path,
                                        contents: Lazy(file.contents),
                                        configuration: configuration)
        return validate(payload: payload, file: file)
    }

    private func validate(payload: RemoteRulePayload, file: File) -> [StyleViolation] {
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
                guard let location = Location(file: file, json: dictionary) else {
                    return nil
                }

                return StyleViolation(ruleDescription: ruleDescription,
                                      severity: severity,
                                      location: location,
                                      reason: dictionary["reason"] as? String)
            }
        } catch {
            queuedPrintError(error)
            return []
        }
    }
}

internal extension Array where Element == RemoteRule {
    var identifiers: [String] {
        return map { $0.ruleDescription.identifier }
    }
}

private extension Location {
    init?(file: File, json: [String: Any]) {
        if let byteOffset = json["byte_offset"] as? Int {
            self = Location(file: file, byteOffset: byteOffset)
        } else if let characterOffset = json["character_offset"] as? Int {
            self = Location(file: file, characterOffset: characterOffset)
        } else if let location = json["location"] as? [String: Int],
            let line = location["line"] {
            self = Location(file: file.path, line: line, character: location["character"] ?? 1)
        } else {
            return nil
        }
    }
}
