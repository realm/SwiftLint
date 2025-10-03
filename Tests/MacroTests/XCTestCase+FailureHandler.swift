import SwiftSyntaxMacrosGenericTestSupport
import TestHelpers
import XCTest

extension XCTestCase {
    func failureHandler(_ spec: TestFailureSpec) {
        spec.location.filePath.withStaticString { filePath in
            XCTFail(
                spec.message,
                file: filePath,
                line: UInt(spec.location.line),
            )
        }
    }
}
