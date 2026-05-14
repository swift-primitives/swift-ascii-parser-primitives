//
//  FixedWidthInteger+Parseable.swift
//  swift-ascii-parser-primitives
//
//  Parseable conformances for standard library integer types.
//

public import Array_Dynamic_Primitives

extension Int: @retroactive Parseable {
    public static var parser: ASCII.Decimal.Parser<Parser.Input.Bytes, Int> { .init() }
}

extension UInt: @retroactive Parseable {
    public static var parser: ASCII.Decimal.Parser<Parser.Input.Bytes, UInt> { .init() }
}

extension Int8: @retroactive Parseable {
    public static var parser: ASCII.Decimal.Parser<Parser.Input.Bytes, Int8> { .init() }
}

extension Int16: @retroactive Parseable {
    public static var parser: ASCII.Decimal.Parser<Parser.Input.Bytes, Int16> { .init() }
}

extension Int32: @retroactive Parseable {
    public static var parser: ASCII.Decimal.Parser<Parser.Input.Bytes, Int32> { .init() }
}

extension Int64: @retroactive Parseable {
    public static var parser: ASCII.Decimal.Parser<Parser.Input.Bytes, Int64> { .init() }
}

extension UInt8: @retroactive Parseable {
    public static var parser: ASCII.Decimal.Parser<Parser.Input.Bytes, UInt8> { .init() }
}

extension UInt16: @retroactive Parseable {
    public static var parser: ASCII.Decimal.Parser<Parser.Input.Bytes, UInt16> { .init() }
}

extension UInt32: @retroactive Parseable {
    public static var parser: ASCII.Decimal.Parser<Parser.Input.Bytes, UInt32> { .init() }
}

extension UInt64: @retroactive Parseable {
    public static var parser: ASCII.Decimal.Parser<Parser.Input.Bytes, UInt64> { .init() }
}
