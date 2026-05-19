//
//  ASCII.Hexadecimal.Parser.swift
//  swift-ascii-parser-primitives
//
//  Parses a hexadecimal integer from ASCII bytes.
//

public import Byte_Primitives
public import Collection_Primitives

extension ASCII.Hexadecimal {
    /// A parser that consumes one or more ASCII hexadecimal digit bytes
    /// (0–9, A–F, a–f) and accumulates them into a `FixedWidthInteger`.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// let hex = ASCII.Hexadecimal.Parser<Input, UInt32>()
    /// let value = try hex.parse(&input) // e.g. 0xDEAD
    /// ```
    public struct Parser<Input: Collection.Slice.`Protocol`, T: FixedWidthInteger>: Sendable
    where Input: Sendable, Input.Element == Byte {
        @inlinable
        public init() {}
    }
}

extension ASCII.Hexadecimal.Parser: Parser.`Protocol` {
    public typealias Output = T
    public typealias Failure = ASCII.Hexadecimal.Error

    @inlinable
    public func parse(_ input: inout Input) throws(Failure) -> T {
        var result: T = 0
        var count = 0
        var index = input.startIndex

        while index < input.endIndex {
            let byte = input[index]
            guard let digit = Self._hexValue(byte) else { break }

            let (shifted, shiftOverflow) = result.multipliedReportingOverflow(by: 16)
            guard !shiftOverflow else { throw .overflow }
            let (sum, addOverflow) = shifted.addingReportingOverflow(digit)
            guard !addOverflow else { throw .overflow }
            result = sum
            input.formIndex(after: &index)
            count += 1
        }

        guard count > 0 else { throw .noDigits }

        input = input[index...]
        return result
    }

    @inlinable
    static func _hexValue(_ byte: Byte) -> T? {
        let raw = byte.underlying
        switch raw {
        case 0x30...0x39: return T(raw &- 0x30)
        case 0x41...0x46: return T(raw &- 0x37)
        case 0x61...0x66: return T(raw &- 0x57)
        default: return nil
        }
    }
}
