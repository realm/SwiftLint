import Foundation
import SourceKittenFramework
import SwiftLintFramework

extension SwiftLintFile {
    static func temporary(withContents contents: String) -> SwiftLintFile {
        let url = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("swift")
        _ = try? contents.data(using: .utf8)!.write(to: url)
        return SwiftLintFile(path: url.path)!
    }

    func makeCompilerArguments() -> [String] {
        return ["-sdk", sdkPath(), "-j4", path!]
    }
}
