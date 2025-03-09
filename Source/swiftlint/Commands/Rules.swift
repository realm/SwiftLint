import ArgumentParser
import Foundation
import SwiftLintFramework
import SwiftyTextTable

private typealias SortedRules = [(String, any Rule.Type)]

extension SwiftLint {
  struct Rules: ParsableCommand {
    static let configuration = CommandConfiguration(
      abstract: "Display the list of rules and their identifiers")

    @Option(help: "The path to a SwiftLint configuration file")
    var config: String?
    @OptionGroup
    var rulesFilterOptions: RulesFilterOptions
    @Flag(name: .shortAndLong, help: "Display full configuration details")
    var verbose = false
    @Flag(help: "Print only the YAML configuration(s)")
    var configOnly = false
    @Flag(help: "Print default configuration(s)")
    var defaultConfig = false
    @Argument(help: "The rule identifier to display description for")
    var ruleID: String?
    @Flag(name: .shortAndLong, help: "Display output as JSON")
    var json = false

    mutating func validate() throws {
      if json {
        if verbose {
          throw ValidationError("The `--verbose` and `--json` flags are mutually exclusive")
        }
        if configOnly {
          throw ValidationError("The `--config-only` and `--json` flags are mutually exclusive")
        }
        if ruleID != nil {
          throw ValidationError("The `--json` cannot be used with a `rule-id`")
        }
      }
    }

    func run() throws {
      let configuration = Configuration(configurationFiles: [config].compactMap({ $0 }))
      if let ruleID {
        guard let rule = RuleRegistry.shared.rule(forID: ruleID) else {
          throw SwiftLintError.usageError(description: "No rule with identifier: \(ruleID)")
        }
        printDescription(for: rule, with: configuration)
        return
      }
      let rules = RulesFilter(enabledRules: configuration.rules)
        .getRules(excluding: rulesFilterOptions.excludingOptions)
        .list
        .sorted { $0.0 < $1.0 }
      if configOnly {
        rules.forEach { printConfig(for: createInstance(of: $0.value, using: configuration)) }
      } else {
        guard !json else {
          let serializableRules = rules.map { ruleID, ruleType in
            let rType = ruleType.init()
            let rule = createInstance(of: ruleType, using: configuration)
            let configuredRule = configuration.configuredRule(forID: ruleID)
            return EncodableRule(
              identifier: ruleID,
              optIn: rule is any OptInRule,
              correctable: rule is any CorrectableRule,
              enabled: configuredRule != nil,
              kind: ruleType.description.kind.rawValue,
              analyzer: rule is any AnalyzerRule,
              usesSourcekit: rule is any SourceKitFreeRule,
              configuration: (defaultConfig ? rType : configuredRule ?? rType)
                .createConfigurationDescription()
            )
          }
          let encoder = JSONEncoder()
          encoder.outputFormatting = [.sortedKeys, .prettyPrinted]
          let data = try encoder.encode(serializableRules)
          print(String(data: data, encoding: .utf8)!)
          return
        }
        let table = TextTable(
          ruleList: rules,
          configuration: configuration,
          verbose: verbose,
          defaultConfig: defaultConfig
        )
        print(table.render())
      }
    }

    private func printDescription(for ruleType: any Rule.Type, with configuration: Configuration) {
      let description = ruleType.description

      let rule = createInstance(of: ruleType, using: configuration)
      if configOnly {
        printConfig(for: rule)
        return
      }

      print("\(description.consoleDescription)")
      if let consoleRationale = description.consoleRationale {
        print("\nRationale:\n\n\(consoleRationale)")
      }
      let configDescription = rule.createConfigurationDescription()
      if configDescription.hasContent {
        print("\nConfiguration (YAML):\n")
        print("  \(description.identifier):")
        print(configDescription.yaml().indent(by: 4))
      }

      guard description.triggeringExamples.isNotEmpty else { return }

      print("\nTriggering Examples (violations are marked with '↓'):")
      for (index, example) in description.triggeringExamples.enumerated() {
        print("\nExample #\(index + 1)\n\n\(example.code.indent(by: 4))")
      }
    }

    private func printConfig(for rule: some Rule) {
      let configDescription = rule.createConfigurationDescription()
      if configDescription.hasContent {
        print("\(type(of: rule).identifier):")
        print(configDescription.yaml().indent(by: 2))
      }
    }

    private func createInstance(of ruleType: any Rule.Type, using config: Configuration) -> any Rule
    {
      defaultConfig
        ? ruleType.init()
        : config.configuredRule(forID: ruleType.identifier) ?? ruleType.init()
    }
  }
}

// MARK: - SwiftyTextTable

extension TextTable {
  fileprivate init(
    ruleList: SortedRules, configuration: Configuration, verbose: Bool, defaultConfig: Bool
  ) {
    let columns = [
      TextTableColumn(header: "identifier"),
      TextTableColumn(header: "opt-in"),
      TextTableColumn(header: "correctable"),
      TextTableColumn(header: "enabled in your config"),
      TextTableColumn(header: "kind"),
      TextTableColumn(header: "analyzer"),
      TextTableColumn(header: "uses sourcekit"),
      TextTableColumn(header: "configuration"),
    ]
    self.init(columns: columns)
    func truncate(_ string: String) -> String {
      let stringWithNoNewlines = string.replacingOccurrences(of: "\n", with: "\\n")
      let minWidth = "configuration".count - "...".count
      let configurationStartColumn = 140
      let maxWidth = verbose ? Int.max : Terminal.currentWidth()
      let truncatedEndIndex = stringWithNoNewlines.index(
        stringWithNoNewlines.startIndex,
        offsetBy: max(minWidth, maxWidth - configurationStartColumn),
        limitedBy: stringWithNoNewlines.endIndex
      )
      if let truncatedEndIndex {
        return stringWithNoNewlines[..<truncatedEndIndex] + "..."
      }
      return stringWithNoNewlines
    }
    for (ruleID, ruleType) in ruleList {
      let rule = ruleType.init()
      let configuredRule = configuration.configuredRule(forID: ruleID)
      addRow(values: [
        ruleID,
        (rule is any OptInRule) ? "yes" : "no",
        (rule is any CorrectableRule) ? "yes" : "no",
        configuredRule != nil ? "yes" : "no",
        ruleType.description.kind.rawValue,
        (rule is any AnalyzerRule) ? "yes" : "no",
        (rule is any SourceKitFreeRule) ? "no" : "yes",
        truncate(
          (defaultConfig ? rule : configuredRule ?? rule).createConfigurationDescription()
            .oneLiner()),
      ])
    }
  }
}

private struct Terminal {
  static func currentWidth() -> Int {
    var size = winsize()
    #if os(Linux)
      _ = ioctl(CInt(STDOUT_FILENO), UInt(TIOCGWINSZ), &size)
    #else
      _ = ioctl(STDOUT_FILENO, TIOCGWINSZ, &size)
    #endif
    return Int(size.ws_col)
  }
}

private struct EncodableRule: Encodable {
  let identifier: String
  let optIn: Bool
  let correctable: Bool
  let enabled: Bool
  let kind: String
  let analyzer: Bool
  let usesSourcekit: Bool
  let configuration: RuleConfigurationDescription
}
