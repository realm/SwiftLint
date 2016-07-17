//
//  Result+Assertions.swift
//  SwiftLint
//
//  Created by Sash Zats on 6/22/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Result
import XCTest

func assertResultSuccess<T: Equatable, E: ErrorType>(result: Result<T, E>, _ value: T,
                         file: StaticString = #file, line: UInt = #line) {
    switch result {
    case let .Success(value1):
        XCTAssertEqual(value1, value, file: file, line: line)
    case let .Failure(error):
        XCTFail("\(error)", file: file, line: line)
    }
}

func assertResultSuccess<T: Equatable, E: ErrorType>(result: Result<T, E>,
                         @noescape _ predicate: ((T) -> Bool),
                         file: StaticString = #file, line: UInt = #line) {
    switch result {
    case let .Success(value1):
        XCTAssertTrue(predicate(value1), file: file, line: line)
    case let .Failure(error):
        XCTFail("\(error)", file: file, line: line)
    }
}
