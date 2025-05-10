// swiftlint:disable file_header
//
// Adapted from periphery's UpdateChecker.swift
//
// https://github.com/peripheryapp/periphery
//
// Copyright (c) 2019 Ian Leitch
// Licensed under the MIT License
//
// See https://github.com/peripheryapp/periphery/blob/master/LICENSE.md for license information
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

package enum UpdateChecker {
    package static func checkForUpdates() async {
        guard let url = URL(string: "https://api.github.com/repos/realm/SwiftLint/releases/latest"),
              let data = try? await sendRequest(to: url),
              let latestVersionNumber = parseVersionNumber(data) else {
            print("Could not check latest SwiftLint version")
            return
        }

        let latestVersion = SwiftLintFramework.Version(value: latestVersionNumber)
        if latestVersion > SwiftLintFramework.Version.current {
            print("A new version of SwiftLint is available: \(latestVersionNumber)")
        } else {
            print("Your version of SwiftLint is up to date.")
        }
    }

    private static func parseVersionNumber(_ data: Data) -> String? {
        guard let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []) as? [AnyHashable: Any] else {
            return nil
        }
        return jsonObject["tag_name"] as? String
    }

    private static func sendRequest(to url: URL) async throws -> Data {
        var request = URLRequest(url: url)
        request.setValue("SwiftLint", forHTTPHeaderField: "User-Agent")
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        return try await URLSession.shared.data(for: request).0
    }
}
