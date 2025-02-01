import SwiftLintCore
import Testing

@Suite
struct AccessControlLevelTests {
    @Test
    func description() {
        #expect(AccessControlLevel.private.description == "private")
        #expect(AccessControlLevel.fileprivate.description == "fileprivate")
        #expect(AccessControlLevel.internal.description == "internal")
        #expect(AccessControlLevel.package.description == "package")
        #expect(AccessControlLevel.public.description == "public")
        #expect(AccessControlLevel.open.description == "open")
    }

    @Test
    func priority() {
        #expect(AccessControlLevel.private < .fileprivate)
        #expect(AccessControlLevel.fileprivate < .internal)
        #expect(AccessControlLevel.internal < .package)
        #expect(AccessControlLevel.package < .public)
        #expect(AccessControlLevel.public < .open)
    }
}
