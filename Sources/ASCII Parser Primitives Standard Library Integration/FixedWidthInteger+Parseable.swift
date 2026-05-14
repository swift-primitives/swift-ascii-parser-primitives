//
//  FixedWidthInteger+Parseable.swift
//  swift-ascii-parser-primitives
//
//  ASCII.Parseable conformances for standard library integer types.
//

public import Array_Dynamic_Primitives
public import ASCII_Parser_Primitives_Core

extension Int: ASCII.Parseable, @retroactive Parseable {
    public static var parser: ASCII.Decimal.Parser<Parser.Input.Bytes, Int> { .init() }
}

extension UInt: ASCII.Parseable, @retroactive Parseable {
    public static var parser: ASCII.Decimal.Parser<Parser.Input.Bytes, UInt> { .init() }
}

extension Int8: ASCII.Parseable, @retroactive Parseable {
    public static var parser: ASCII.Decimal.Parser<Parser.Input.Bytes, Int8> { .init() }
}

extension Int16: ASCII.Parseable, @retroactive Parseable {
    public static var parser: ASCII.Decimal.Parser<Parser.Input.Bytes, Int16> { .init() }
}

extension Int32: ASCII.Parseable, @retroactive Parseable {
    public static var parser: ASCII.Decimal.Parser<Parser.Input.Bytes, Int32> { .init() }
}

extension Int64: ASCII.Parseable, @retroactive Parseable {
    public static var parser: ASCII.Decimal.Parser<Parser.Input.Bytes, Int64> { .init() }
}

extension UInt8: ASCII.Parseable, @retroactive Parseable {
    public static var parser: ASCII.Decimal.Parser<Parser.Input.Bytes, UInt8> { .init() }
}

extension UInt16: ASCII.Parseable, @retroactive Parseable {
    public static var parser: ASCII.Decimal.Parser<Parser.Input.Bytes, UInt16> { .init() }
}

extension UInt32: ASCII.Parseable, @retroactive Parseable {
    public static var parser: ASCII.Decimal.Parser<Parser.Input.Bytes, UInt32> { .init() }
}

extension UInt64: ASCII.Parseable, @retroactive Parseable {
    public static var parser: ASCII.Decimal.Parser<Parser.Input.Bytes, UInt64> { .init() }
}
