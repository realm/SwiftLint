import Foundation
import TestHelpers
import Testing
import Yams

@Suite
struct YamlSwiftLintTests {
    @Test
    func flattenYaml() throws {
        guard let yamlDict = try Yams.load(yaml: try getTestYaml()) as? [String: Any] else {
            Issue.record("Failed to load YAML from file")
            return
        }

        let dict1 = (yamlDict["dictionary1"] as? [Swift.String: Any])!
        let dict2 = (yamlDict["dictionary2"] as? [Swift.String: Any])!
        #expect(dict1["bool"] as? Bool == true && dict2["bool"] as? Bool == true)
        #expect(dict1["int"] as? Int == 1 && dict2["int"] as? Int == 1)
        #expect(dict1["double"] as? Double == 1.0 && dict2["double"] as? Double == 1.0)
        #expect(dict1["string"] as? String == "string" && dict2["string"] as? String == "string")

        let array1 = (dict1["array"] as? [Any])!
        let array2 = (dict1["array"] as? [Any])!
        #expect(array1[0] as? Bool == true && array2[0] as? Bool == true)
        #expect(array1[1] as? Int == 1 && array2[1] as? Int == 1)
        #expect(array1[2] as? Double == 1.0 && array2[2] as? Double == 1.0)
        #expect(array1[3] as? String == "string" && array2[3] as? String == "string")

        let dictFromArray1 = (array1[4] as? [Swift.String: Any])!
        let dictFromArray2 = (array2[4] as? [Swift.String: Any])!
        #expect(dictFromArray1["bool"] as? Bool == true && dictFromArray2["bool"] as? Bool == true)
        #expect(dictFromArray1["int"] as? Int == 1 && dictFromArray2["int"] as? Int == 1)
        #expect(dictFromArray1["double"] as? Double == 1.0 && dictFromArray2["double"] as? Double == 1.0)
        #expect(dictFromArray1["string"] as? String == "string" && dictFromArray2["string"] as? String == "string")
    }

    private func getTestYaml() throws -> String {
        try String(contentsOfFile: "\(TestResources.path())/test.yml", encoding: .utf8)
    }
}
