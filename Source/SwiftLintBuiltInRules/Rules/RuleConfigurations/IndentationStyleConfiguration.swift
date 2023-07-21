import SwiftLintCore

struct IndentationStyleConfiguration: SeverityBasedRuleConfiguration, Equatable {
	typealias Parent = IndentationStyleRule

	@ConfigurationElement(key: "severity")
	private(set) var severityConfiguration = SeverityConfiguration<Parent>.warning
	@ConfigurationElement(key: "include_multiline_strings")
	private(set) var includeMultilineStrings = false
	@ConfigurationElement(key: "per_file")
	private(set) var perFile = true
	@ConfigurationElement(key: "preferred_style")
	private(set) var preferredStyle = PreferredStyle.spaces
	@ConfigurationElement(key: "tab_width")
	private(set) var tabWidth: Int?

	static let testTabWidth: [String: Any] = ["tab_width": 4]

	enum PreferredStyle: String, AcceptableByConfigurationElement {
		case tabs
		case spaces

		func asOption() -> OptionType {
			.string(rawValue)
		}
	}

	mutating func apply(configuration: Any) throws {
		guard let configurationDict = configuration as? [String: Any] else {
			throw Issue.unknownConfiguration(ruleID: Parent.identifier)
		}

		if let config = configurationDict[$severityConfiguration] {
			try severityConfiguration.apply(configuration: config)
		}

		if let perFile = configurationDict[$perFile] as? Bool {
			self.perFile = perFile
		}

		if perFile == false {
			if let preferredStyle = configurationDict[$preferredStyle] as? String {
				self.preferredStyle = PreferredStyle(rawValue: preferredStyle) ?? .spaces
			}
		}

		if let includeMultilineStrings = configurationDict[$includeMultilineStrings] as? Bool {
			self.includeMultilineStrings = includeMultilineStrings
		}

		self.tabWidth = configurationDict[$tabWidth] as? Int
	}
}
