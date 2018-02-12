//
//  LinuxMain.swift
//  SwiftLint
//
//  Created by JP Simard on 12/11/16.
//  Copyright © 2016 Realm. All rights reserved.
//
// Generated using Sourcery 0.10.1 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

@testable import SwiftLintFrameworkTests
import XCTest

// swiftlint:disable line_length file_length

extension AttributesRuleTests {
    static var allTests: [(String, (AttributesRuleTests) -> () throws -> Void)] = [
        ("testAttributesWithDefaultConfiguration", testAttributesWithDefaultConfiguration),
        ("testAttributesWithAlwaysOnSameLine", testAttributesWithAlwaysOnSameLine),
        ("testAttributesWithAlwaysOnLineAbove", testAttributesWithAlwaysOnLineAbove)
    ]
}

extension ColonRuleTests {
    static var allTests: [(String, (ColonRuleTests) -> () throws -> Void)] = [
        ("testColonWithDefaultConfiguration", testColonWithDefaultConfiguration),
        ("testColonWithFlexibleRightSpace", testColonWithFlexibleRightSpace),
        ("testColonWithoutApplyToDictionaries", testColonWithoutApplyToDictionaries)
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
        ("testActionInverse", testActionInverse),
        ("testNoModifierCommandExpandsToItself", testNoModifierCommandExpandsToItself),
        ("testExpandPreviousCommand", testExpandPreviousCommand),
        ("testExpandThisCommand", testExpandThisCommand),
        ("testExpandNextCommand", testExpandNextCommand),
        ("testSuperfluousDisableCommands", testSuperfluousDisableCommands),
        ("testSuperfluousDisableCommandsDisabled", testSuperfluousDisableCommandsDisabled),
        ("testSuperfluousDisableCommandsDisabledOnConfiguration", testSuperfluousDisableCommandsDisabledOnConfiguration)
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
        ("testLintablePaths", testLintablePaths),
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
        ("testConfiguresCorrectlyFromDeprecatedAlias", testConfiguresCorrectlyFromDeprecatedAlias),
        ("testReturnsNilWithDuplicatedConfiguration", testReturnsNilWithDuplicatedConfiguration),
        ("testInitsFromDeprecatedAlias", testInitsFromDeprecatedAlias),
        ("testWhitelistRulesFromDeprecatedAlias", testWhitelistRulesFromDeprecatedAlias),
        ("testDisabledRulesFromDeprecatedAlias", testDisabledRulesFromDeprecatedAlias),
        ("testMerge", testMerge),
        ("testLevel0", testLevel0),
        ("testLevel1", testLevel1),
        ("testLevel2", testLevel2),
        ("testLevel3", testLevel3),
        ("testNestedConfigurationWithCustomRootPath", testNestedConfigurationWithCustomRootPath),
        ("testMergedWarningThreshold", testMergedWarningThreshold),
        ("testNestedWhitelistedRules", testNestedWhitelistedRules)
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

extension DiscouragedDirectInitRuleTests {
    static var allTests: [(String, (DiscouragedDirectInitRuleTests) -> () throws -> Void)] = [
        ("testDiscouragedDirectInitWithDefaultConfiguration", testDiscouragedDirectInitWithDefaultConfiguration),
        ("testDiscouragedDirectInitWithConfiguredSeverity", testDiscouragedDirectInitWithConfiguredSeverity),
        ("testDiscouragedDirectInitWithNewIncludedTypes", testDiscouragedDirectInitWithNewIncludedTypes),
        ("testDiscouragedDirectInitWithReplacedTypes", testDiscouragedDirectInitWithReplacedTypes)
    ]
}

extension DocumentationTests {
    static var allTests: [(String, (DocumentationTests) -> () throws -> Void)] = [
    ]
}

extension ExtendedNSStringTests {
    static var allTests: [(String, (ExtendedNSStringTests) -> () throws -> Void)] = [
        ("testLineAndCharacterForByteOffset_forContentsContainingMultibyteCharacters", testLineAndCharacterForByteOffset_forContentsContainingMultibyteCharacters)
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
        ("testFileHeaderWithForbiddenPatternAndDocComment", testFileHeaderWithForbiddenPatternAndDocComment)
    ]
}

extension FileLengthRuleTests {
    static var allTests: [(String, (FileLengthRuleTests) -> () throws -> Void)] = [
        ("testFileLengthWithDefaultConfiguration", testFileLengthWithDefaultConfiguration),
        ("testFileLengthIgnoringLinesWithOnlyComments", testFileLengthIgnoringLinesWithOnlyComments)
    ]
}

extension FunctionBodyLengthRuleTests {
    static var allTests: [(String, (FunctionBodyLengthRuleTests) -> () throws -> Void)] = [
        ("testFunctionBodyLengths", testFunctionBodyLengths),
        ("testFunctionBodyLengthsWithComments", testFunctionBodyLengthsWithComments),
        ("testFunctionBodyLengthsWithMultilineComments", testFunctionBodyLengthsWithMultilineComments)
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

extension IdentifierNameRuleTests {
    static var allTests: [(String, (IdentifierNameRuleTests) -> () throws -> Void)] = [
        ("testIdentifierName", testIdentifierName),
        ("testIdentifierNameWithAllowedSymbols", testIdentifierNameWithAllowedSymbols),
        ("testIdentifierNameWithAllowedSymbolsAndViolation", testIdentifierNameWithAllowedSymbolsAndViolation),
        ("testIdentifierNameWithIgnoreStartWithLowercase", testIdentifierNameWithIgnoreStartWithLowercase)
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
        ("testImplicitlyUnwrappedOptionalRuleDefaultConfiguration", testImplicitlyUnwrappedOptionalRuleDefaultConfiguration),
        ("testImplicitlyUnwrappedOptionalRuleWarnsOnOutletsInAllMode", testImplicitlyUnwrappedOptionalRuleWarnsOnOutletsInAllMode)
    ]
}

extension IntegrationTests {
    static var allTests: [(String, (IntegrationTests) -> () throws -> Void)] = [
        ("testSwiftLintLints", testSwiftLintLints),
        ("testSwiftLintAutoCorrects", testSwiftLintAutoCorrects)
    ]
}

extension LineLengthConfigurationTests {
    static var allTests: [(String, (LineLengthConfigurationTests) -> () throws -> Void)] = [
        ("testLineLengthConfigurationInitializerSetsLength", testLineLengthConfigurationInitializerSetsLength),
        ("testLineLengthConfigurationInitialiserSetsIgnoresURLs", testLineLengthConfigurationInitialiserSetsIgnoresURLs),
        ("testLineLengthConfigurationInitialiserSetsIgnoresFunctionDeclarations", testLineLengthConfigurationInitialiserSetsIgnoresFunctionDeclarations),
        ("testLineLengthConfigurationInitialiserSetsIgnoresComments", testLineLengthConfigurationInitialiserSetsIgnoresComments),
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
        ("testLineLengthWithIgnoreURLsEnabled", testLineLengthWithIgnoreURLsEnabled)
    ]
}

extension LinterCacheTests {
    static var allTests: [(String, (LinterCacheTests) -> () throws -> Void)] = [
        ("testInitThrowsWhenUsingInvalidCacheFormat", testInitThrowsWhenUsingInvalidCacheFormat),
        ("testSaveThrowsWithNoLocation", testSaveThrowsWithNoLocation),
        ("testInitSucceeds", testInitSucceeds),
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

extension MultilineArgumentsRuleTests {
    static var allTests: [(String, (MultilineArgumentsRuleTests) -> () throws -> Void)] = [
        ("testMultilineArgumentsWithDefaultConfiguration", testMultilineArgumentsWithDefaultConfiguration),
        ("testMultilineArgumentsWithWithNextLine", testMultilineArgumentsWithWithNextLine),
        ("testMultilineArgumentsWithWithSameLine", testMultilineArgumentsWithWithSameLine)
    ]
}

extension NumberSeparatorRuleTests {
    static var allTests: [(String, (NumberSeparatorRuleTests) -> () throws -> Void)] = [
        ("testNumberSeparatorWithDefaultConfiguration", testNumberSeparatorWithDefaultConfiguration),
        ("testNumberSeparatorWithMinimumLength", testNumberSeparatorWithMinimumLength),
        ("testNumberSeparatorWithMinimumFractionLength", testNumberSeparatorWithMinimumFractionLength)
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

extension PrivateOverFilePrivateRuleTests {
    static var allTests: [(String, (PrivateOverFilePrivateRuleTests) -> () throws -> Void)] = [
        ("testPrivateOverFilePrivateWithDefaultConfiguration", testPrivateOverFilePrivateWithDefaultConfiguration),
        ("testPrivateOverFilePrivateValidatingExtensions", testPrivateOverFilePrivateValidatingExtensions),
        ("testPrivateOverFilePrivateNotValidatingExtensions", testPrivateOverFilePrivateNotValidatingExtensions)
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
        ("testJSONReporter", testJSONReporter),
        ("testCSVReporter", testCSVReporter),
        ("testCheckstyleReporter", testCheckstyleReporter),
        ("testJunitReporter", testJunitReporter),
        ("testHTMLReporter", testHTMLReporter)
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

extension RuleConfigurationsTests {
    static var allTests: [(String, (RuleConfigurationsTests) -> () throws -> Void)] = [
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
        ("testOverridenSuperCallConfigurationFromDictionary", testOverridenSuperCallConfigurationFromDictionary)
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
        ("testArrayInit", testArrayInit),
        ("testBlockBasedKVO", testBlockBasedKVO),
        ("testClassDelegateProtocol", testClassDelegateProtocol),
        ("testClosingBrace", testClosingBrace),
        ("testClosureEndIndentation", testClosureEndIndentation),
        ("testClosureParameterPosition", testClosureParameterPosition),
        ("testClosureSpacing", testClosureSpacing),
        ("testComma", testComma),
        ("testCompilerProtocolInit", testCompilerProtocolInit),
        ("testConditionalReturnsOnNewline", testConditionalReturnsOnNewline),
        ("testContainsOverFirstNotNil", testContainsOverFirstNotNil),
        ("testControlStatement", testControlStatement),
        ("testCyclomaticComplexity", testCyclomaticComplexity),
        ("testDiscardedNotificationCenterObserver", testDiscardedNotificationCenterObserver),
        ("testDiscouragedObjectLiteral", testDiscouragedObjectLiteral),
        ("testDiscouragedOptionalBoolean", testDiscouragedOptionalBoolean),
        ("testDynamicInline", testDynamicInline),
        ("testEmptyCount", testEmptyCount),
        ("testEmptyEnumArguments", testEmptyEnumArguments),
        ("testEmptyParameters", testEmptyParameters),
        ("testEmptyParenthesesWithTrailingClosure", testEmptyParenthesesWithTrailingClosure),
        ("testExplicitACL", testExplicitACL),
        ("testExplicitEnumRawValue", testExplicitEnumRawValue),
        ("testExplicitInit", testExplicitInit),
        ("testExplicitTopLevelACL", testExplicitTopLevelACL),
        ("testExplicitTypeInterface", testExplicitTypeInterface),
        ("testExtensionAccessModifier", testExtensionAccessModifier),
        ("testFallthrough", testFallthrough),
        ("testFatalErrorMessage", testFatalErrorMessage),
        ("testFirstWhere", testFirstWhere),
        ("testForceCast", testForceCast),
        ("testForceTry", testForceTry),
        ("testForceUnwrapping", testForceUnwrapping),
        ("testForWhere", testForWhere),
        ("testFunctionBodyLength", testFunctionBodyLength),
        ("testFunctionParameterCount", testFunctionParameterCount),
        ("testImplicitGetter", testImplicitGetter),
        ("testImplicitlyUnwrappedOptional", testImplicitlyUnwrappedOptional),
        ("testImplicitReturn", testImplicitReturn),
        ("testIsDisjoint", testIsDisjoint),
        ("testJoinedDefaultParameter", testJoinedDefaultParameter),
        ("testLargeTuple", testLargeTuple),
        ("testLeadingWhitespace", testLeadingWhitespace),
        ("testLegacyCGGeometryFunctions", testLegacyCGGeometryFunctions),
        ("testLegacyNSGeometryFunctions", testLegacyNSGeometryFunctions),
        ("testLegacyConstant", testLegacyConstant),
        ("testLegacyConstructor", testLegacyConstructor),
        ("testLetVarWhitespace", testLetVarWhitespace),
        ("testLiteralExpressionEndIdentation", testLiteralExpressionEndIdentation),
        ("testMark", testMark),
        ("testMultilineParameters", testMultilineParameters),
        ("testMultipleClosuresWithTrailingClosure", testMultipleClosuresWithTrailingClosure),
        ("testNesting", testNesting),
        ("testNoExtensionAccessModifier", testNoExtensionAccessModifier),
        ("testNoGroupingExtension", testNoGroupingExtension),
        ("testNotificationCenterDetachment", testNotificationCenterDetachment),
        ("testNimbleOperator", testNimbleOperator),
        ("testOpeningBrace", testOpeningBrace),
        ("testOperatorFunctionWhitespace", testOperatorFunctionWhitespace),
        ("testOperatorUsageWhitespace", testOperatorUsageWhitespace),
        ("testOverrideInExtension", testOverrideInExtension),
        ("testPatternMatchingKeywords", testPatternMatchingKeywords),
        ("testPrefixedTopLevelConstant", testPrefixedTopLevelConstant),
        ("testPrivateAction", testPrivateAction),
        ("testPrivateOutlet", testPrivateOutlet),
        ("testPrivateUnitTest", testPrivateUnitTest),
        ("testProhibitedSuper", testProhibitedSuper),
        ("testProtocolPropertyAccessorsOrder", testProtocolPropertyAccessorsOrder),
        ("testQuickDiscouragedCall", testQuickDiscouragedCall),
        ("testQuickDiscouragedFocusedTest", testQuickDiscouragedFocusedTest),
        ("testQuickDiscouragedPendingTest", testQuickDiscouragedPendingTest),
        ("testRedundantDiscardableLet", testRedundantDiscardableLet),
        ("testRedundantNilCoalescing", testRedundantNilCoalescing),
        ("testRedundantOptionalInitialization", testRedundantOptionalInitialization),
        ("testRedundantStringEnumValue", testRedundantStringEnumValue),
        ("testRedundantVoidReturn", testRedundantVoidReturn),
        ("testRequiredEnumCase", testRequiredEnumCase),
        ("testReturnArrowWhitespace", testReturnArrowWhitespace),
        ("testShorthandOperator", testShorthandOperator),
        ("testSingleTestClass", testSingleTestClass),
        ("testSortedFirstLast", testSortedFirstLast),
        ("testSortedImports", testSortedImports),
        ("testStatementPosition", testStatementPosition),
        ("testStatementPositionUncuddled", testStatementPositionUncuddled),
        ("testStrictFilePrivate", testStrictFilePrivate),
        ("testSwitchCaseAlignment", testSwitchCaseAlignment),
        ("testSwitchCaseOnNewline", testSwitchCaseOnNewline),
        ("testSyntacticSugar", testSyntacticSugar),
        ("testTrailingClosure", testTrailingClosure),
        ("testTrailingNewline", testTrailingNewline),
        ("testTrailingSemicolon", testTrailingSemicolon),
        ("testTrailingWhitespace", testTrailingWhitespace),
        ("testTypeBodyLength", testTypeBodyLength),
        ("testUnneededBreakInSwitch", testUnneededBreakInSwitch),
        ("testUnneededParenthesesInClosureArgument", testUnneededParenthesesInClosureArgument),
        ("testUnusedClosureParameter", testUnusedClosureParameter),
        ("testUnusedEnumerated", testUnusedEnumerated),
        ("testValidIBInspectable", testValidIBInspectable),
        ("testVerticalParameterAlignmentOnCall", testVerticalParameterAlignmentOnCall),
        ("testVerticalParameterAlignment", testVerticalParameterAlignment),
        ("testVoidReturn", testVoidReturn),
        ("testSuperCall", testSuperCall),
        ("testWeakDelegate", testWeakDelegate),
        ("testXCTFailMessage", testXCTFailMessage),
        ("testYodaCondition", testYodaCondition)
    ]
}

extension SourceKitCrashTests {
    static var allTests: [(String, (SourceKitCrashTests) -> () throws -> Void)] = [
        ("testAssertHandlerIsNotCalledOnNormalFile", testAssertHandlerIsNotCalledOnNormalFile),
        ("testAssertHandlerIsCalledOnFileThatCrashedSourceKitService", testAssertHandlerIsCalledOnFileThatCrashedSourceKitService),
        ("testRulesWithFileThatCrashedSourceKitService", testRulesWithFileThatCrashedSourceKitService)
    ]
}

extension TodoRuleTests {
    static var allTests: [(String, (TodoRuleTests) -> () throws -> Void)] = [
        ("testTodo", testTodo),
        ("testTodoMessage", testTodoMessage),
        ("testFixMeMessage", testFixMeMessage)
    ]
}

extension TrailingCommaRuleTests {
    static var allTests: [(String, (TrailingCommaRuleTests) -> () throws -> Void)] = [
        ("testTrailingCommaRuleWithDefaultConfiguration", testTrailingCommaRuleWithDefaultConfiguration),
        ("testTrailingCommaRuleWithMandatoryComma", testTrailingCommaRuleWithMandatoryComma)
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

extension UnusedOptionalBindingRuleTests {
    static var allTests: [(String, (UnusedOptionalBindingRuleTests) -> () throws -> Void)] = [
        ("testDefaultConfiguration", testDefaultConfiguration),
        ("testIgnoreOptionalTryEnabled", testIgnoreOptionalTryEnabled)
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

XCTMain([
    testCase(AttributesRuleTests.allTests),
    testCase(ColonRuleTests.allTests),
    testCase(CommandTests.allTests),
    testCase(ConfigurationTests.allTests),
    testCase(CustomRulesTests.allTests),
    testCase(CyclomaticComplexityConfigurationTests.allTests),
    testCase(CyclomaticComplexityRuleTests.allTests),
    testCase(DiscouragedDirectInitRuleTests.allTests),
    testCase(DocumentationTests.allTests),
    testCase(ExtendedNSStringTests.allTests),
    testCase(FileHeaderRuleTests.allTests),
    testCase(FileLengthRuleTests.allTests),
    testCase(FunctionBodyLengthRuleTests.allTests),
    testCase(GenericTypeNameRuleTests.allTests),
    testCase(IdentifierNameRuleTests.allTests),
    testCase(ImplicitlyUnwrappedOptionalConfigurationTests.allTests),
    testCase(ImplicitlyUnwrappedOptionalRuleTests.allTests),
    testCase(IntegrationTests.allTests),
    testCase(LineLengthConfigurationTests.allTests),
    testCase(LineLengthRuleTests.allTests),
    testCase(LinterCacheTests.allTests),
    testCase(MultilineArgumentsRuleTests.allTests),
    testCase(NumberSeparatorRuleTests.allTests),
    testCase(ObjectLiteralRuleTests.allTests),
    testCase(PrivateOverFilePrivateRuleTests.allTests),
    testCase(RegionTests.allTests),
    testCase(ReporterTests.allTests),
    testCase(RequiredEnumCaseRuleTestCase.allTests),
    testCase(RuleConfigurationsTests.allTests),
    testCase(RuleTests.allTests),
    testCase(RulesTests.allTests),
    testCase(SourceKitCrashTests.allTests),
    testCase(TodoRuleTests.allTests),
    testCase(TrailingCommaRuleTests.allTests),
    testCase(TypeNameRuleTests.allTests),
    testCase(UnusedOptionalBindingRuleTests.allTests),
    testCase(VerticalWhitespaceRuleTests.allTests),
    testCase(YamlParserTests.allTests),
    testCase(YamlSwiftLintTests.allTests)
])
