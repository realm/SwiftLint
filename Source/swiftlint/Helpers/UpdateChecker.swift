import Foundation
import SwiftLintFramework

enum UpdateChecker {
    static func checkForUpdates() {
        guard let url = URL(string: "https://api.github.com/repos/realm/SwiftLint/releases/latest") else {
            return
        }
        guard let data = sendSynchronousRequest(to: url) else {
            return
        }
        guard let latestVersionNumber = parseVersionNumber(data) else {
            return
        }
        let latestVersion = SwiftLintFramework.Version(value: latestVersionNumber)
        if latestVersion > SwiftLintFramework.Version.current {
            print("A new version of SwiftLint is available: \(latestVersionNumber)")
        } else {
            print("Your version of SwiftLint is up to date")
        }
    }

    private static func parseVersionNumber(_ data: Data) -> String? {
        guard let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []) as? [AnyHashable: Any],
              let tagName = jsonObject["tag_name"] as? String else {
            return nil
        }
        return tagName
    }

    private static func sendSynchronousRequest(to url: URL) -> Data? {
        var request = URLRequest(url: url)
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        let semaphore = DispatchSemaphore(value: 0)
        var result: Data?

        let task = URLSession.shared.dataTask(with: request) { data, _, _ in
            result = data
            semaphore.signal()
        }
        task.resume()

        semaphore.wait()
        return result
    }
}
