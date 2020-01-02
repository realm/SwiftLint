// Generated using Sourcery 0.17.0 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

@testable import SwiftLintFrameworkTests
import XCTest

// swiftlint:disable line_length file_length

extension AnyObjectProtocolRuleTests {
    static var allTests: [(String, (AnyObjectProtocolRuleTests) -> () throws -> Void)] = [
        ("testWithDefaultConfiguration", testWithDefaultConfiguration)
    ]
}

extension ArrayInitRuleTests {
    static var allTests: [(String, (ArrayInitRuleTests) -> () throws -> Void)] = [
        ("testWithDefaultConfiguration", testWithDefaultConfiguration)
    ]
}

extension AttributesRuleTests {
    static var allTests: [(String, (AttributesRuleTests) -> () throws -> Void)] = [
        ("testAttributesWithDefaultConfiguration", testAttributesWithDefaultConfiguration),
        ("testAttributesWithAlwaysOnSameLine", testAttributesWithAlwaysOnSameLine),
        ("testAttributesWithAlwaysOnLineAbove", testAttributesWithAlwaysOnLineAbove),
        ("testAttributesWithAttributesOnLineAboveButOnOtherDeclaration", testAttributesWithAttributesOnLineAboveButOnOtherDeclaration)
    ]
}

extension BlockBasedKVORuleTests {
    static var allTests: [(String, (BlockBasedKVORuleTests) -> () throws -> Void)] = [
        ("testWithDefaultConfiguration", testWithDefaultConfiguration)
    ]
}

extension ClassDelegateProtocolRuleTests {
    static var allTests: [(String, (ClassDelegateProtocolRuleTests) -> () throws -> Void)] = [
        ("testWithDefaultConfiguration", testWithDefaultConfiguration)
    ]
}

extension ClosingBraceRuleTests {
    static var allTests: [(String, (ClosingBraceRuleTests) -> () throws -> Void)] = [
        ("testWithDefaultConfiguration", testWithDefaultConfiguration)
    ]
}

extension ClosureBodyLengthRuleTests {
    static var allTests: [(String, (ClosureBodyLengthRuleTests) -> () throws -> Void)] = [
        ("testWithDefaultConfiguration", testWithDefaultConfiguration)
    ]
}

extension ClosureEndIndentationRuleTests {
    static var allTests: [(String, (ClosureEndIndentationRuleTests) -> () throws -> Void)] = [
        ("testWithDefaultConfiguration", testWithDefaultConfiguration)
    ]
}

extension ClosureParameterPositionRuleTests {
    static var allTests: [(String, (ClosureParameterPositionRuleTests) -> () throws -> Void)] = [
        ("testWithDefaultConfiguration", testWithDefaultConfiguration)
    ]
}

extension ClosureSpacingRuleTests {
    static var allTests: [(String, (ClosureSpacingRuleTests) -> () throws -> Void)] = [
        ("testWithDefaultConfiguration", testWithDefaultConfiguration)
    ]
}

extension CollectingRuleTests {
    static var allTests: [(String, (CollectingRuleTests) -> () throws -> Void)] = [
        ("testCollectsIntoStorage", testCollectsIntoStorage),
        ("testCollectsAllFiles", testCollectsAllFiles),
        ("testCollectsAnalyzerFiles", testCollectsAnalyzerFiles),
        ("testCorrects", testCorrects)
    ]
}

extension CollectionAlignmentRuleTests {
    static var allTests: [(String, (CollectionAlignmentRuleTests) -> () throws -> Void)] = [
        ("testWithDefaultConfiguration", testWithDefaultConfiguration),
        ("testCollectionAlignmentWithAlignLeft", testCollectionAlignmentWithAlignLeft),
        ("testCollectionAlignmentWithAlignColons", testCollectionAlignmentWithAlignColons)
    ]
}

extension ColonRuleTests {
    static var allTests: [(String, (ColonRuleTests) -> () throws -> Void)] = [
        ("testColonWithDefaultConfiguration", testColonWithDefaultConfiguration),
        ("testColonWithFlexibleRightSpace", testColonWithFlexibleRightSpace),
        ("testColonWithoutApplyToDictionaries", testColonWithoutApplyToDictionaries)
    ]
}

extension CommaRuleTests {
    static var allTests: [(String, (CommaRuleTests) -> () throws -> Void)] = [
        ("testWithDefaultConfiguration", testWithDefaultConfiguration)
    ]
}

extension CommandTests {
    static var allTests: [(String, (CommandTests) -> () throws -> Void)] = [
        ("testNoCommandsInEmptyFile", testNoCommandsInEmptyFile),
        ("testEmptyString", testEmptyString),
        ("testDisable", testDisable),
        ("testDisablePrevious", testDisablePrevious),
        ("testDisableThis", testDisableThis),
        ("testDisableNext", testDisableNext),
        ("testEnable", testEnable),
        ("testEnablePrevious", testEnablePrevious),
        ("testEnableThis", testEnableThis),
        ("testEnableNext", testEnableNext),
        ("testTrailingCOmment", testTrailingCOmment),
        ("testActionInverse", testActionInverse),
        ("testNoModifierCommandExpandsToItself", testNoModifierCommandExpandsToItself),
        ("testExpandPreviousCommand", testExpandPreviousCommand),
        ("testExpandThisCommand", testExpandThisCommand),
        ("testExpandNextCommand", testExpandNextCommand),
        ("testSuperfluousDisableCommands", testSuperfluousDisableCommands),
        ("testDisableAllOverridesSuperfluousDisableCommand", testDisableAllOverridesSuperfluousDisableCommand),
        ("testSuperfluousDisableCommandsIgnoreDelimiter", testSuperfluousDisableCommandsIgnoreDelimiter),
        ("testInvalidDisableCommands", testInvalidDisableCommands),
        ("testSuperfluousDisableCommandsDisabled", testSuperfluousDisableCommandsDisabled),
        ("testSuperfluousDisableCommandsDisabledOnConfiguration", testSuperfluousDisableCommandsDisabledOnConfiguration)
    ]
}

extension CompilerProtocolInitRuleTests {
    static var allTests: [(String, (CompilerProtocolInitRuleTests) -> () throws -> Void)] = [
        ("testWithDefaultConfiguration", testWithDefaultConfiguration),
        ("testViolationMessageForExpressibleByIntegerLiteral", testViolationMessageForExpressibleByIntegerLiteral)
    ]
}

extension ConditionalReturnsOnNewlineRuleTests {
    static var allTests: [(String, (ConditionalReturnsOnNewlineRuleTests) -> () throws -> Void)] = [
        ("testConditionalReturnsOnNewlineWithDefaultConfiguration", testConditionalReturnsOnNewlineWithDefaultConfiguration),
        ("testConditionalReturnsOnNewlineWithIfOnly", testConditionalReturnsOnNewlineWithIfOnly)
    ]
}

extension ConfigurationAliasesTests {
    static var allTests: [(String, (ConfigurationAliasesTests) -> () throws -> Void)] = [
        ("testConfiguresCorrectlyFromDeprecatedAlias", testConfiguresCorrectlyFromDeprecatedAlias),
        ("testReturnsNilWithDuplicatedConfiguration", testReturnsNilWithDuplicatedConfiguration),
        ("testInitsFromDeprecatedAlias", testInitsFromDeprecatedAlias),
        ("testWhitelistRulesFromDeprecatedAlias", testWhitelistRulesFromDeprecatedAlias),
        ("testDisabledRulesFromDeprecatedAlias", testDisabledRulesFromDeprecatedAlias)
    ]
}

extension ConfigurationTests {
    static var allTests: [(String, (ConfigurationTests) -> () throws -> Void)] = [
        ("testInit", testInit),
        ("testEmptyConfiguration", testEmptyConfiguration),
        ("testInitWithRelativePathAndRootPath", testInitWithRelativePathAndRootPath),
        ("testEnableAllRulesConfiguration", testEnableAllRulesConfiguration),
        ("testWhitelistRules", testWhitelistRules),
        ("testWarningThreshold_value", testWarningThreshold_value),
        ("testWarningThreshold_nil", testWarningThreshold_nil),
        ("testOtherRuleConfigurationsAlongsideWhitelistRules", testOtherRuleConfigurationsAlongsideWhitelistRules),
        ("testDisabledRules", testDisabledRules),
        ("testDisabledRulesWithUnknownRule", testDisabledRulesWithUnknownRule),
        ("testDuplicatedRules", testDuplicatedRules),
        ("testExcludedPaths", testExcludedPaths),
        ("testForceExcludesFile", testForceExcludesFile),
        ("testForceExcludesFileNotPresentInExcluded", testForceExcludesFileNotPresentInExcluded),
        ("testForceExcludesDirectory", testForceExcludesDirectory),
        ("testForceExcludesDirectoryThatIsNotInExcludedButHasChildrenThatAre", testForceExcludesDirectoryThatIsNotInExcludedButHasChildrenThatAre),
        ("testLintablePaths", testLintablePaths),
        ("testGlobExcludePaths", testGlobExcludePaths),
        ("testIsEqualTo", testIsEqualTo),
        ("testIsNotEqualTo", testIsNotEqualTo),
        ("testCustomConfiguration", testCustomConfiguration),
        ("testConfigurationWithSwiftFileAsRoot", testConfigurationWithSwiftFileAsRoot),
        ("testConfigurationWithSwiftFileAsRootAndCustomConfiguration", testConfigurationWithSwiftFileAsRootAndCustomConfiguration),
        ("testIndentationTabs", testIndentationTabs),
        ("testIndentationSpaces", testIndentationSpaces),
        ("testIndentationFallback", testIndentationFallback),
        ("testConfiguresCorrectlyFromDict", testConfiguresCorrectlyFromDict),
        ("testConfigureFallsBackCorrectly", testConfigureFallsBackCorrectly),
        ("testMerge", testMerge),
        ("testLevel0", testLevel0),
        ("testLevel1", testLevel1),
        ("testLevel2", testLevel2),
        ("testLevel3", testLevel3),
        ("testNestedConfigurationWithCustomRootPath", testNestedConfigurationWithCustomRootPath),
        ("testMergedWarningThreshold", testMergedWarningThreshold),
        ("testNestedWhitelistedRules", testNestedWhitelistedRules),
        ("testNestedConfigurationsWithCustomRulesMerge", testNestedConfigurationsWithCustomRulesMerge),
        ("testNestedConfigurationAllowsDisablingParentsCustomRules", testNestedConfigurationAllowsDisablingParentsCustomRules)
    ]
}

extension ContainsOverFilterCountRuleTests {
    static var allTests: [(String, (ContainsOverFilterCountRuleTests) -> () throws -> Void)] = [
        ("testWithDefaultConfiguration", testWithDefaultConfiguration)
    ]
}

extension ContainsOverFilterIsEmptyRuleTests {
    static var allTests: [(String, (ContainsOverFilterIsEmptyRuleTests) -> () throws -> Void)] = [
        ("testWithDefaultConfiguration", testWithDefaultConfiguration)
    ]
}

extension ContainsOverFirstNotNilRuleTests {
    static var allTests: [(String, (ContainsOverFirstNotNilRuleTests) -> () throws -> Void)] = [
        ("testWithDefaultConfiguration", testWithDefaultConfiguration),
        ("testFirstReason", testFirstReason),
        ("testFirstIndexReason", testFirstIndexReason)
    ]
}

extension ContainsOverRangeNilComparisonRuleTests {
    static var allTests: [(String, (ContainsOverRangeNilComparisonRuleTests) -> () throws -> Void)] = [
        ("testWithDefaultConfiguration", testWithDefaultConfiguration)
    ]
}

extension ControlStatementRuleTests {
    static var allTests: [(String, (ControlStatementRuleTests) -> () throws -> Void)] = [
        ("testWithDefaultConfiguration", testWithDefaultConfiguration)
    ]
}

extension ConvenienceTypeRuleTests {
    static var allTests: [(String, (ConvenienceTypeRuleTests) -> () throws -> Void)] = [
        ("testWithDefaultConfiguration", testWithDefaultConfiguration)
    ]
}

extension CustomRulesTests {
    static var allTests: [(String, (CustomRulesTests) -> () throws -> Void)] = [
        ("testCustomRuleConfigurationSetsCorrectly", testCustomRuleConfigurationSetsCorrectly),
        ("testCustomRuleConfigurationThrows", testCustomRuleConfigurationThrows),
        ("testCustomRuleConfigurationIgnoreInvalidRules", testCustomRuleConfigurationIgnoreInvalidRules),
        ("testCustomRules", testCustomRules),
        ("testLocalDisableCustomRule", testLocalDisableCustomRule),
        ("testLocalDisableCustomRuleWithMultipleRules", testLocalDisableCustomRuleWithMultipleRules),
        ("testCustomRulesIncludedDefault", testCustomRulesIncludedDefault),
        ("testCustomRulesIncludedExcludesFile", testCustomRulesIncludedExcludesFile),
        ("testCustomRulesExcludedExcludesFile", testCustomRulesExcludedExcludesFile)
    ]
}

extension CyclomaticComplexityConfigurationTests {
    static var allTests: [(String, (CyclomaticComplexityConfigurationTests) -> () throws -> Void)] = [
        ("testCyclomaticComplexityConfigurationInitializerSetsLevels", testCyclomaticComplexityConfigurationInitializerSetsLevels),
        ("testCyclomaticComplexityConfigurationInitializerSetsIgnoresCaseStatements", testCyclomaticComplexityConfigurationInitializerSetsIgnoresCaseStatements),
        ("testCyclomaticComplexityConfigurationApplyConfigurationWithDictionary", testCyclomaticComplexityConfigurationApplyConfigurationWithDictionary),
        ("testCyclomaticComplexityConfigurationThrowsOnBadConfigValues", testCyclomaticComplexityConfigurationThrowsOnBadConfigValues),
        ("testCyclomaticComplexityConfigurationCompares", testCyclomaticComplexityConfigurationCompares)
    ]
}

extension CyclomaticComplexityRuleTests {
    static var allTests: [(String, (CyclomaticComplexityRuleTests) -> () throws -> Void)] = [
        ("testCyclomaticComplexity", testCyclomaticComplexity),
        ("testIgnoresCaseStatementsConfigurationEnabled", testIgnoresCaseStatementsConfigurationEnabled),
        ("testIgnoresCaseStatementsConfigurationDisabled", testIgnoresCaseStatementsConfigurationDisabled)
    ]
}

extension DeploymentTargetConfigurationTests {
    static var allTests: [(String, (DeploymentTargetConfigurationTests) -> () throws -> Void)] = [
        ("testAppliesConfigurationFromDictionary", testAppliesConfigurationFromDictionary),
        ("testThrowsOnBadConfig", testThrowsOnBadConfig)
    ]
}

extension DeploymentTargetRuleTests {
    static var allTests: [(String, (DeploymentTargetRuleTests) -> () throws -> Void)] = [
        ("testRule", testRule),
        ("testMacOSAttributeReason", testMacOSAttributeReason),
        ("testWatchOSConditionReason", testWatchOSConditionReason)
    ]
}

extension DisableAllTests {
    static var allTests: [(String, (DisableAllTests) -> () throws -> Void)] = [
        ("testViolatingPhrase", testViolatingPhrase),
        ("testDisableAll", testDisableAll),
        ("testEnableAll", testEnableAll),
        ("testDisableAllPrevious", testDisableAllPrevious),
        ("testEnableAllPrevious", testEnableAllPrevious),
        ("testDisableAllNext", testDisableAllNext),
        ("testEnableAllNext", testEnableAllNext),
        ("testDisableAllThis", testDisableAllThis),
        ("testEnableAllThis", testEnableAllThis)
    ]
}

extension DiscardedNotificationCenterObserverRuleTests {
    static var allTests: [(String, (DiscardedNotificationCenterObserverRuleTests) -> () throws -> Void)] = [
        ("testWithDefaultConfiguration", testWithDefaultConfiguration)
    ]
}

extension DiscouragedDirectInitRuleTests {
    static var allTests: [(String, (DiscouragedDirectInitRuleTests) -> () throws -> Void)] = [
        ("testDiscouragedDirectInitWithDefaultConfiguration", testDiscouragedDirectInitWithDefaultConfiguration),
        ("testDiscouragedDirectInitWithConfiguredSeverity", testDiscouragedDirectInitWithConfiguredSeverity),
        ("testDiscouragedDirectInitWithNewIncludedTypes", testDiscouragedDirectInitWithNewIncludedTypes),
        ("testDiscouragedDirectInitWithReplacedTypes", testDiscouragedDirectInitWithReplacedTypes)
    ]
}

extension DiscouragedObjectLiteralRuleTests {
    static var allTests: [(String, (DiscouragedObjectLiteralRuleTests) -> () throws -> Void)] = [
        ("testWithDefaultConfiguration", testWithDefaultConfiguration),
        ("testWithImageLiteral", testWithImageLiteral),
        ("testWithColorLiteral", testWithColorLiteral)
    ]
}

extension DiscouragedOptionalBooleanRuleTests {
    static var allTests: [(String, (DiscouragedOptionalBooleanRuleTests) -> () throws -> Void)] = [
        ("testWithDefaultConfiguration", testWithDefaultConfiguration)
    ]
}

extension DiscouragedOptionalCollectionRuleTests {
    static var allTests: [(String, (DiscouragedOptionalCollectionRuleTests) -> () throws -> Void)] = [
        ("testWithDefaultConfiguration", testWithDefaultConfiguration)
    ]
}

extension DocumentationTests {
    static var allTests: [(String, (DocumentationTests) -> () throws -> Void)] = [
        ("testRulesDocumentationIsUpdated", testRulesDocumentationIsUpdated)
    ]
}

extension DuplicateEnumCasesRuleTests {
    static var allTests: [(String, (DuplicateEnumCasesRuleTests) -> () throws -> Void)] = [
        ("testWithDefaultConfiguration", testWithDefaultConfiguration)
    ]
}

extension DuplicateImportsRuleTests {
    static var allTests: [(String, (DuplicateImportsRuleTests) -> () throws -> Void)] = [
        ("testWithDefaultConfiguration", testWithDefaultConfiguration)
    ]
}

extension DynamicInlineRuleTests {
    static var allTests: [(String, (DynamicInlineRuleTests) -> () throws -> Void)] = [
        ("testWithDefaultConfiguration", testWithDefaultConfiguration)
    ]
}

extension EmptyCollectionLiteralRuleTests {
    static var allTests: [(String, (EmptyCollectionLiteralRuleTests) -> () throws -> Void)] = [
        ("testWithDefaultConfiguration", testWithDefaultConfiguration)
    ]
}

extension EmptyCountRuleTests {
    static var allTests: [(String, (EmptyCountRuleTests) -> () throws -> Void)] = [
        ("testWithDefaultConfiguration", testWithDefaultConfiguration)
    ]
}

extension EmptyEnumArgumentsRuleTests {
    static var allTests: [(String, (EmptyEnumArgumentsRuleTests) -> () throws -> Void)] = [
        ("testWithDefaultConfiguration", testWithDefaultConfiguration)
    ]
}

extension EmptyParametersRuleTests {
    static var allTests: [(String, (EmptyParametersRuleTests) -> () throws -> Void)] = [
        ("testWithDefaultConfiguration", testWithDefaultConfiguration)
    ]
}

extension EmptyParenthesesWithTrailingClosureRuleTests {
    static var allTests: [(String, (EmptyParenthesesWithTrailingClosureRuleTests) -> () throws -> Void)] = [
        ("testWithDefaultConfiguration", testWithDefaultConfiguration)
    ]
}

extension EmptyStringRuleTests {
    static var allTests: [(String, (EmptyStringRuleTests) -> () throws -> Void)] = [
        ("testWithDefaultConfiguration", testWithDefaultConfiguration)
    ]
}

extension EmptyXCTestMethodRuleTests {
    static var allTests: [(String, (EmptyXCTestMethodRuleTests) -> () throws -> Void)] = [
        ("testWithDefaultConfiguration", testWithDefaultConfiguration)
    ]
}

extension ExpiringTodoRuleTests {
    static var allTests: [(String, (ExpiringTodoRuleTests) -> () throws -> Void)] = [
        ("testExpiringTodo", testExpiringTodo),
        ("testExpiredTodo", testExpiredTodo),
        ("testExpiredFixMe", testExpiredFixMe),
        ("testApproachingExpiryTodo", testApproachingExpiryTodo),
        ("testNonExpiredTodo", testNonExpiredTodo),
        ("testExpiredCustomDelimiters", testExpiredCustomDelimiters),
        ("testExpiredCustomSeparator", testExpiredCustomSeparator),
        ("testExpiredCustomFormat", testExpiredCustomFormat)
    ]
}

extension ExplicitACLRuleTests {
    static var allTests: [(String, (ExplicitACLRuleTests) -> () throws -> Void)] = [
        ("testWithDefaultConfiguration", testWithDefaultConfiguration)
    ]
}

extension ExplicitEnumRawValueRuleTests {
    static var allTests: [(String, (ExplicitEnumRawValueRuleTests) -> () throws -> Void)] = [
        ("testWithDefaultConfiguration", testWithDefaultConfiguration)
    ]
}

extension ExplicitInitRuleTests {
    static var allTests: [(String, (ExplicitInitRuleTests) -> () throws -> Void)] = [
        ("testWithDefaultConfiguration", testWithDefaultConfiguration)
    ]
}

extension ExplicitSelfRuleTests {
    static var allTests: [(String, (ExplicitSelfRuleTests) -> () throws -> Void)] = [
        ("testWithDefaultConfiguration", testWithDefaultConfiguration)
    ]
}

extension ExplicitTopLevelACLRuleTests {
    static var allTests: [(String, (ExplicitTopLevelACLRuleTests) -> () throws -> Void)] = [
        ("testWithDefaultConfiguration", testWithDefaultConfiguration)
    ]
}

extension ExplicitTypeInterfaceConfigurationTests {
    static var allTests: [(String, (ExplicitTypeInterfaceConfigurationTests) -> () throws -> Void)] = [
        ("testDefaultConfiguration", testDefaultConfiguration),
        ("testApplyingCustomConfiguration", testApplyingCustomConfiguration),
        ("testInvalidKeyInCustomConfiguration", testInvalidKeyInCustomConfiguration),
        ("testInvalidTypeOfCustomConfiguration", testInvalidTypeOfCustomConfiguration),
        ("testInvalidTypeOfValueInCustomConfiguration", testInvalidTypeOfValueInCustomConfiguration),
        ("testConsoleDescription", testConsoleDescription)
    ]
}

extension ExplicitTypeInterfaceRuleTests {
    static var allTests: [(String, (ExplicitTypeInterfaceRuleTests) -> () throws -> Void)] = [
        ("testExplicitTypeInterface", testExplicitTypeInterface),
        ("testExcludeLocalVars", testExcludeLocalVars),
        ("testExcludeClassVars", testExcludeClassVars),
        ("testAllowRedundancy", testAllowRedundancy),
        ("testEmbededInStatements", testEmbededInStatements),
        ("testCaptureGroup", testCaptureGroup),
        ("testFastEnumerationDeclaration", testFastEnumerationDeclaration),
        ("testSwitchCaseDeclarations", testSwitchCaseDeclarations)
    ]
}

extension ExtendedNSStringTests {
    static var allTests: [(String, (ExtendedNSStringTests) -> () throws -> Void)] = [
        ("testLineAndCharacterForByteOffset_forContentsContainingMultibyteCharacters", testLineAndCharacterForByteOffset_forContentsContainingMultibyteCharacters)
    ]
}

extension ExtensionAccessModifierRuleTests {
    static var allTests: [(String, (ExtensionAccessModifierRuleTests) -> () throws -> Void)] = [
        ("testWithDefaultConfiguration", testWithDefaultConfiguration)
    ]
}

extension FallthroughRuleTests {
    static var allTests: [(String, (FallthroughRuleTests) -> () throws -> Void)] = [
        ("testWithDefaultConfiguration", testWithDefaultConfiguration)
    ]
}

extension FatalErrorMessageRuleTests {
    static var allTests: [(String, (FatalErrorMessageRuleTests) -> () throws -> Void)] = [
        ("testWithDefaultConfiguration", testWithDefaultConfiguration)
    ]
}

extension FileHeaderRuleTests {
    static var allTests: [(String, (FileHeaderRuleTests) -> () throws -> Void)] = [
        ("testFileHeaderWithDefaultConfiguration", testFileHeaderWithDefaultConfiguration),
        ("testFileHeaderWithRequiredString", testFileHeaderWithRequiredString),
        ("testFileHeaderWithRequiredPattern", testFileHeaderWithRequiredPattern),
        ("testFileHeaderWithRequiredStringAndURLComment", testFileHeaderWithRequiredStringAndURLComment),
        ("testFileHeaderWithForbiddenString", testFileHeaderWithForbiddenString),
        ("testFileHeaderWithForbiddenPattern", testFileHeaderWithForbiddenPattern),
        ("testFileHeaderWithForbiddenPatternAndDocComment", testFileHeaderWithForbiddenPatternAndDocComment),
        ("testFileHeaderWithRequiredStringUsingFilenamePlaceholder", testFileHeaderWithRequiredStringUsingFilenamePlaceholder),
        ("testFileHeaderWithForbiddenStringUsingFilenamePlaceholder", testFileHeaderWithForbiddenStringUsingFilenamePlaceholder),
        ("testFileHeaderWithRequiredPatternUsingFilenamePlaceholder", testFileHeaderWithRequiredPatternUsingFilenamePlaceholder),
        ("testFileHeaderWithForbiddenPatternUsingFilenamePlaceholder", testFileHeaderWithForbiddenPatternUsingFilenamePlaceholder)
    ]
}

extension FileLengthRuleTests {
    static var allTests: [(String, (FileLengthRuleTests) -> () throws -> Void)] = [
        ("testFileLengthWithDefaultConfiguration", testFileLengthWithDefaultConfiguration),
        ("testFileLengthIgnoringLinesWithOnlyComments", testFileLengthIgnoringLinesWithOnlyComments)
    ]
}

extension FileNameRuleTests {
    static var allTests: [(String, (FileNameRuleTests) -> () throws -> Void)] = [
        ("testMainDoesntTrigger", testMainDoesntTrigger),
        ("testLinuxMainDoesntTrigger", testLinuxMainDoesntTrigger),
        ("testClassNameDoesntTrigger", testClassNameDoesntTrigger),
        ("testStructNameDoesntTrigger", testStructNameDoesntTrigger),
        ("testExtensionNameDoesntTrigger", testExtensionNameDoesntTrigger),
        ("testNestedExtensionDoesntTrigger", testNestedExtensionDoesntTrigger),
        ("testNestedTypeSeparatorDoesntTrigger", testNestedTypeSeparatorDoesntTrigger),
        ("testWrongNestedTypeSeparatorDoesTrigger", testWrongNestedTypeSeparatorDoesTrigger),
        ("testMisspelledNameDoesTrigger", testMisspelledNameDoesTrigger),
        ("testMisspelledNameDoesntTriggerWithOverride", testMisspelledNameDoesntTriggerWithOverride),
        ("testMainDoesTriggerWithoutOverride", testMainDoesTriggerWithoutOverride),
        ("testCustomSuffixPattern", testCustomSuffixPattern),
        ("testCustomPrefixPattern", testCustomPrefixPattern),
        ("testCustomPrefixAndSuffixPatterns", testCustomPrefixAndSuffixPatterns)
    ]
}

extension FileTypesOrderRuleTests {
    static var allTests: [(String, (FileTypesOrderRuleTests) -> () throws -> Void)] = [
        ("testFileTypesOrderWithDefaultConfiguration", testFileTypesOrderWithDefaultConfiguration),
        ("testFileTypesOrderReversedOrder", testFileTypesOrderReversedOrder),
        ("testFileTypesOrderGroupedOrder", testFileTypesOrderGroupedOrder)
    ]
}

extension FirstWhereRuleTests {
    static var allTests: [(String, (FirstWhereRuleTests) -> () throws -> Void)] = [
        ("testWithDefaultConfiguration", testWithDefaultConfiguration)
    ]
}

extension FlatMapOverMapReduceRuleTests {
    static var allTests: [(String, (FlatMapOverMapReduceRuleTests) -> () throws -> Void)] = [
        ("testWithDefaultConfiguration", testWithDefaultConfiguration)
    ]
}

extension ForWhereRuleTests {
    static var allTests: [(String, (ForWhereRuleTests) -> () throws -> Void)] = [
        ("testWithDefaultConfiguration", testWithDefaultConfiguration)
    ]
}

extension ForceCastRuleTests {
    static var allTests: [(String, (ForceCastRuleTests) -> () throws -> Void)] = [
        ("testWithDefaultConfiguration", testWithDefaultConfiguration)
    ]
}

extension ForceTryRuleTests {
    static var allTests: [(String, (ForceTryRuleTests) -> () throws -> Void)] = [
        ("testWithDefaultConfiguration", testWithDefaultConfiguration)
    ]
}

extension ForceUnwrappingRuleTests {
    static var allTests: [(String, (ForceUnwrappingRuleTests) -> () throws -> Void)] = [
        ("testWithDefaultConfiguration", testWithDefaultConfiguration)
    ]
}

extension FunctionBodyLengthRuleTests {
    static var allTests: [(String, (FunctionBodyLengthRuleTests) -> () throws -> Void)] = [
        ("testWithDefaultConfiguration", testWithDefaultConfiguration),
        ("testFunctionBodyLengths", testFunctionBodyLengths),
        ("testFunctionBodyLengthsWithComments", testFunctionBodyLengthsWithComments),
        ("testFunctionBodyLengthsWithMultilineComments", testFunctionBodyLengthsWithMultilineComments)
    ]
}

extension FunctionDefaultParameterAtEndRuleTests {
    static var allTests: [(String, (FunctionDefaultParameterAtEndRuleTests) -> () throws -> Void)] = [
        ("testWithDefaultConfiguration", testWithDefaultConfiguration)
    ]
}

extension FunctionParameterCountRuleTests {
    static var allTests: [(String, (FunctionParameterCountRuleTests) -> () throws -> Void)] = [
        ("testWithDefaultConfiguration", testWithDefaultConfiguration),
        ("testFunctionParameterCount", testFunctionParameterCount),
        ("testDefaultFunctionParameterCount", testDefaultFunctionParameterCount)
    ]
}

extension GenericTypeNameRuleTests {
    static var allTests: [(String, (GenericTypeNameRuleTests) -> () throws -> Void)] = [
        ("testGenericTypeName", testGenericTypeName),
        ("testGenericTypeNameWithAllowedSymbols", testGenericTypeNameWithAllowedSymbols),
        ("testGenericTypeNameWithAllowedSymbolsAndViolation", testGenericTypeNameWithAllowedSymbolsAndViolation),
        ("testGenericTypeNameWithIgnoreStartWithLowercase", testGenericTypeNameWithIgnoreStartWithLowercase)
    ]
}

extension GlobTests {
    static var allTests: [(String, (GlobTests) -> () throws -> Void)] = [
        ("testOnlyGlobForWildcard", testOnlyGlobForWildcard),
        ("testNoMatchReturnsEmpty", testNoMatchReturnsEmpty),
        ("testMatchesFiles", testMatchesFiles),
        ("testMatchesSingleCharacter", testMatchesSingleCharacter),
        ("testMatchesOneCharacterInBracket", testMatchesOneCharacterInBracket),
        ("testNoMatchOneCharacterInBracket", testNoMatchOneCharacterInBracket),
        ("testMatchesCharacterInRange", testMatchesCharacterInRange),
        ("testNoMatchCharactersInRange", testNoMatchCharactersInRange),
        ("testMatchesMultipleFiles", testMatchesMultipleFiles),
        ("testMatchesNestedDirectory", testMatchesNestedDirectory),
        ("testNoGlobstarSupport", testNoGlobstarSupport)
    ]
}

extension IdenticalOperandsRuleTests {
    static var allTests: [(String, (IdenticalOperandsRuleTests) -> () throws -> Void)] = [
        ("testWithDefaultConfiguration", testWithDefaultConfiguration)
    ]
}

extension IdentifierNameRuleTests {
    static var allTests: [(String, (IdentifierNameRuleTests) -> () throws -> Void)] = [
        ("testIdentifierName", testIdentifierName),
        ("testIdentifierNameWithAllowedSymbols", testIdentifierNameWithAllowedSymbols),
        ("testIdentifierNameWithAllowedSymbolsAndViolation", testIdentifierNameWithAllowedSymbolsAndViolation),
        ("testIdentifierNameWithIgnoreStartWithLowercase", testIdentifierNameWithIgnoreStartWithLowercase),
        ("testLinuxCrashOnEmojiNames", testLinuxCrashOnEmojiNames)
    ]
}

extension ImplicitGetterRuleTests {
    static var allTests: [(String, (ImplicitGetterRuleTests) -> () throws -> Void)] = [
        ("testWithDefaultConfiguration", testWithDefaultConfiguration)
    ]
}

extension ImplicitReturnRuleTests {
    static var allTests: [(String, (ImplicitReturnRuleTests) -> () throws -> Void)] = [
        ("testWithDefaultConfiguration", testWithDefaultConfiguration)
    ]
}

extension ImplicitlyUnwrappedOptionalConfigurationTests {
    static var allTests: [(String, (ImplicitlyUnwrappedOptionalConfigurationTests) -> () throws -> Void)] = [
        ("testImplicitlyUnwrappedOptionalConfigurationProperlyAppliesConfigurationFromDictionary", testImplicitlyUnwrappedOptionalConfigurationProperlyAppliesConfigurationFromDictionary),
        ("testImplicitlyUnwrappedOptionalConfigurationThrowsOnBadConfig", testImplicitlyUnwrappedOptionalConfigurationThrowsOnBadConfig)
    ]
}

extension ImplicitlyUnwrappedOptionalRuleTests {
    static var allTests: [(String, (ImplicitlyUnwrappedOptionalRuleTests) -> () throws -> Void)] = [
        ("testWithDefaultConfiguration", testWithDefaultConfiguration),
        ("testImplicitlyUnwrappedOptionalRuleDefaultConfiguration", testImplicitlyUnwrappedOptionalRuleDefaultConfiguration),
        ("testImplicitlyUnwrappedOptionalRuleWarnsOnOutletsInAllMode", testImplicitlyUnwrappedOptionalRuleWarnsOnOutletsInAllMode)
    ]
}

extension InertDeferRuleTests {
    static var allTests: [(String, (InertDeferRuleTests) -> () throws -> Void)] = [
        ("testWithDefaultConfiguration", testWithDefaultConfiguration)
    ]
}

extension IntegrationTests {
    static var allTests: [(String, (IntegrationTests) -> () throws -> Void)] = [
        ("testSwiftLintLints", testSwiftLintLints),
        ("testSwiftLintAutoCorrects", testSwiftLintAutoCorrects),
        ("testSimulateHomebrewTest", testSimulateHomebrewTest),
        ("testSimulateHomebrewTestWithDisableSourceKit", testSimulateHomebrewTestWithDisableSourceKit)
    ]
}

extension IsDisjointRuleTests {
    static var allTests: [(String, (IsDisjointRuleTests) -> () throws -> Void)] = [
        ("testWithDefaultConfiguration", testWithDefaultConfiguration)
    ]
}

extension JoinedDefaultParameterRuleTests {
    static var allTests: [(String, (JoinedDefaultParameterRuleTests) -> () throws -> Void)] = [
        ("testWithDefaultConfiguration", testWithDefaultConfiguration)
    ]
}

extension LargeTupleRuleTests {
    static var allTests: [(String, (LargeTupleRuleTests) -> () throws -> Void)] = [
        ("testWithDefaultConfiguration", testWithDefaultConfiguration)
    ]
}

extension LastWhereRuleTests {
    static var allTests: [(String, (LastWhereRuleTests) -> () throws -> Void)] = [
        ("testWithDefaultConfiguration", testWithDefaultConfiguration)
    ]
}

extension LegacyCGGeometryFunctionsRuleTests {
    static var allTests: [(String, (LegacyCGGeometryFunctionsRuleTests) -> () throws -> Void)] = [
        ("testWithDefaultConfiguration", testWithDefaultConfiguration)
    ]
}

extension LegacyConstantRuleTests {
    static var allTests: [(String, (LegacyConstantRuleTests) -> () throws -> Void)] = [
        ("testWithDefaultConfiguration", testWithDefaultConfiguration)
    ]
}

extension LegacyConstructorRuleTests {
    static var allTests: [(String, (LegacyConstructorRuleTests) -> () throws -> Void)] = [
        ("testWithDefaultConfiguration", testWithDefaultConfiguration)
    ]
}

extension LegacyHashingRuleTests {
    static var allTests: [(String, (LegacyHashingRuleTests) -> () throws -> Void)] = [
        ("testWithDefaultConfiguration", testWithDefaultConfiguration)
    ]
}

extension LegacyMultipleRuleTests {
    static var allTests: [(String, (LegacyMultipleRuleTests) -> () throws -> Void)] = [
        ("testWithDefaultConfiguration", testWithDefaultConfiguration)
    ]
}

extension LegacyNSGeometryFunctionsRuleTests {
    static var allTests: [(String, (LegacyNSGeometryFunctionsRuleTests) -> () throws -> Void)] = [
        ("testWithDefaultConfiguration", testWithDefaultConfiguration)
    ]
}

extension LegacyRandomRuleTests {
    static var allTests: [(String, (LegacyRandomRuleTests) -> () throws -> Void)] = [
        ("testWithDefaultConfiguration", testWithDefaultConfiguration)
    ]
}

extension LetVarWhitespaceRuleTests {
    static var allTests: [(String, (LetVarWhitespaceRuleTests) -> () throws -> Void)] = [
        ("testWithDefaultConfiguration", testWithDefaultConfiguration)
    ]
}

extension LineLengthConfigurationTests {
    static var allTests: [(String, (LineLengthConfigurationTests) -> () throws -> Void)] = [
        ("testLineLengthConfigurationInitializerSetsLength", testLineLengthConfigurationInitializerSetsLength),
        ("testLineLengthConfigurationInitialiserSetsIgnoresURLs", testLineLengthConfigurationInitialiserSetsIgnoresURLs),
        ("testLineLengthConfigurationInitialiserSetsIgnoresFunctionDeclarations", testLineLengthConfigurationInitialiserSetsIgnoresFunctionDeclarations),
        ("testLineLengthConfigurationInitialiserSetsIgnoresComments", testLineLengthConfigurationInitialiserSetsIgnoresComments),
        ("testLineLengthConfigurationInitialiserSetsIgnoresInterpolatedStrings", testLineLengthConfigurationInitialiserSetsIgnoresInterpolatedStrings),
        ("testLineLengthConfigurationParams", testLineLengthConfigurationParams),
        ("testLineLengthConfigurationPartialParams", testLineLengthConfigurationPartialParams),
        ("testLineLengthConfigurationThrowsOnBadConfig", testLineLengthConfigurationThrowsOnBadConfig),
        ("testLineLengthConfigurationThrowsOnBadConfigValues", testLineLengthConfigurationThrowsOnBadConfigValues),
        ("testLineLengthConfigurationApplyConfigurationWithArray", testLineLengthConfigurationApplyConfigurationWithArray),
        ("testLineLengthConfigurationApplyConfigurationWithDictionary", testLineLengthConfigurationApplyConfigurationWithDictionary),
        ("testLineLengthConfigurationCompares", testLineLengthConfigurationCompares)
    ]
}

extension LineLengthRuleTests {
    static var allTests: [(String, (LineLengthRuleTests) -> () throws -> Void)] = [
        ("testLineLength", testLineLength),
        ("testLineLengthWithIgnoreFunctionDeclarationsEnabled", testLineLengthWithIgnoreFunctionDeclarationsEnabled),
        ("testLineLengthWithIgnoreCommentsEnabled", testLineLengthWithIgnoreCommentsEnabled),
        ("testLineLengthWithIgnoreURLsEnabled", testLineLengthWithIgnoreURLsEnabled),
        ("testLineLengthWithIgnoreInterpolatedStringsTrue", testLineLengthWithIgnoreInterpolatedStringsTrue),
        ("testLineLengthWithIgnoreInterpolatedStringsFalse", testLineLengthWithIgnoreInterpolatedStringsFalse)
    ]
}

extension LinterCacheTests {
    static var allTests: [(String, (LinterCacheTests) -> () throws -> Void)] = [
        ("testUnchangedFilesReusesCache", testUnchangedFilesReusesCache),
        ("testConfigFileReorderedReusesCache", testConfigFileReorderedReusesCache),
        ("testConfigFileWhitespaceAndCommentsChangedOrAddedOrRemovedReusesCache", testConfigFileWhitespaceAndCommentsChangedOrAddedOrRemovedReusesCache),
        ("testConfigFileUnrelatedKeysChangedOrAddedOrRemovedReusesCache", testConfigFileUnrelatedKeysChangedOrAddedOrRemovedReusesCache),
        ("testChangedFileCausesJustThatFileToBeLintWithCacheUsedForAllOthers", testChangedFileCausesJustThatFileToBeLintWithCacheUsedForAllOthers),
        ("testFileRemovedPreservesThatFileInTheCacheAndDoesntCauseAnyOtherFilesToBeLinted", testFileRemovedPreservesThatFileInTheCacheAndDoesntCauseAnyOtherFilesToBeLinted),
        ("testCustomRulesChangedOrAddedOrRemovedCausesAllFilesToBeReLinted", testCustomRulesChangedOrAddedOrRemovedCausesAllFilesToBeReLinted),
        ("testDisabledRulesChangedOrAddedOrRemovedCausesAllFilesToBeReLinted", testDisabledRulesChangedOrAddedOrRemovedCausesAllFilesToBeReLinted),
        ("testOptInRulesChangedOrAddedOrRemovedCausesAllFilesToBeReLinted", testOptInRulesChangedOrAddedOrRemovedCausesAllFilesToBeReLinted),
        ("testEnabledRulesChangedOrAddedOrRemovedCausesAllFilesToBeReLinted", testEnabledRulesChangedOrAddedOrRemovedCausesAllFilesToBeReLinted),
        ("testWhitelistRulesChangedOrAddedOrRemovedCausesAllFilesToBeReLinted", testWhitelistRulesChangedOrAddedOrRemovedCausesAllFilesToBeReLinted),
        ("testRuleConfigurationChangedOrAddedOrRemovedCausesAllFilesToBeReLinted", testRuleConfigurationChangedOrAddedOrRemovedCausesAllFilesToBeReLinted),
        ("testSwiftVersionChangedRemovedCausesAllFilesToBeReLinted", testSwiftVersionChangedRemovedCausesAllFilesToBeReLinted),
        ("testDetectSwiftVersion", testDetectSwiftVersion)
    ]
}

extension LiteralExpressionEndIdentationRuleTests {
    static var allTests: [(String, (LiteralExpressionEndIdentationRuleTests) -> () throws -> Void)] = [
        ("testWithDefaultConfiguration", testWithDefaultConfiguration)
    ]
}

extension LowerACLThanParentRuleTests {
    static var allTests: [(String, (LowerACLThanParentRuleTests) -> () throws -> Void)] = [
        ("testWithDefaultConfiguration", testWithDefaultConfiguration)
    ]
}

extension MissingDocsRuleConfigurationTests {
    static var allTests: [(String, (MissingDocsRuleConfigurationTests) -> () throws -> Void)] = [
        ("testDescriptionEmpty", testDescriptionEmpty),
        ("testDescriptionSingleServety", testDescriptionSingleServety),
        ("testDescriptionMultipleSeverities", testDescriptionMultipleSeverities),
        ("testDescriptionMultipleAcls", testDescriptionMultipleAcls),
        ("testParsingSingleServety", testParsingSingleServety),
        ("testParsingMultipleSeverities", testParsingMultipleSeverities),
        ("testParsingMultipleAcls", testParsingMultipleAcls),
        ("testInvalidServety", testInvalidServety),
        ("testInvalidAcl", testInvalidAcl),
        ("testInvalidDuplicateAcl", testInvalidDuplicateAcl)
    ]
}

extension MissingDocsRuleTests {
    static var allTests: [(String, (MissingDocsRuleTests) -> () throws -> Void)] = [
        ("testWithDefaultConfiguration", testWithDefaultConfiguration)
    ]
}

extension ModifierOrderTests {
    static var allTests: [(String, (ModifierOrderTests) -> () throws -> Void)] = [
        ("testAttributeTypeMethod", testAttributeTypeMethod),
        ("testRightOrderedModifierGroups", testRightOrderedModifierGroups),
        ("testAtPrefixedGroup", testAtPrefixedGroup),
        ("testNonSpecifiedModifiersDontInterfere", testNonSpecifiedModifiersDontInterfere),
        ("testCorrectionsAreAppliedCorrectly", testCorrectionsAreAppliedCorrectly),
        ("testCorrectionsAreNotAppliedToIrrelevantModifier", testCorrectionsAreNotAppliedToIrrelevantModifier),
        ("testTypeMethodClassCorrection", testTypeMethodClassCorrection),
        ("testViolationMessage", testViolationMessage)
    ]
}

extension MultilineArgumentsBracketsRuleTests {
    static var allTests: [(String, (MultilineArgumentsBracketsRuleTests) -> () throws -> Void)] = [
        ("testWithDefaultConfiguration", testWithDefaultConfiguration)
    ]
}

extension MultilineArgumentsRuleTests {
    static var allTests: [(String, (MultilineArgumentsRuleTests) -> () throws -> Void)] = [
        ("testMultilineArgumentsWithDefaultConfiguration", testMultilineArgumentsWithDefaultConfiguration),
        ("testMultilineArgumentsWithWithNextLine", testMultilineArgumentsWithWithNextLine),
        ("testMultilineArgumentsWithWithSameLine", testMultilineArgumentsWithWithSameLine),
        ("testMultilineArgumentsWithOnlyEnforceAfterFirstClosureOnFirstLine", testMultilineArgumentsWithOnlyEnforceAfterFirstClosureOnFirstLine)
    ]
}

extension MultilineFunctionChainsRuleTests {
    static var allTests: [(String, (MultilineFunctionChainsRuleTests) -> () throws -> Void)] = [
        ("testWithDefaultConfiguration", testWithDefaultConfiguration)
    ]
}

extension MultilineLiteralBracketsRuleTests {
    static var allTests: [(String, (MultilineLiteralBracketsRuleTests) -> () throws -> Void)] = [
        ("testWithDefaultConfiguration", testWithDefaultConfiguration)
    ]
}

extension MultilineParametersBracketsRuleTests {
    static var allTests: [(String, (MultilineParametersBracketsRuleTests) -> () throws -> Void)] = [
        ("testWithDefaultConfiguration", testWithDefaultConfiguration)
    ]
}

extension MultilineParametersRuleTests {
    static var allTests: [(String, (MultilineParametersRuleTests) -> () throws -> Void)] = [
        ("testWithDefaultConfiguration", testWithDefaultConfiguration)
    ]
}

extension MultipleClosuresWithTrailingClosureRuleTests {
    static var allTests: [(String, (MultipleClosuresWithTrailingClosureRuleTests) -> () throws -> Void)] = [
        ("testWithDefaultConfiguration", testWithDefaultConfiguration)
    ]
}

extension NSLocalizedStringKeyRuleTests {
    static var allTests: [(String, (NSLocalizedStringKeyRuleTests) -> () throws -> Void)] = [
        ("testWithDefaultConfiguration", testWithDefaultConfiguration)
    ]
}

extension NSLocalizedStringRequireBundleRuleTests {
    static var allTests: [(String, (NSLocalizedStringRequireBundleRuleTests) -> () throws -> Void)] = [
        ("testWithDefaultConfiguration", testWithDefaultConfiguration)
    ]
}

extension NSObjectPreferIsEqualRuleTests {
    static var allTests: [(String, (NSObjectPreferIsEqualRuleTests) -> () throws -> Void)] = [
        ("testWithDefaultConfiguration", testWithDefaultConfiguration)
    ]
}

extension NestingRuleTests {
    static var allTests: [(String, (NestingRuleTests) -> () throws -> Void)] = [
        ("testWithDefaultConfiguration", testWithDefaultConfiguration)
    ]
}

extension NimbleOperatorRuleTests {
    static var allTests: [(String, (NimbleOperatorRuleTests) -> () throws -> Void)] = [
        ("testWithDefaultConfiguration", testWithDefaultConfiguration)
    ]
}

extension NoExtensionAccessModifierRuleTests {
    static var allTests: [(String, (NoExtensionAccessModifierRuleTests) -> () throws -> Void)] = [
        ("testWithDefaultConfiguration", testWithDefaultConfiguration)
    ]
}

extension NoFallthroughOnlyRuleTests {
    static var allTests: [(String, (NoFallthroughOnlyRuleTests) -> () throws -> Void)] = [
        ("testWithDefaultConfiguration", testWithDefaultConfiguration)
    ]
}

extension NoGroupingExtensionRuleTests {
    static var allTests: [(String, (NoGroupingExtensionRuleTests) -> () throws -> Void)] = [
        ("testWithDefaultConfiguration", testWithDefaultConfiguration)
    ]
}

extension NoSpaceInMethodCallRuleTests {
    static var allTests: [(String, (NoSpaceInMethodCallRuleTests) -> () throws -> Void)] = [
        ("testWithDefaultConfiguration", testWithDefaultConfiguration)
    ]
}

extension NotificationCenterDetachmentRuleTests {
    static var allTests: [(String, (NotificationCenterDetachmentRuleTests) -> () throws -> Void)] = [
        ("testWithDefaultConfiguration", testWithDefaultConfiguration)
    ]
}

extension NumberSeparatorRuleTests {
    static var allTests: [(String, (NumberSeparatorRuleTests) -> () throws -> Void)] = [
        ("testNumberSeparatorWithDefaultConfiguration", testNumberSeparatorWithDefaultConfiguration),
        ("testNumberSeparatorWithMinimumLength", testNumberSeparatorWithMinimumLength),
        ("testNumberSeparatorWithMinimumFractionLength", testNumberSeparatorWithMinimumFractionLength),
        ("testNumberSeparatorWithExcludeRanges", testNumberSeparatorWithExcludeRanges)
    ]
}

extension ObjectLiteralRuleTests {
    static var allTests: [(String, (ObjectLiteralRuleTests) -> () throws -> Void)] = [
        ("testObjectLiteralWithDefaultConfiguration", testObjectLiteralWithDefaultConfiguration),
        ("testObjectLiteralWithImageLiteral", testObjectLiteralWithImageLiteral),
        ("testObjectLiteralWithColorLiteral", testObjectLiteralWithColorLiteral),
        ("testObjectLiteralWithImageAndColorLiteral", testObjectLiteralWithImageAndColorLiteral)
    ]
}

extension OpeningBraceRuleTests {
    static var allTests: [(String, (OpeningBraceRuleTests) -> () throws -> Void)] = [
        ("testWithDefaultConfiguration", testWithDefaultConfiguration)
    ]
}

extension OperatorFunctionWhitespaceRuleTests {
    static var allTests: [(String, (OperatorFunctionWhitespaceRuleTests) -> () throws -> Void)] = [
        ("testWithDefaultConfiguration", testWithDefaultConfiguration)
    ]
}

extension OperatorUsageWhitespaceRuleTests {
    static var allTests: [(String, (OperatorUsageWhitespaceRuleTests) -> () throws -> Void)] = [
        ("testWithDefaultConfiguration", testWithDefaultConfiguration)
    ]
}

extension OptionalEnumCaseMatchingRuleTests {
    static var allTests: [(String, (OptionalEnumCaseMatchingRuleTests) -> () throws -> Void)] = [
        ("testWithDefaultConfiguration", testWithDefaultConfiguration)
    ]
}

extension OverriddenSuperCallRuleTests {
    static var allTests: [(String, (OverriddenSuperCallRuleTests) -> () throws -> Void)] = [
        ("testWithDefaultConfiguration", testWithDefaultConfiguration)
    ]
}

extension OverrideInExtensionRuleTests {
    static var allTests: [(String, (OverrideInExtensionRuleTests) -> () throws -> Void)] = [
        ("testWithDefaultConfiguration", testWithDefaultConfiguration)
    ]
}

extension PatternMatchingKeywordsRuleTests {
    static var allTests: [(String, (PatternMatchingKeywordsRuleTests) -> () throws -> Void)] = [
        ("testWithDefaultConfiguration", testWithDefaultConfiguration)
    ]
}

extension PrefixedTopLevelConstantRuleTests {
    static var allTests: [(String, (PrefixedTopLevelConstantRuleTests) -> () throws -> Void)] = [
        ("testDefaultConfiguration", testDefaultConfiguration),
        ("testPrivateOnly", testPrivateOnly)
    ]
}

extension PrivateActionRuleTests {
    static var allTests: [(String, (PrivateActionRuleTests) -> () throws -> Void)] = [
        ("testWithDefaultConfiguration", testWithDefaultConfiguration)
    ]
}

extension PrivateOutletRuleTests {
    static var allTests: [(String, (PrivateOutletRuleTests) -> () throws -> Void)] = [
        ("testWithDefaultConfiguration", testWithDefaultConfiguration),
        ("testWithAllowPrivateSet", testWithAllowPrivateSet)
    ]
}

extension PrivateOverFilePrivateRuleTests {
    static var allTests: [(String, (PrivateOverFilePrivateRuleTests) -> () throws -> Void)] = [
        ("testPrivateOverFilePrivateWithDefaultConfiguration", testPrivateOverFilePrivateWithDefaultConfiguration),
        ("testPrivateOverFilePrivateValidatingExtensions", testPrivateOverFilePrivateValidatingExtensions),
        ("testPrivateOverFilePrivateNotValidatingExtensions", testPrivateOverFilePrivateNotValidatingExtensions)
    ]
}

extension PrivateUnitTestRuleTests {
    static var allTests: [(String, (PrivateUnitTestRuleTests) -> () throws -> Void)] = [
        ("testWithDefaultConfiguration", testWithDefaultConfiguration)
    ]
}

extension ProhibitedInterfaceBuilderRuleTests {
    static var allTests: [(String, (ProhibitedInterfaceBuilderRuleTests) -> () throws -> Void)] = [
        ("testWithDefaultConfiguration", testWithDefaultConfiguration)
    ]
}

extension ProhibitedSuperRuleTests {
    static var allTests: [(String, (ProhibitedSuperRuleTests) -> () throws -> Void)] = [
        ("testWithDefaultConfiguration", testWithDefaultConfiguration)
    ]
}

extension ProtocolPropertyAccessorsOrderRuleTests {
    static var allTests: [(String, (ProtocolPropertyAccessorsOrderRuleTests) -> () throws -> Void)] = [
        ("testWithDefaultConfiguration", testWithDefaultConfiguration)
    ]
}

extension QuickDiscouragedCallRuleTests {
    static var allTests: [(String, (QuickDiscouragedCallRuleTests) -> () throws -> Void)] = [
        ("testWithDefaultConfiguration", testWithDefaultConfiguration)
    ]
}

extension QuickDiscouragedFocusedTestRuleTests {
    static var allTests: [(String, (QuickDiscouragedFocusedTestRuleTests) -> () throws -> Void)] = [
        ("testWithDefaultConfiguration", testWithDefaultConfiguration)
    ]
}

extension QuickDiscouragedPendingTestRuleTests {
    static var allTests: [(String, (QuickDiscouragedPendingTestRuleTests) -> () throws -> Void)] = [
        ("testWithDefaultConfiguration", testWithDefaultConfiguration)
    ]
}

extension RawValueForCamelCasedCodableEnumRuleTests {
    static var allTests: [(String, (RawValueForCamelCasedCodableEnumRuleTests) -> () throws -> Void)] = [
        ("testWithDefaultConfiguration", testWithDefaultConfiguration)
    ]
}

extension ReduceBooleanRuleTests {
    static var allTests: [(String, (ReduceBooleanRuleTests) -> () throws -> Void)] = [
        ("testWithDefaultConfiguration", testWithDefaultConfiguration)
    ]
}

extension ReduceIntoRuleTests {
    static var allTests: [(String, (ReduceIntoRuleTests) -> () throws -> Void)] = [
        ("testWithDefaultConfiguration", testWithDefaultConfiguration)
    ]
}

extension RedundantDiscardableLetRuleTests {
    static var allTests: [(String, (RedundantDiscardableLetRuleTests) -> () throws -> Void)] = [
        ("testWithDefaultConfiguration", testWithDefaultConfiguration)
    ]
}

extension RedundantNilCoalescingRuleTests {
    static var allTests: [(String, (RedundantNilCoalescingRuleTests) -> () throws -> Void)] = [
        ("testWithDefaultConfiguration", testWithDefaultConfiguration)
    ]
}

extension RedundantObjcAttributeRuleTests {
    static var allTests: [(String, (RedundantObjcAttributeRuleTests) -> () throws -> Void)] = [
        ("testWithDefaultConfiguration", testWithDefaultConfiguration)
    ]
}

extension RedundantOptionalInitializationRuleTests {
    static var allTests: [(String, (RedundantOptionalInitializationRuleTests) -> () throws -> Void)] = [
        ("testWithDefaultConfiguration", testWithDefaultConfiguration)
    ]
}

extension RedundantSetAccessControlRuleTests {
    static var allTests: [(String, (RedundantSetAccessControlRuleTests) -> () throws -> Void)] = [
        ("testWithDefaultConfiguration", testWithDefaultConfiguration)
    ]
}

extension RedundantStringEnumValueRuleTests {
    static var allTests: [(String, (RedundantStringEnumValueRuleTests) -> () throws -> Void)] = [
        ("testWithDefaultConfiguration", testWithDefaultConfiguration)
    ]
}

extension RedundantTypeAnnotationRuleTests {
    static var allTests: [(String, (RedundantTypeAnnotationRuleTests) -> () throws -> Void)] = [
        ("testWithDefaultConfiguration", testWithDefaultConfiguration)
    ]
}

extension RedundantVoidReturnRuleTests {
    static var allTests: [(String, (RedundantVoidReturnRuleTests) -> () throws -> Void)] = [
        ("testWithDefaultConfiguration", testWithDefaultConfiguration)
    ]
}

extension RegionTests {
    static var allTests: [(String, (RegionTests) -> () throws -> Void)] = [
        ("testNoRegionsInEmptyFile", testNoRegionsInEmptyFile),
        ("testNoRegionsInFileWithNoCommands", testNoRegionsInFileWithNoCommands),
        ("testRegionsFromSingleCommand", testRegionsFromSingleCommand),
        ("testRegionsFromMatchingPairCommands", testRegionsFromMatchingPairCommands),
        ("testRegionsFromThreeCommandForSingleLine", testRegionsFromThreeCommandForSingleLine),
        ("testSeveralRegionsFromSeveralCommands", testSeveralRegionsFromSeveralCommands)
    ]
}

extension ReporterTests {
    static var allTests: [(String, (ReporterTests) -> () throws -> Void)] = [
        ("testReporterFromString", testReporterFromString),
        ("testXcodeReporter", testXcodeReporter),
        ("testEmojiReporter", testEmojiReporter),
        ("testGitHubActionsLoggingReporter", testGitHubActionsLoggingReporter),
        ("testJSONReporter", testJSONReporter),
        ("testCSVReporter", testCSVReporter),
        ("testCheckstyleReporter", testCheckstyleReporter),
        ("testJunitReporter", testJunitReporter),
        ("testHTMLReporter", testHTMLReporter),
        ("testSonarQubeReporter", testSonarQubeReporter),
        ("testMarkdownReporter", testMarkdownReporter)
    ]
}

extension RequiredDeinitRuleTests {
    static var allTests: [(String, (RequiredDeinitRuleTests) -> () throws -> Void)] = [
        ("testWithDefaultConfiguration", testWithDefaultConfiguration)
    ]
}

extension RequiredEnumCaseRuleTestCase {
    static var allTests: [(String, (RequiredEnumCaseRuleTestCase) -> () throws -> Void)] = [
        ("testRequiredCaseHashValue", testRequiredCaseHashValue),
        ("testRequiredCaseEquatableReturnsTrue", testRequiredCaseEquatableReturnsTrue),
        ("testRequiredCaseEquatableReturnsFalseBecauseOfDifferentName", testRequiredCaseEquatableReturnsFalseBecauseOfDifferentName),
        ("testConsoleDescriptionReturnsAllConfiguredProtocols", testConsoleDescriptionReturnsAllConfiguredProtocols),
        ("testConsoleDescriptionReturnsNoConfiguredProtocols", testConsoleDescriptionReturnsNoConfiguredProtocols),
        ("testRegisterProtocolCasesRegistersCasesWithSpecifiedSeverity", testRegisterProtocolCasesRegistersCasesWithSpecifiedSeverity),
        ("testRegisterProtocols", testRegisterProtocols),
        ("testApplyThrowsErrorBecausePassedConfigurationCantBeCast", testApplyThrowsErrorBecausePassedConfigurationCantBeCast),
        ("testApplyRegistersProtocols", testApplyRegistersProtocols),
        ("testEqualsReturnsTrue", testEqualsReturnsTrue),
        ("testEqualsReturnsFalseBecauseProtocolsArentEqual", testEqualsReturnsFalseBecauseProtocolsArentEqual),
        ("testEqualsReturnsFalseBecauseSeverityIsntEqual", testEqualsReturnsFalseBecauseSeverityIsntEqual)
    ]
}

extension ReturnArrowWhitespaceRuleTests {
    static var allTests: [(String, (ReturnArrowWhitespaceRuleTests) -> () throws -> Void)] = [
        ("testWithDefaultConfiguration", testWithDefaultConfiguration)
    ]
}

extension RuleConfigurationTests {
    static var allTests: [(String, (RuleConfigurationTests) -> () throws -> Void)] = [
        ("testNameConfigurationSetsCorrectly", testNameConfigurationSetsCorrectly),
        ("testNameConfigurationThrowsOnBadConfig", testNameConfigurationThrowsOnBadConfig),
        ("testNameConfigurationMinLengthThreshold", testNameConfigurationMinLengthThreshold),
        ("testNameConfigurationMaxLengthThreshold", testNameConfigurationMaxLengthThreshold),
        ("testNestingConfigurationSetsCorrectly", testNestingConfigurationSetsCorrectly),
        ("testNestingConfigurationThrowsOnBadConfig", testNestingConfigurationThrowsOnBadConfig),
        ("testSeverityConfigurationFromString", testSeverityConfigurationFromString),
        ("testSeverityConfigurationFromDictionary", testSeverityConfigurationFromDictionary),
        ("testSeverityConfigurationThrowsOnBadConfig", testSeverityConfigurationThrowsOnBadConfig),
        ("testSeverityLevelConfigParams", testSeverityLevelConfigParams),
        ("testSeverityLevelConfigPartialParams", testSeverityLevelConfigPartialParams),
        ("testSeverityLevelConfigApplyNilErrorValue", testSeverityLevelConfigApplyNilErrorValue),
        ("testSeverityLevelConfigApplyMissingErrorValue", testSeverityLevelConfigApplyMissingErrorValue),
        ("testRegexConfigurationThrows", testRegexConfigurationThrows),
        ("testRegexRuleDescription", testRegexRuleDescription),
        ("testTrailingWhitespaceConfigurationThrowsOnBadConfig", testTrailingWhitespaceConfigurationThrowsOnBadConfig),
        ("testTrailingWhitespaceConfigurationInitializerSetsIgnoresEmptyLines", testTrailingWhitespaceConfigurationInitializerSetsIgnoresEmptyLines),
        ("testTrailingWhitespaceConfigurationInitializerSetsIgnoresComments", testTrailingWhitespaceConfigurationInitializerSetsIgnoresComments),
        ("testTrailingWhitespaceConfigurationApplyConfigurationSetsIgnoresEmptyLines", testTrailingWhitespaceConfigurationApplyConfigurationSetsIgnoresEmptyLines),
        ("testTrailingWhitespaceConfigurationApplyConfigurationSetsIgnoresComments", testTrailingWhitespaceConfigurationApplyConfigurationSetsIgnoresComments),
        ("testTrailingWhitespaceConfigurationCompares", testTrailingWhitespaceConfigurationCompares),
        ("testTrailingWhitespaceConfigurationApplyConfigurationUpdatesSeverityConfiguration", testTrailingWhitespaceConfigurationApplyConfigurationUpdatesSeverityConfiguration),
        ("testOverridenSuperCallConfigurationFromDictionary", testOverridenSuperCallConfigurationFromDictionary),
        ("testModifierOrderConfigurationFromDictionary", testModifierOrderConfigurationFromDictionary),
        ("testModifierOrderConfigurationThrowsOnUnrecognizedModifierGroup", testModifierOrderConfigurationThrowsOnUnrecognizedModifierGroup),
        ("testModifierOrderConfigurationThrowsOnNonModifiableGroup", testModifierOrderConfigurationThrowsOnNonModifiableGroup)
    ]
}

extension RuleTests {
    static var allTests: [(String, (RuleTests) -> () throws -> Void)] = [
        ("testRuleIsEqualTo", testRuleIsEqualTo),
        ("testRuleIsNotEqualTo", testRuleIsNotEqualTo),
        ("testRuleArraysWithDifferentCountsNotEqual", testRuleArraysWithDifferentCountsNotEqual),
        ("testSeverityLevelRuleInitsWithConfigDictionary", testSeverityLevelRuleInitsWithConfigDictionary),
        ("testSeverityLevelRuleInitsWithWarningOnlyConfigDictionary", testSeverityLevelRuleInitsWithWarningOnlyConfigDictionary),
        ("testSeverityLevelRuleInitsWithErrorOnlyConfigDictionary", testSeverityLevelRuleInitsWithErrorOnlyConfigDictionary),
        ("testSeverityLevelRuleInitsWithConfigArray", testSeverityLevelRuleInitsWithConfigArray),
        ("testSeverityLevelRuleInitsWithSingleValueConfigArray", testSeverityLevelRuleInitsWithSingleValueConfigArray),
        ("testSeverityLevelRuleInitsWithLiteral", testSeverityLevelRuleInitsWithLiteral),
        ("testSeverityLevelRuleNotEqual", testSeverityLevelRuleNotEqual),
        ("testDifferentSeverityLevelRulesNotEqual", testDifferentSeverityLevelRulesNotEqual)
    ]
}

extension RulesTests {
    static var allTests: [(String, (RulesTests) -> () throws -> Void)] = [
        ("testLeadingWhitespace", testLeadingWhitespace),
        ("testMark", testMark),
        ("testRequiredEnumCase", testRequiredEnumCase),
        ("testTrailingNewline", testTrailingNewline)
    ]
}

extension ShorthandOperatorRuleTests {
    static var allTests: [(String, (ShorthandOperatorRuleTests) -> () throws -> Void)] = [
        ("testWithDefaultConfiguration", testWithDefaultConfiguration)
    ]
}

extension SingleTestClassRuleTests {
    static var allTests: [(String, (SingleTestClassRuleTests) -> () throws -> Void)] = [
        ("testWithDefaultConfiguration", testWithDefaultConfiguration)
    ]
}

extension SortedFirstLastRuleTests {
    static var allTests: [(String, (SortedFirstLastRuleTests) -> () throws -> Void)] = [
        ("testWithDefaultConfiguration", testWithDefaultConfiguration)
    ]
}

extension SortedImportsRuleTests {
    static var allTests: [(String, (SortedImportsRuleTests) -> () throws -> Void)] = [
        ("testWithDefaultConfiguration", testWithDefaultConfiguration)
    ]
}

extension SourceKitCrashTests {
    static var allTests: [(String, (SourceKitCrashTests) -> () throws -> Void)] = [
        ("testAssertHandlerIsNotCalledOnNormalFile", testAssertHandlerIsNotCalledOnNormalFile),
        ("testAssertHandlerIsCalledOnFileThatCrashedSourceKitService", testAssertHandlerIsCalledOnFileThatCrashedSourceKitService),
        ("testRulesWithFileThatCrashedSourceKitService", testRulesWithFileThatCrashedSourceKitService)
    ]
}

extension StatementPositionRuleTests {
    static var allTests: [(String, (StatementPositionRuleTests) -> () throws -> Void)] = [
        ("testStatementPosition", testStatementPosition),
        ("testStatementPositionUncuddled", testStatementPositionUncuddled)
    ]
}

extension StaticOperatorRuleTests {
    static var allTests: [(String, (StaticOperatorRuleTests) -> () throws -> Void)] = [
        ("testWithDefaultConfiguration", testWithDefaultConfiguration)
    ]
}

extension StrictFilePrivateRuleTests {
    static var allTests: [(String, (StrictFilePrivateRuleTests) -> () throws -> Void)] = [
        ("testWithDefaultConfiguration", testWithDefaultConfiguration)
    ]
}

extension StrongIBOutletRuleTests {
    static var allTests: [(String, (StrongIBOutletRuleTests) -> () throws -> Void)] = [
        ("testWithDefaultConfiguration", testWithDefaultConfiguration)
    ]
}

extension SwitchCaseAlignmentRuleTests {
    static var allTests: [(String, (SwitchCaseAlignmentRuleTests) -> () throws -> Void)] = [
        ("testWithDefaultConfiguration", testWithDefaultConfiguration),
        ("testSwitchCaseAlignmentWithoutIndentedCases", testSwitchCaseAlignmentWithoutIndentedCases),
        ("testSwitchCaseAlignmentWithIndentedCases", testSwitchCaseAlignmentWithIndentedCases)
    ]
}

extension SwitchCaseOnNewlineRuleTests {
    static var allTests: [(String, (SwitchCaseOnNewlineRuleTests) -> () throws -> Void)] = [
        ("testWithDefaultConfiguration", testWithDefaultConfiguration)
    ]
}

extension SyntacticSugarRuleTests {
    static var allTests: [(String, (SyntacticSugarRuleTests) -> () throws -> Void)] = [
        ("testWithDefaultConfiguration", testWithDefaultConfiguration)
    ]
}

extension TodoRuleTests {
    static var allTests: [(String, (TodoRuleTests) -> () throws -> Void)] = [
        ("testTodo", testTodo),
        ("testTodoMessage", testTodoMessage),
        ("testFixMeMessage", testFixMeMessage)
    ]
}

extension ToggleBoolRuleTests {
    static var allTests: [(String, (ToggleBoolRuleTests) -> () throws -> Void)] = [
        ("testWithDefaultConfiguration", testWithDefaultConfiguration)
    ]
}

extension TrailingClosureConfigurationTests {
    static var allTests: [(String, (TrailingClosureConfigurationTests) -> () throws -> Void)] = [
        ("testDefaultConfiguration", testDefaultConfiguration),
        ("testApplyingCustomConfiguration", testApplyingCustomConfiguration)
    ]
}

extension TrailingClosureRuleTests {
    static var allTests: [(String, (TrailingClosureRuleTests) -> () throws -> Void)] = [
        ("testDefaultConfiguration", testDefaultConfiguration),
        ("testWithOnlySingleMutedParameterEnabled", testWithOnlySingleMutedParameterEnabled)
    ]
}

extension TrailingCommaRuleTests {
    static var allTests: [(String, (TrailingCommaRuleTests) -> () throws -> Void)] = [
        ("testTrailingCommaRuleWithDefaultConfiguration", testTrailingCommaRuleWithDefaultConfiguration),
        ("testTrailingCommaRuleWithMandatoryComma", testTrailingCommaRuleWithMandatoryComma)
    ]
}

extension TrailingSemicolonRuleTests {
    static var allTests: [(String, (TrailingSemicolonRuleTests) -> () throws -> Void)] = [
        ("testWithDefaultConfiguration", testWithDefaultConfiguration)
    ]
}

extension TrailingWhitespaceTests {
    static var allTests: [(String, (TrailingWhitespaceTests) -> () throws -> Void)] = [
        ("testWithDefaultConfiguration", testWithDefaultConfiguration),
        ("testWithIgnoresEmptyLinesEnabled", testWithIgnoresEmptyLinesEnabled),
        ("testWithIgnoresCommentsDisabled", testWithIgnoresCommentsDisabled)
    ]
}

extension TypeBodyLengthRuleTests {
    static var allTests: [(String, (TypeBodyLengthRuleTests) -> () throws -> Void)] = [
        ("testWithDefaultConfiguration", testWithDefaultConfiguration)
    ]
}

extension TypeContentsOrderRuleTests {
    static var allTests: [(String, (TypeContentsOrderRuleTests) -> () throws -> Void)] = [
        ("testTypeContentsOrderWithDefaultConfiguration", testTypeContentsOrderWithDefaultConfiguration),
        ("testTypeContentsOrderReversedOrder", testTypeContentsOrderReversedOrder),
        ("testTypeContentsOrderGroupedOrder", testTypeContentsOrderGroupedOrder)
    ]
}

extension TypeNameRuleTests {
    static var allTests: [(String, (TypeNameRuleTests) -> () throws -> Void)] = [
        ("testTypeName", testTypeName),
        ("testTypeNameWithAllowedSymbols", testTypeNameWithAllowedSymbols),
        ("testTypeNameWithAllowedSymbolsAndViolation", testTypeNameWithAllowedSymbolsAndViolation),
        ("testTypeNameWithIgnoreStartWithLowercase", testTypeNameWithIgnoreStartWithLowercase)
    ]
}

extension UnavailableFunctionRuleTests {
    static var allTests: [(String, (UnavailableFunctionRuleTests) -> () throws -> Void)] = [
        ("testWithDefaultConfiguration", testWithDefaultConfiguration)
    ]
}

extension UnneededBreakInSwitchRuleTests {
    static var allTests: [(String, (UnneededBreakInSwitchRuleTests) -> () throws -> Void)] = [
        ("testWithDefaultConfiguration", testWithDefaultConfiguration)
    ]
}

extension UnneededParenthesesInClosureArgumentRuleTests {
    static var allTests: [(String, (UnneededParenthesesInClosureArgumentRuleTests) -> () throws -> Void)] = [
        ("testWithDefaultConfiguration", testWithDefaultConfiguration)
    ]
}

extension UnownedVariableCaptureRuleTests {
    static var allTests: [(String, (UnownedVariableCaptureRuleTests) -> () throws -> Void)] = [
        ("testWithDefaultConfiguration", testWithDefaultConfiguration)
    ]
}

extension UntypedErrorInCatchRuleTests {
    static var allTests: [(String, (UntypedErrorInCatchRuleTests) -> () throws -> Void)] = [
        ("testWithDefaultConfiguration", testWithDefaultConfiguration)
    ]
}

extension UnusedCaptureListRuleTests {
    static var allTests: [(String, (UnusedCaptureListRuleTests) -> () throws -> Void)] = [
        ("testWithDefaultConfiguration", testWithDefaultConfiguration)
    ]
}

extension UnusedClosureParameterRuleTests {
    static var allTests: [(String, (UnusedClosureParameterRuleTests) -> () throws -> Void)] = [
        ("testWithDefaultConfiguration", testWithDefaultConfiguration)
    ]
}

extension UnusedControlFlowLabelRuleTests {
    static var allTests: [(String, (UnusedControlFlowLabelRuleTests) -> () throws -> Void)] = [
        ("testWithDefaultConfiguration", testWithDefaultConfiguration)
    ]
}

extension UnusedDeclarationRuleTests {
    static var allTests: [(String, (UnusedDeclarationRuleTests) -> () throws -> Void)] = [
        ("testWithDefaultConfiguration", testWithDefaultConfiguration)
    ]
}

extension UnusedEnumeratedRuleTests {
    static var allTests: [(String, (UnusedEnumeratedRuleTests) -> () throws -> Void)] = [
        ("testWithDefaultConfiguration", testWithDefaultConfiguration)
    ]
}

extension UnusedImportRuleTests {
    static var allTests: [(String, (UnusedImportRuleTests) -> () throws -> Void)] = [
        ("testWithDefaultConfiguration", testWithDefaultConfiguration)
    ]
}

extension UnusedOptionalBindingRuleTests {
    static var allTests: [(String, (UnusedOptionalBindingRuleTests) -> () throws -> Void)] = [
        ("testDefaultConfiguration", testDefaultConfiguration),
        ("testIgnoreOptionalTryEnabled", testIgnoreOptionalTryEnabled)
    ]
}

extension UnusedSetterValueRuleTests {
    static var allTests: [(String, (UnusedSetterValueRuleTests) -> () throws -> Void)] = [
        ("testWithDefaultConfiguration", testWithDefaultConfiguration)
    ]
}

extension ValidIBInspectableRuleTests {
    static var allTests: [(String, (ValidIBInspectableRuleTests) -> () throws -> Void)] = [
        ("testWithDefaultConfiguration", testWithDefaultConfiguration)
    ]
}

extension VerticalParameterAlignmentOnCallRuleTests {
    static var allTests: [(String, (VerticalParameterAlignmentOnCallRuleTests) -> () throws -> Void)] = [
        ("testWithDefaultConfiguration", testWithDefaultConfiguration)
    ]
}

extension VerticalParameterAlignmentRuleTests {
    static var allTests: [(String, (VerticalParameterAlignmentRuleTests) -> () throws -> Void)] = [
        ("testWithDefaultConfiguration", testWithDefaultConfiguration)
    ]
}

extension VerticalWhitespaceBetweenCasesRuleTests {
    static var allTests: [(String, (VerticalWhitespaceBetweenCasesRuleTests) -> () throws -> Void)] = [
        ("testWithDefaultConfiguration", testWithDefaultConfiguration)
    ]
}

extension VerticalWhitespaceClosingBracesRuleTests {
    static var allTests: [(String, (VerticalWhitespaceClosingBracesRuleTests) -> () throws -> Void)] = [
        ("testWithDefaultConfiguration", testWithDefaultConfiguration)
    ]
}

extension VerticalWhitespaceOpeningBracesRuleTests {
    static var allTests: [(String, (VerticalWhitespaceOpeningBracesRuleTests) -> () throws -> Void)] = [
        ("testWithDefaultConfiguration", testWithDefaultConfiguration)
    ]
}

extension VerticalWhitespaceRuleTests {
    static var allTests: [(String, (VerticalWhitespaceRuleTests) -> () throws -> Void)] = [
        ("testVerticalWhitespaceWithDefaultConfiguration", testVerticalWhitespaceWithDefaultConfiguration),
        ("testAttributesWithMaxEmptyLines", testAttributesWithMaxEmptyLines),
        ("testAutoCorrectionWithMaxEmptyLines", testAutoCorrectionWithMaxEmptyLines),
        ("testViolationMessageWithMaxEmptyLines", testViolationMessageWithMaxEmptyLines),
        ("testViolationMessageWithDefaultConfiguration", testViolationMessageWithDefaultConfiguration)
    ]
}

extension VoidReturnRuleTests {
    static var allTests: [(String, (VoidReturnRuleTests) -> () throws -> Void)] = [
        ("testWithDefaultConfiguration", testWithDefaultConfiguration)
    ]
}

extension WeakDelegateRuleTests {
    static var allTests: [(String, (WeakDelegateRuleTests) -> () throws -> Void)] = [
        ("testWithDefaultConfiguration", testWithDefaultConfiguration)
    ]
}

extension XCTFailMessageRuleTests {
    static var allTests: [(String, (XCTFailMessageRuleTests) -> () throws -> Void)] = [
        ("testWithDefaultConfiguration", testWithDefaultConfiguration)
    ]
}

extension XCTSpecificMatcherRuleTests {
    static var allTests: [(String, (XCTSpecificMatcherRuleTests) -> () throws -> Void)] = [
        ("testRule", testRule),
        ("testEqualTrue", testEqualTrue),
        ("testEqualFalse", testEqualFalse),
        ("testEqualNil", testEqualNil),
        ("testNotEqualTrue", testNotEqualTrue),
        ("testNotEqualFalse", testNotEqualFalse),
        ("testNotEqualNil", testNotEqualNil),
        ("testEqualOptionalFalse", testEqualOptionalFalse),
        ("testEqualUnwrappedOptionalFalse", testEqualUnwrappedOptionalFalse),
        ("testEqualNilNil", testEqualNilNil),
        ("testEqualTrueTrue", testEqualTrueTrue),
        ("testEqualFalseFalse", testEqualFalseFalse),
        ("testNotEqualNilNil", testNotEqualNilNil),
        ("testNotEqualTrueTrue", testNotEqualTrueTrue),
        ("testNotEqualFalseFalse", testNotEqualFalseFalse)
    ]
}

extension YamlParserTests {
    static var allTests: [(String, (YamlParserTests) -> () throws -> Void)] = [
        ("testParseEmptyString", testParseEmptyString),
        ("testParseValidString", testParseValidString),
        ("testParseReplacesEnvVar", testParseReplacesEnvVar),
        ("testParseTreatNoAsString", testParseTreatNoAsString),
        ("testParseTreatYesAsString", testParseTreatYesAsString),
        ("testParseTreatOnAsString", testParseTreatOnAsString),
        ("testParseTreatOffAsString", testParseTreatOffAsString),
        ("testParseInvalidStringThrows", testParseInvalidStringThrows)
    ]
}

extension YamlSwiftLintTests {
    static var allTests: [(String, (YamlSwiftLintTests) -> () throws -> Void)] = [
        ("testFlattenYaml", testFlattenYaml)
    ]
}

extension YodaConditionRuleTests {
    static var allTests: [(String, (YodaConditionRuleTests) -> () throws -> Void)] = [
        ("testWithDefaultConfiguration", testWithDefaultConfiguration)
    ]
}

XCTMain([
    testCase(AnyObjectProtocolRuleTests.allTests),
    testCase(ArrayInitRuleTests.allTests),
    testCase(AttributesRuleTests.allTests),
    testCase(BlockBasedKVORuleTests.allTests),
    testCase(ClassDelegateProtocolRuleTests.allTests),
    testCase(ClosingBraceRuleTests.allTests),
    testCase(ClosureBodyLengthRuleTests.allTests),
    testCase(ClosureEndIndentationRuleTests.allTests),
    testCase(ClosureParameterPositionRuleTests.allTests),
    testCase(ClosureSpacingRuleTests.allTests),
    testCase(CollectingRuleTests.allTests),
    testCase(CollectionAlignmentRuleTests.allTests),
    testCase(ColonRuleTests.allTests),
    testCase(CommaRuleTests.allTests),
    testCase(CommandTests.allTests),
    testCase(CompilerProtocolInitRuleTests.allTests),
    testCase(ConditionalReturnsOnNewlineRuleTests.allTests),
    testCase(ConfigurationAliasesTests.allTests),
    testCase(ConfigurationTests.allTests),
    testCase(ContainsOverFilterCountRuleTests.allTests),
    testCase(ContainsOverFilterIsEmptyRuleTests.allTests),
    testCase(ContainsOverFirstNotNilRuleTests.allTests),
    testCase(ContainsOverRangeNilComparisonRuleTests.allTests),
    testCase(ControlStatementRuleTests.allTests),
    testCase(ConvenienceTypeRuleTests.allTests),
    testCase(CustomRulesTests.allTests),
    testCase(CyclomaticComplexityConfigurationTests.allTests),
    testCase(CyclomaticComplexityRuleTests.allTests),
    testCase(DeploymentTargetConfigurationTests.allTests),
    testCase(DeploymentTargetRuleTests.allTests),
    testCase(DisableAllTests.allTests),
    testCase(DiscardedNotificationCenterObserverRuleTests.allTests),
    testCase(DiscouragedDirectInitRuleTests.allTests),
    testCase(DiscouragedObjectLiteralRuleTests.allTests),
    testCase(DiscouragedOptionalBooleanRuleTests.allTests),
    testCase(DiscouragedOptionalCollectionRuleTests.allTests),
    testCase(DocumentationTests.allTests),
    testCase(DuplicateEnumCasesRuleTests.allTests),
    testCase(DuplicateImportsRuleTests.allTests),
    testCase(DynamicInlineRuleTests.allTests),
    testCase(EmptyCollectionLiteralRuleTests.allTests),
    testCase(EmptyCountRuleTests.allTests),
    testCase(EmptyEnumArgumentsRuleTests.allTests),
    testCase(EmptyParametersRuleTests.allTests),
    testCase(EmptyParenthesesWithTrailingClosureRuleTests.allTests),
    testCase(EmptyStringRuleTests.allTests),
    testCase(EmptyXCTestMethodRuleTests.allTests),
    testCase(ExpiringTodoRuleTests.allTests),
    testCase(ExplicitACLRuleTests.allTests),
    testCase(ExplicitEnumRawValueRuleTests.allTests),
    testCase(ExplicitInitRuleTests.allTests),
    testCase(ExplicitSelfRuleTests.allTests),
    testCase(ExplicitTopLevelACLRuleTests.allTests),
    testCase(ExplicitTypeInterfaceConfigurationTests.allTests),
    testCase(ExplicitTypeInterfaceRuleTests.allTests),
    testCase(ExtendedNSStringTests.allTests),
    testCase(ExtensionAccessModifierRuleTests.allTests),
    testCase(FallthroughRuleTests.allTests),
    testCase(FatalErrorMessageRuleTests.allTests),
    testCase(FileHeaderRuleTests.allTests),
    testCase(FileLengthRuleTests.allTests),
    testCase(FileNameRuleTests.allTests),
    testCase(FileTypesOrderRuleTests.allTests),
    testCase(FirstWhereRuleTests.allTests),
    testCase(FlatMapOverMapReduceRuleTests.allTests),
    testCase(ForWhereRuleTests.allTests),
    testCase(ForceCastRuleTests.allTests),
    testCase(ForceTryRuleTests.allTests),
    testCase(ForceUnwrappingRuleTests.allTests),
    testCase(FunctionBodyLengthRuleTests.allTests),
    testCase(FunctionDefaultParameterAtEndRuleTests.allTests),
    testCase(FunctionParameterCountRuleTests.allTests),
    testCase(GenericTypeNameRuleTests.allTests),
    testCase(GlobTests.allTests),
    testCase(IdenticalOperandsRuleTests.allTests),
    testCase(IdentifierNameRuleTests.allTests),
    testCase(ImplicitGetterRuleTests.allTests),
    testCase(ImplicitReturnRuleTests.allTests),
    testCase(ImplicitlyUnwrappedOptionalConfigurationTests.allTests),
    testCase(ImplicitlyUnwrappedOptionalRuleTests.allTests),
    testCase(InertDeferRuleTests.allTests),
    testCase(IntegrationTests.allTests),
    testCase(IsDisjointRuleTests.allTests),
    testCase(JoinedDefaultParameterRuleTests.allTests),
    testCase(LargeTupleRuleTests.allTests),
    testCase(LastWhereRuleTests.allTests),
    testCase(LegacyCGGeometryFunctionsRuleTests.allTests),
    testCase(LegacyConstantRuleTests.allTests),
    testCase(LegacyConstructorRuleTests.allTests),
    testCase(LegacyHashingRuleTests.allTests),
    testCase(LegacyMultipleRuleTests.allTests),
    testCase(LegacyNSGeometryFunctionsRuleTests.allTests),
    testCase(LegacyRandomRuleTests.allTests),
    testCase(LetVarWhitespaceRuleTests.allTests),
    testCase(LineLengthConfigurationTests.allTests),
    testCase(LineLengthRuleTests.allTests),
    testCase(LinterCacheTests.allTests),
    testCase(LiteralExpressionEndIdentationRuleTests.allTests),
    testCase(LowerACLThanParentRuleTests.allTests),
    testCase(MissingDocsRuleConfigurationTests.allTests),
    testCase(MissingDocsRuleTests.allTests),
    testCase(ModifierOrderTests.allTests),
    testCase(MultilineArgumentsBracketsRuleTests.allTests),
    testCase(MultilineArgumentsRuleTests.allTests),
    testCase(MultilineFunctionChainsRuleTests.allTests),
    testCase(MultilineLiteralBracketsRuleTests.allTests),
    testCase(MultilineParametersBracketsRuleTests.allTests),
    testCase(MultilineParametersRuleTests.allTests),
    testCase(MultipleClosuresWithTrailingClosureRuleTests.allTests),
    testCase(NSLocalizedStringKeyRuleTests.allTests),
    testCase(NSLocalizedStringRequireBundleRuleTests.allTests),
    testCase(NSObjectPreferIsEqualRuleTests.allTests),
    testCase(NestingRuleTests.allTests),
    testCase(NimbleOperatorRuleTests.allTests),
    testCase(NoExtensionAccessModifierRuleTests.allTests),
    testCase(NoFallthroughOnlyRuleTests.allTests),
    testCase(NoGroupingExtensionRuleTests.allTests),
    testCase(NoSpaceInMethodCallRuleTests.allTests),
    testCase(NotificationCenterDetachmentRuleTests.allTests),
    testCase(NumberSeparatorRuleTests.allTests),
    testCase(ObjectLiteralRuleTests.allTests),
    testCase(OpeningBraceRuleTests.allTests),
    testCase(OperatorFunctionWhitespaceRuleTests.allTests),
    testCase(OperatorUsageWhitespaceRuleTests.allTests),
    testCase(OptionalEnumCaseMatchingRuleTests.allTests),
    testCase(OverriddenSuperCallRuleTests.allTests),
    testCase(OverrideInExtensionRuleTests.allTests),
    testCase(PatternMatchingKeywordsRuleTests.allTests),
    testCase(PrefixedTopLevelConstantRuleTests.allTests),
    testCase(PrivateActionRuleTests.allTests),
    testCase(PrivateOutletRuleTests.allTests),
    testCase(PrivateOverFilePrivateRuleTests.allTests),
    testCase(PrivateUnitTestRuleTests.allTests),
    testCase(ProhibitedInterfaceBuilderRuleTests.allTests),
    testCase(ProhibitedSuperRuleTests.allTests),
    testCase(ProtocolPropertyAccessorsOrderRuleTests.allTests),
    testCase(QuickDiscouragedCallRuleTests.allTests),
    testCase(QuickDiscouragedFocusedTestRuleTests.allTests),
    testCase(QuickDiscouragedPendingTestRuleTests.allTests),
    testCase(RawValueForCamelCasedCodableEnumRuleTests.allTests),
    testCase(ReduceBooleanRuleTests.allTests),
    testCase(ReduceIntoRuleTests.allTests),
    testCase(RedundantDiscardableLetRuleTests.allTests),
    testCase(RedundantNilCoalescingRuleTests.allTests),
    testCase(RedundantObjcAttributeRuleTests.allTests),
    testCase(RedundantOptionalInitializationRuleTests.allTests),
    testCase(RedundantSetAccessControlRuleTests.allTests),
    testCase(RedundantStringEnumValueRuleTests.allTests),
    testCase(RedundantTypeAnnotationRuleTests.allTests),
    testCase(RedundantVoidReturnRuleTests.allTests),
    testCase(RegionTests.allTests),
    testCase(ReporterTests.allTests),
    testCase(RequiredDeinitRuleTests.allTests),
    testCase(RequiredEnumCaseRuleTestCase.allTests),
    testCase(ReturnArrowWhitespaceRuleTests.allTests),
    testCase(RuleConfigurationTests.allTests),
    testCase(RuleTests.allTests),
    testCase(RulesTests.allTests),
    testCase(ShorthandOperatorRuleTests.allTests),
    testCase(SingleTestClassRuleTests.allTests),
    testCase(SortedFirstLastRuleTests.allTests),
    testCase(SortedImportsRuleTests.allTests),
    testCase(SourceKitCrashTests.allTests),
    testCase(StatementPositionRuleTests.allTests),
    testCase(StaticOperatorRuleTests.allTests),
    testCase(StrictFilePrivateRuleTests.allTests),
    testCase(StrongIBOutletRuleTests.allTests),
    testCase(SwitchCaseAlignmentRuleTests.allTests),
    testCase(SwitchCaseOnNewlineRuleTests.allTests),
    testCase(SyntacticSugarRuleTests.allTests),
    testCase(TodoRuleTests.allTests),
    testCase(ToggleBoolRuleTests.allTests),
    testCase(TrailingClosureConfigurationTests.allTests),
    testCase(TrailingClosureRuleTests.allTests),
    testCase(TrailingCommaRuleTests.allTests),
    testCase(TrailingSemicolonRuleTests.allTests),
    testCase(TrailingWhitespaceTests.allTests),
    testCase(TypeBodyLengthRuleTests.allTests),
    testCase(TypeContentsOrderRuleTests.allTests),
    testCase(TypeNameRuleTests.allTests),
    testCase(UnavailableFunctionRuleTests.allTests),
    testCase(UnneededBreakInSwitchRuleTests.allTests),
    testCase(UnneededParenthesesInClosureArgumentRuleTests.allTests),
    testCase(UnownedVariableCaptureRuleTests.allTests),
    testCase(UntypedErrorInCatchRuleTests.allTests),
    testCase(UnusedCaptureListRuleTests.allTests),
    testCase(UnusedClosureParameterRuleTests.allTests),
    testCase(UnusedControlFlowLabelRuleTests.allTests),
    testCase(UnusedDeclarationRuleTests.allTests),
    testCase(UnusedEnumeratedRuleTests.allTests),
    testCase(UnusedImportRuleTests.allTests),
    testCase(UnusedOptionalBindingRuleTests.allTests),
    testCase(UnusedSetterValueRuleTests.allTests),
    testCase(ValidIBInspectableRuleTests.allTests),
    testCase(VerticalParameterAlignmentOnCallRuleTests.allTests),
    testCase(VerticalParameterAlignmentRuleTests.allTests),
    testCase(VerticalWhitespaceBetweenCasesRuleTests.allTests),
    testCase(VerticalWhitespaceClosingBracesRuleTests.allTests),
    testCase(VerticalWhitespaceOpeningBracesRuleTests.allTests),
    testCase(VerticalWhitespaceRuleTests.allTests),
    testCase(VoidReturnRuleTests.allTests),
    testCase(WeakDelegateRuleTests.allTests),
    testCase(XCTFailMessageRuleTests.allTests),
    testCase(XCTSpecificMatcherRuleTests.allTests),
    testCase(YamlParserTests.allTests),
    testCase(YamlSwiftLintTests.allTests),
    testCase(YodaConditionRuleTests.allTests)
])
