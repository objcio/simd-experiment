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

func controlCharacterMask(for data: UnsafePointer<UInt8>, inQuotes: inout Bool) -> (commas: UInt64, newlines: UInt64) {
    let q = cmp_mask_against_input(data, 34)
    let c = cmp_mask_against_input(data, 44)
    let n = cmp_mask_against_input(data, 10)

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


public func parseCSV(data: Data) -> [[String]] {
    var commas: [Int] = []
    commas.reserveCapacity(1000)
    var newlines: [Int] = []
    newlines.reserveCapacity(1000)
    var inQuotes = false

    data.withUnsafeBytes { buf in
        for start in stride(from: 0, to: buf.count, by: 64) {
            let end = min(buf.count, start + 64)
            var ptr = buf.baseAddress!.assumingMemoryBound(to: UInt8.self) + start
            if end - start < 64 {
                let new = UnsafeMutablePointer<UInt8>.allocate(capacity: 64)
                new.initialize(repeating: 0, count: 64)
                new.assign(from: buf.baseAddress!.assumingMemoryBound(to: UInt8.self) + start, count: end - start)
                ptr = UnsafePointer(new)
            }
            let result = controlCharacterMask(for: ptr, inQuotes: &inQuotes)
            commas.append(contentsOf: result.commas.oneIndices(offset: start))
            newlines.append(contentsOf: result.newlines.oneIndices(offset: start))
        }
    }

    var commas2 = commas[...] + [data.count]
    var result: [[String]] = []
    result.reserveCapacity(1000)
    var lineStart = 0
    for lineEnd in newlines + [data.count] {
        guard lineStart < lineEnd else { break }
        var fields: [String] = []
        fields.reserveCapacity(16)
        var fieldStart = lineStart
        while let commaIdx = commas2.first, commaIdx <= lineEnd {
            fields.append(String(data: data[fieldStart..<commaIdx], encoding: .utf8)!)
            commas2.removeFirst()
            fieldStart = commaIdx + 1
        }
        result.append(fields)
        lineStart = lineEnd + 1
    }
    return result
}

import AppKit

@discardableResult
func measure<A>(name: String = "", _ block: () -> A) -> A {
    let startTime = CACurrentMediaTime()
    let result = block()
    let timeElapsed = CACurrentMediaTime() - startTime
    print("Time: \(name) - \(timeElapsed)")
    return result
}

let csv = #"""
"Fiel,d 1","Field with ""quotes""","""""qu,otes""""","kajhsdkahdakshdkajdhkj",",,,,"
"Another line", "with , commas, in fields", "and ""escaped quotes"""
"""#
//let data = csv.data(using: .ascii)!
let data = try! Data(contentsOf: URL(fileURLWithPath: "/Users/florian/Downloads/stops.txt"))
measure {
    _ = parseCSV(data: data)
}
//dump(parseCSV(data: data))
