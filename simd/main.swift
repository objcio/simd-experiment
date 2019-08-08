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

    func oneIndices(offset: Int = 0) -> [Int] {
        var result: [Int] = []
        result.reserveCapacity(16)
        for idx in 0..<64 {
            if self & 1 << idx != 0 {
                result.append(idx + offset)
            }
        }
        return result
    }
}

extension Data {
    func paddedPrefix(_ length: Int) -> Data {
        var chunk = prefix(length)
        if chunk.count < length {
            chunk += Data(repeating: 0, count: length-chunk.count)
        }
        return chunk
    }
}

func controlCharacterMask(for data: Data, inQuotes: inout Bool) -> (commas: UInt64, newlines: UInt64) {
    let (q, c, n): (UInt64, UInt64, UInt64) = data.withUnsafeBytes { bytes in
        return (cmp_mask_against_input(bytes, 34), cmp_mask_against_input(bytes, 44), cmp_mask_against_input(bytes, 10))
    }

    let s = q & ~(q << 1)

    let e: UInt64 = (0...63).reduce(0) { result, idx in idx % 2 == 0 ? result | (1 << idx) : result }
    let o = ~e

    let es = s & e
    let ec = q &+ es
    let ece = ec & ~q
    let od1 = ece & ~e

    let os = s & o
    let oc = q &+ os
    let oce = oc & ~q
    let od2 = oce & e

    let od = od1 | od2

    let stringMask = carryless_multiply(od, ~0)

    let finalMask = inQuotes ? stringMask : ~stringMask
    let cq = c & finalMask
    let nq = n & finalMask
    if cq.nonzeroBitCount % 2 != 0 {
        inQuotes.toggle()
    }
    return (cq, nq)
}

let csv = #"""
"Fiel,d 1","Field with ""quotes""","""""qu,otes""""","kajhsdkahdakshdkajdhkj",",,,,"
"Another line", "with , commas, in fields", "and ""escaped quotes"""
"""#
//let data = csv.data(using: .ascii)!
let data = try! Data(contentsOf: URL(fileURLWithPath: "/Users/florian/Downloads/stops.txt"))

var commas: [Int] = []
commas.reserveCapacity(1000)
var newlines: [Int] = []
newlines.reserveCapacity(1000)
var inQuotes = false

for start in stride(from: 0, to: data.count, by: 64) {
    let end = min(data.count, start + 64)
    let chunk = data[start..<end].paddedPrefix(64)
    let result = controlCharacterMask(for: chunk, inQuotes: &inQuotes)
    commas.append(contentsOf: result.commas.oneIndices(offset: start))
    newlines.append(contentsOf: result.newlines.oneIndices(offset: start))
}

//print(newlines)
//print(commas)

//print(csv)

var result: [String] = []
for range in zip([0] + commas.map { $0 + 1 }, commas + [data.count]) {
//    print(range)
    result.append(String(data: data[range.0..<range.1], encoding: .utf8)!)
}
print(result.count)
