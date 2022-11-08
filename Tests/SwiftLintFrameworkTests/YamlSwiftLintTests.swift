import Foundation
import XCTest
import Yams

class YamlSwiftLintTests: SwiftLintTestCase {
    func testFlattenYaml() throws {
        do {
            guard let yamlDict = try Yams.load(yaml: try getTestYaml()) as? [String: Any] else {
                XCTFail("Failed to load YAML from file")
                return
            }

            let dict1 = (yamlDict["dictionary1"] as? [Swift.String: Any])!
            let dict2 = (yamlDict["dictionary2"] as? [Swift.String: Any])!
            XCTAssertTrue(dict1["bool"] as? Bool == true && dict2["bool"] as? Bool == true)
            XCTAssertTrue(dict1["int"] as? Int == 1 && dict2["int"] as? Int == 1)
            XCTAssertTrue(dict1["double"] as? Double == 1.0 && dict2["double"] as? Double == 1.0)
            XCTAssertTrue(dict1["string"] as? String == "string" &&
                          dict2["string"] as? String == "string")

            let array1 = (dict1["array"] as? [Any])!
            let array2 = (dict1["array"] as? [Any])!
            XCTAssertTrue(array1[0] as? Bool == true && array2[0] as? Bool == true)
            XCTAssertTrue(array1[1] as? Int == 1 && array2[1] as? Int == 1)
            XCTAssertTrue(array1[2] as? Double == 1.0 && array2[2] as? Double == 1.0)
            XCTAssertTrue(array1[3] as? String == "string" && array2[3] as? String == "string")

            let dictFromArray1 = (array1[4] as? [Swift.String: Any])!
            let dictFromArray2 = (array2[4] as? [Swift.String: Any])!
            XCTAssertTrue(dictFromArray1["bool"] as? Bool == true && dictFromArray2["bool"] as? Bool == true)
            XCTAssertTrue(dictFromArray1["int"] as? Int == 1 && dictFromArray2["int"] as? Int == 1)
            XCTAssertTrue(dictFromArray1["double"] as? Double == 1.0 &&
                          dictFromArray2["double"] as? Double == 1.0)
            XCTAssertTrue(dictFromArray1["string"] as? String == "string" &&
                          dictFromArray2["string"] as? String == "string")
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    private func getTestYaml() throws -> String {
        return try String(contentsOfFile: "\(testResourcesPath)/test.yml", encoding: .utf8)
    }
}
