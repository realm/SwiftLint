import ArgumentParser
import SwiftLintFramework
import SwiftyTextTable

extension SwiftLint {
    struct Reporters: ParsableCommand {
        static let configuration = CommandConfiguration(abstract: "Display the list of reporters and their identifiers")

        private static let reporters: [Reporter.Type] = [
            XcodeReporter.self,
            JSONReporter.self,
            CSVReporter.self,
            CheckstyleReporter.self,
            CodeClimateReporter.self,
            JUnitReporter.self,
            HTMLReporter.self,
            EmojiReporter.self,
            SonarQubeReporter.self,
            MarkdownReporter.self,
            GitHubActionsLoggingReporter.self,
            GitLabJUnitReporter.self,
            RelativePathReporter.self
        ]

        func run() throws {
            print(TextTable(reporters: Self.reporters).render())
            ExitHelper.successfullyExit()
        }
    }
}

// MARK: - SwiftyTextTable

private extension TextTable {
    init(reporters: [Reporter.Type]) {
        let columns = [
            TextTableColumn(header: "identifier"),
            TextTableColumn(header: "description")
        ]
        self.init(columns: columns)
        for reporter in reporters {
            addRow(values: [
                reporter.identifier,
                reporter.description
            ])
        }
    }
}
