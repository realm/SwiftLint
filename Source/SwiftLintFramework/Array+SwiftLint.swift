//
//  Array+SwiftLint.swift
//  SwiftLint
//
//  Created by Aaron Daub on 2015-05-20.
//  Copyright (c) 2015 Realm. All rights reserved.
//

import Foundation

func flatten<T>(array: [T?]) -> [T] {
  return array.reduce([]){
    if let e = $1 {
      return $0 + [e]
    }
    return $0
  }
}

func flatten<T>(nestedArray: [[T]]) -> [T] {
  return reduce(nestedArray, [], +)
}
