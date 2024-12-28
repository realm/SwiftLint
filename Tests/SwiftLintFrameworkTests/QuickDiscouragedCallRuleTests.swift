//
//  QuickDiscouragedCallRuleTests.swift
//  SwiftLint
//
//  Created by Omer Murat Aydin on 28.12.2024.
//

@testable import SwiftLintBuiltInRules
import XCTest
@testable import SwiftLintFramework

class QuickDiscouragedCallRuleTests: XCTestCase {
    
    func lint(_ content: String) -> [StyleViolation] {
        let file = SwiftLintFile(contents: content)
        return QuickDiscouragedCallRule().validate(file: file)
    }

    
    
    
    func testQuickDiscouragedCallRule() {
        // Örnek doğru kullanım (uyarı tetiklenmemeli)
        let nonTriggeringExamples = [
            "@TestState var foo = Foo()" // Bu uyarı vermemeli
        ]

        // Örnek yanlış kullanım (uyarı tetiklemeli)
        let triggeringExamples = [
            "describe(\"foo\") { @TestState var foo = Foo() }"
        ]

        // Doğru kullanım testi
        nonTriggeringExamples.forEach { example in
            XCTAssertEqual(lint(example), [])
        }

        // Yanlış kullanım testi
        triggeringExamples.forEach { example in
            XCTAssertFalse(lint(example).isEmpty)
        }
    }
}
