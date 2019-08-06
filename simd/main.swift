//
//  main.swift
//  simd
//
//  Created by Florian Kugler on 06-08-2019.
//  Copyright © 2019 Florian Kugler. All rights reserved.
//

import Foundation

extension UInt64: Collection {
    public var startIndex: Int { return 0 }
    public var endIndex: Int { return 64 }
    public func index(after i: Int) -> Int {
        return i + 1
    }
    public subscript(_ idx: Int) -> Int {
        return self & (1 << idx) != 0 ? 1 : 0
    }
}

extension UInt64: CustomDebugStringConvertible {
    public var debugDescription: String {
        return map(String.init).joined()
    }
}

let csv = "{ \"\\\\\\\"Nam[{\": [ 116,\"\\\\\\\\\" , 234, \"true\", false ], \"t\":\"\\\\\\\"\" }"
let data = csv.data(using: .ascii)!
assert(data.count == 64)

let bytes = Array(data)
let input = fill_input(bytes)
let result = cmp_mask_against_input(input, 92)

print(result.debugDescription)
