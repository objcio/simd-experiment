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

let (b, q): (UInt64, UInt64) = data.withUnsafeBytes { bytes in
    let input = fill_input(bytes.baseAddress!.assumingMemoryBound(to: UInt8.self))
    return (cmp_mask_against_input(input, 92), cmp_mask_against_input(input, 34))
}

print(csv)
print(b.debugDescription)

let s = b & ~(b << 1)
print(s.debugDescription)

let e: UInt64 = (0...63).reduce(0) { result, idx in idx % 2 == 0 ? result | (1 << idx) : result }
let o = ~e

let es = s & e
print(es.debugDescription)

let ec = b + es
print(ec.debugDescription)

let ece = ec & ~b
print(ece.debugDescription)

let od1 = ece & ~e
print(od1.debugDescription)

let os = s & o
let oc = b + os
let oce = oc & ~b
let od2 = oce & e

let od = od1 | od2

print(od.debugDescription)

print("---")

print(csv)
print(q.debugDescription)

let cq = q & ~od
print(cq.debugDescription)

let result = carryless_multiply(cq, ~0)
print(result.debugDescription)
