import Testing

@testable import SwiftLintFramework

@Suite(.serialized, .rulesRegistered)
struct FileSystemAccessTestSuite {
    struct BaselineTests {}
    struct ConfigurationTests {
        init() {
            Configuration.resetCache()
        }
    }
    struct GlobTests {}
    struct ReporterTests {}
    struct SourceKitCrashTests {}
}
