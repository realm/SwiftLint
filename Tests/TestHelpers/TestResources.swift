import Foundation
import SwiftLintCore

public enum TestResources {
    public static func path(_ calleePath: String = #filePath) -> URL {
        let folder = URL(fileURLWithPath: calleePath, isDirectory: false).deletingLastPathComponent()
        if let rootProjectDirectory = ProcessInfo.processInfo.environment["BUILD_WORKSPACE_DIRECTORY"] {
            return URL(fileURLWithPath: rootProjectDirectory, isDirectory: true)
                .appendingPathComponent("Tests", isDirectory: true)
                .appendingPathComponent(folder.lastPathComponent, isDirectory: true)
                .appendingPathComponent("Resources", isDirectory: true)
        }
        return folder
            .appendingPathComponent("Resources")
            .resolvingSymlinksInPath()
    }
}
