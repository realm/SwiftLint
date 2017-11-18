//
//  DocumentationTests.swift
//  SwiftLint
//
//  Created by Marcelo Fabri on 08/24/17.
//  Copyright © 2017 Realm. All rights reserved.
//

import Foundation
import SwiftLintFramework
import XCTest

private let projectRoot = #file.bridge()
    .deletingLastPathComponent.bridge()
    .deletingLastPathComponent.bridge()
    .deletingLastPathComponent

class DocumentationTests: XCTestCase {
    // sourcery:skipTestOnLinux
    func testRulesDocumentationIsUpdated() throws {
        let docsPath = "\(projectRoot)/Rules.md"
        let existingDocs = try String(contentsOfFile: docsPath)
        let updatedDocs = masterRuleList.generateDocumentation()

        XCTAssertEqual(existingDocs, updatedDocs)

        if existingDocs != updatedDocs {
            // Overwrite Rules.md with latest version
            try updatedDocs.data(using: .utf8)?.write(to: URL(fileURLWithPath: docsPath))
        }
    }
}
