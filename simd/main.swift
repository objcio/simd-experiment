//
//  main.swift
//  simd
//
//  Created by Florian Kugler on 06-08-2019.
//  Copyright © 2019 Florian Kugler. All rights reserved.
//

import Foundation

extension UInt64: Collection, CustomDebugStringConvertible {
    public var startIndex: Int { return 0 }
    public var endIndex: Int { return 64 }

    public func index(after i: Int) -> Int {
        return i + 1
    }

    public subscript(_ idx: Int) -> Int {
        return self & (1 << idx) != 0 ? 1 : 0
    }

    public var debugDescription: String {
        return map(String.init).joined()
    }
}

extension UInt64 {
    func oneIndices(offset: Int = 0, appendTo result: inout [Int]) {
        for idx in 0..<64 {
            if self & 1 << idx != 0 {
                result.append(idx + offset)
            }
        }
    }
}

let evens: UInt64 = (0...63).reduce(0) { result, idx in idx % 2 == 0 ? result | (1 << idx) : result }
let odds = ~evens

func controlCharacterMask(for data: UnsafePointer<UInt8>, inQuotes: inout Bool) -> (commas: UInt64, newlines: UInt64) {
    let quotes = cmp_mask_against_input(data, 34)
    let commas = cmp_mask_against_input(data, 44)
    let newlines = cmp_mask_against_input(data, 10)

    let quoteStarts = quotes & ~(quotes << 1)
    


    let evenQuoteStarts = quoteStarts & evens
    let evenQuotesWithCarries = quotes &+ evenQuoteStarts
    let evenQuoteCarries = evenQuotesWithCarries & ~quotes
    let oddQuoteEndsWithEvenStarts = evenQuoteCarries & ~evens

    let oddQuoteStarts = quoteStarts & odds
    let (oddQuotesWithCarries, overflow) = quotes.addingReportingOverflow(oddQuoteStarts)
    let oddQuoteCarries = oddQuotesWithCarries & ~quotes
    let evenQuoteEndsWithOddStarts = oddQuoteCarries & evens

    let quoteEnds = oddQuoteEndsWithEvenStarts | evenQuoteEndsWithOddStarts

    let stringMask = carryless_multiply(quoteEnds, ~0)
    let controlMask = ~stringMask
    let finalMask = inQuotes ? ~controlMask : controlMask

    let controlCommas = commas & finalMask
    let controlNewlines = newlines & finalMask

    let endsInString = stringMask & (1 << 63) != 0
    inQuotes = endsInString != overflow
    return (controlCommas, controlNewlines)
}


public func parseCSV(data: Data) -> [[String]] {
    var commas: [Int] = []
    var newlines: [Int] = []
    var inQuotes = false
    
    data.withUnsafeBytes { buf in
        for start in stride(from: 0, to: buf.count, by: 64) {
            let end = min(buf.count, start + 64)
            let ptr = buf.baseAddress!.assumingMemoryBound(to: UInt8.self) + start
            let result: (commas: UInt64, newlines: UInt64)
            let size = end - start
            if size < 64 {
                var foo = Data(repeating: 0, count: 64)
                foo.replaceSubrange(0..<size, with: ptr, count: size)
                result = foo.withUnsafeBytes { bytes in
                    controlCharacterMask(for: bytes.baseAddress!.assumingMemoryBound(to: UInt8.self), inQuotes: &inQuotes)
                }
            } else {
                result = controlCharacterMask(for: ptr, inQuotes: &inQuotes)
            }
            result.commas.oneIndices(offset: start, appendTo: &commas)
            result.newlines.oneIndices(offset: start, appendTo: &newlines)
        }
    }
    
    var commas2 = commas[...] + [data.count]
    var result: [[String]] = []
    result.reserveCapacity(32)
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

//let csv = #"""
//"Fiel,d 1",,"Field with ""quotes""","""""qu,otes""""","kajhsdaa",
//"Another line", "with , commas, in fields", "and ""escaped quotes"""
//"""#
//let data = csv.data(using: .utf8)!
//dump(parseCSV(data: data))
let data = try! Data(contentsOf: URL(fileURLWithPath: "/Users/florian/Downloads/shapes.txt"))
measure {
    _ = parseCSV(data: data)
}
