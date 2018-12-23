import Foundation
@testable import SwiftLintFramework
import XCTest

private let projectRoot = #file.bridge()
    .deletingLastPathComponent.bridge()
    .deletingLastPathComponent.bridge()
    .deletingLastPathComponent

class DocumentationTests: XCTestCase {
    func testRulesDocumentationIsUpdated() throws {
        guard SwiftVersion.current >= .fourDotOne else {
            return
        }

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
