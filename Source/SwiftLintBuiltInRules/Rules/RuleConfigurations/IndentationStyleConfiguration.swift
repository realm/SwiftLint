import SwiftLintCore

struct IndentationStyleConfiguration: SeverityBasedRuleConfiguration, Equatable {
	typealias Parent = IndentationStyleRule

	@ConfigurationElement(key: "severity")
	private(set) var severityConfiguration = SeverityConfiguration<Parent>.warning
	@ConfigurationElement(key: "include_multiline_strings")
	private(set) var includeMultilineStrings = false
	@ConfigurationElement(key: "include_multiline_comments")
	private(set) var includeMultilineComments = true
	@ConfigurationElement(key: "per_file")
	private(set) var perFile = true
	@ConfigurationElement(key: "preferred_style")
	private(set) var preferredStyle = PreferredStyle.spaces
	/// Checks to make sure that in tab mode indentation, any spaces are only at the end and are, at most, tabWidth-1
	/// in quantity, if tabWidth is set.
	@ConfigurationElement(key: "tab_width")
	private(set) var tabWidth: Int?

	static let testTabWidth: [String: any Sendable] = ["tab_width": 4]
	static let testMultilineString: [String: any Sendable] = ["include_multiline_strings": true]
	static let testMultilineComment: [String: any Sendable] = ["include_multiline_comments": false]

	@MakeAcceptableByConfigurationElement
	enum PreferredStyle: String {
		case tabs
		case spaces
	}

	mutating func apply(configuration: Any) throws {
		guard let configurationDict = configuration as? [String: Any] else {
			throw Issue.unknownConfiguration(ruleID: Parent.identifier)
		}

		if let config = configurationDict[$severityConfiguration.key] {
			try severityConfiguration.apply(configuration: config)
		}

		if let perFile = configurationDict[$perFile.key] as? Bool {
			self.perFile = perFile
		}

		if perFile == false {
			if let preferredStyle = configurationDict[$preferredStyle.key] as? String {
				self.preferredStyle = PreferredStyle(rawValue: preferredStyle) ?? .spaces
			}
		}

		if let includeMultilineStrings = configurationDict[$includeMultilineStrings.key] as? Bool {
			self.includeMultilineStrings = includeMultilineStrings
		}

		if let includeMultilineComments = configurationDict[$includeMultilineComments.key] as? Bool {
			self.includeMultilineComments = includeMultilineComments
		}

		self.tabWidth = configurationDict[$tabWidth.key] as? Int
	}
}
