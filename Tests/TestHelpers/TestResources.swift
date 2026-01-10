import Foundation
import SwiftLintCore

public enum TestResources {
    public static func path(_ calleePath: String = #filePath) -> URL {
        let folder = calleePath.url(directoryHint: .notDirectory).deletingLastPathComponent()
        if let rootProjectDirectory = ProcessInfo.processInfo.environment["BUILD_WORKSPACE_DIRECTORY"] {
            return rootProjectDirectory.url(directoryHint: .isDirectory)
                .appending(path: "Tests", directoryHint: .isDirectory)
                .appending(path: folder.lastPathComponent, directoryHint: .isDirectory)
                .appending(path: "Resources", directoryHint: .isDirectory)
        }
        return folder
            .appending(path: "Resources", directoryHint: .isDirectory)
            .resolvingSymlinksInPath()
    }
}
