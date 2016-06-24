//
//  TestBundle.swift
//  SwiftLint
//
//  Created by Sash Zats on 6/24/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation

// marker used to find our bundle
private class MarkerClass { }

let testBundle = NSBundle(forClass: MarkerClass.self)
