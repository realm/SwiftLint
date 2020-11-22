@testable import SwiftLintFramework
import XCTest

final class StringExtensionTests: XCTestCase {
    func testRelativePathExpression() {
        XCTAssertEqual("Folder/Test", "Root/Folder/Test".path(relativeTo: "Root"))
        XCTAssertEqual("Test", "Root/Folder/Test".path(relativeTo: "Root/Folder"))
        XCTAssertEqual("", "Root/Folder/Test".path(relativeTo: "Root/Folder/Test"))
        XCTAssertEqual("../Test", "Root/Folder/Test".path(relativeTo: "Root/Folder/SubFolder"))
        XCTAssertEqual("../..", "Root".path(relativeTo: "Root/Folder/SubFolder"))
        XCTAssertEqual("../../OtherFolder/Test", "Root/OtherFolder/Test".path(relativeTo: "Root/Folder/SubFolder"))
    }
}
