import Foundation

public enum TestResources {
    public static func path(_ calleePath: String = #filePath) -> String {
        let folder = URL(fileURLWithPath: calleePath, isDirectory: false).deletingLastPathComponent()
        if let rootProjectDirectory = ProcessInfo.processInfo.environment["BUILD_WORKSPACE_DIRECTORY"] {
            return "\(rootProjectDirectory)/Tests/\(folder.lastPathComponent)/Resources"
        }
        return folder
            .appendingPathComponent("Resources")
            .path
            .absolutePathStandardized()
    }
}
