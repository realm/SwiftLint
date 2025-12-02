import Foundation
import SwiftLintCore

public enum TestResources {
    public static func path(_ calleePath: String = #filePath) -> URL {
        let folder = URL(fileURLWithPath: calleePath, isDirectory: false).deletingLastPathComponent()
        if let rootProjectDirectory = ProcessInfo.processInfo.environment["BUILD_WORKSPACE_DIRECTORY"] {
            return URL(
                fileURLWithPath: "\(rootProjectDirectory)/Tests/\(folder.lastPathComponent)/Resources",
                isDirectory: true)
        }
        return folder
            .appendingPathComponent("Resources")
            .resolvingSymlinksInPath()
    }
}
