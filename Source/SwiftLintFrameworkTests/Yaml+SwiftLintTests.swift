//
//  Yaml+SwiftLintTests.swift
//  SwiftLint
//
//  Created by Scott Hoyt on 12/28/15.
//  Copyright © 2015 Realm. All rights reserved.
//

import XCTest
import Yaml
@testable import SwiftLintFramework

class YamlSwiftLintTests: XCTestCase {

    func testFlattenYaml() {
        let yamlResult = Yaml.load(getTestYaml())
        if let error = yamlResult.error {
            XCTFail(error)
        } else {
            let yaml = yamlResult.value!
            let yamlDict = yaml.flatDictionary!

            let dict1 = (yamlDict["dictionary1"] as? [Swift.String : AnyObject])!
            let dict2 = (yamlDict["dictionary2"] as? [Swift.String : AnyObject])!
            XCTAssertTrue(dict1["nothing"] as? NSNull == NSNull() &&
                          dict2["nothing"] as? NSNull == NSNull())
            XCTAssertTrue(dict1["bool"] as? Bool == true && dict2["bool"] as? Bool == true)
            XCTAssertTrue(dict1["int"] as? Int == 1 && dict2["int"] as? Int == 1)
            XCTAssertTrue(dict1["double"] as? Double == 1.0 && dict2["double"] as? Double == 1.0)
            XCTAssertTrue(dict1["string"] as? String == "string" &&
                          dict2["string"] as? String == "string")

            let array1 = (dict1["array"] as? [AnyObject])!
            let array2 = (dict1["array"] as? [AnyObject])!
            XCTAssertTrue(array1[0] as? Bool == true && array2[0] as? Bool == true)
            XCTAssertTrue(array1[1] as? Int == 1 && array2[1] as? Int == 1)
            XCTAssertTrue(array1[2] as? Double == 1.0 && array2[2] as? Double == 1.0)
            XCTAssertTrue(array1[3] as? String == "string" && array2[3] as? String == "string")

            let dict1_1 = (array1[4] as? [Swift.String: AnyObject])!
            let dict2_2 = (array2[4] as? [Swift.String: AnyObject])!
            XCTAssertTrue(dict1_1["bool"] as? Bool == true && dict2_2["bool"] as? Bool == true)
            XCTAssertTrue(dict1_1["int"] as? Int == 1 && dict2_2["int"] as? Int == 1)
            XCTAssertTrue(dict1_1["double"] as? Double == 1.0 &&
                          dict2_2["double"] as? Double == 1.0)
            XCTAssertTrue(dict1_1["string"] as? String == "string" &&
                          dict2_2["string"] as? String == "string")
        }
    }

    func testStringValues() {
        XCTAssertEqual(Yaml.Bool(true).stringValue, "true")
        XCTAssertEqual(Yaml.Int(4).stringValue, "4")
        XCTAssertEqual(Yaml.Double(4.4).stringValue, "4.4")
        XCTAssertEqual(Yaml.String("string").stringValue, "string")
        XCTAssertEqual(Yaml.Array([Yaml.Int(4), Yaml.String("string")]).stringValue, "[4, string]")
        XCTAssertEqual(Yaml.Dictionary([Yaml.Int(4): Yaml.String("string")]).stringValue,
                       "[\"4\": string]")
        XCTAssertEqual(Yaml.Null.stringValue, "Null")
    }

    // MARK: - Utilities

    func getTestYaml() -> String {
        let testBundle = NSBundle(forClass: self.dynamicType)
        if let path = testBundle.pathForResource("test", ofType: "yml"),
           let ymlString = try? String(contentsOfFile: path) {
            return ymlString
        }
        fatalError("Could not load test.yml")
    }

}
