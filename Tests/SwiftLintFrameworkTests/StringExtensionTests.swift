import XCTest

final class StringExtensionTests: SwiftLintTestCase {
    func testRelativePathExpression() {
        XCTAssertEqual("Folder/Test", "Root/Folder/Test".path(relativeTo: "Root"))
        XCTAssertEqual("Test", "Root/Folder/Test".path(relativeTo: "Root/Folder"))
        XCTAssertEqual("", "Root/Folder/Test".path(relativeTo: "Root/Folder/Test"))
        XCTAssertEqual("../Test", "Root/Folder/Test".path(relativeTo: "Root/Folder/SubFolder"))
        XCTAssertEqual("../..", "Root".path(relativeTo: "Root/Folder/SubFolder"))
        XCTAssertEqual("../../OtherFolder/Test", "Root/OtherFolder/Test".path(relativeTo: "Root/Folder/SubFolder"))
        XCTAssertEqual("../MyFolder123", "Folder/MyFolder123".path(relativeTo: "Folder/MyFolder"))
        XCTAssertEqual("../MyFolder123", "Folder/MyFolder123".path(relativeTo: "Folder/MyFolder/"))
        XCTAssertEqual("Test", "Root////Folder///Test/".path(relativeTo: "Root//Folder////"))
        XCTAssertEqual("Root/Folder/Test", "Root/Folder/Test/".path(relativeTo: ""))
    }
}
