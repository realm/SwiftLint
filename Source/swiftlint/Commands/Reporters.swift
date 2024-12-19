import ArgumentParser
import SwiftLintFramework
import SwiftyTextTable

extension SwiftLint {
    struct Reporters: ParsableCommand {
        static let configuration = CommandConfiguration(abstract: "Display the list of reporters and their identifiers")

        func run() throws {
            print(TextTable(reporters: reportersList).render())
        }
    }
}

// MARK: - SwiftyTextTable

private extension TextTable {
    init(reporters: [any Reporter.Type]) {
        let columns = [
            TextTableColumn(header: "identifier"),
            TextTableColumn(header: "description"),
        ]
        self.init(columns: columns)
        for reporter in reporters {
            addRow(values: [
                reporter.identifier,
                reporter.description,
            ])
        }
    }
}
