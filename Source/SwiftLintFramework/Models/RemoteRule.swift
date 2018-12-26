import Foundation
import SourceKittenFramework

struct RemoteRule {
    let description: RuleDescription
    let executable: String
    let configuration: Any?

    func validate(file: File) -> [StyleViolation] {
        let payload = Payload(structure: file.structure.dictionary,
                              syntaxMap: file.syntaxMap.tokens,
                              path: file.path,
                              contents: file.contents,
                              configuration: configuration)
        return validate(payload: payload, file: file)
    }

    private func validate(payload: Payload, file: File) -> [StyleViolation] {
        do {
            let task = Process()
            task.launchPath = executable
            task.arguments = ["lint"]

            let pipe = Pipe()
            task.standardOutput = pipe

            let stdinPipe = Pipe()
            task.standardInput = stdinPipe.fileHandleForReading

            stdinPipe.fileHandleForWriting.writeabilityHandler = { pipeHandle in
                let outputData = (try? payload.asJSONData()) ?? Data()
                stdinPipe.fileHandleForWriting.write(outputData)
                stdinPipe.fileHandleForWriting.writeabilityHandler = nil
                stdinPipe.fileHandleForWriting.closeFile()
            }

            task.launch()

            let pipeFile = pipe.fileHandleForReading
            defer { pipeFile.closeFile() }

            let data = pipeFile.readDataToEndOfFile()
            guard let json = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
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

extension Data {
    func chunks(_ chunkSize: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: chunkSize).map {
            Array(self[$0..<Swift.min($0 + chunkSize, count)])
        }
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
            "syntax_map": syntaxMap.map { $0.dictionaryValue },
        ] as [String: Any]
        json["path"] = path
        json["configuration"] = configuration
        if path == nil {
            json["contents"] = contents
        }

        return json
    }
}
