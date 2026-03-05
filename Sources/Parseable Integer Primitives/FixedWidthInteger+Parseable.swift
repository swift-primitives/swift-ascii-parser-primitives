//
//  FixedWidthInteger+Parseable.swift
//  swift-ascii-parser-primitives
//
//  Parseable conformances for standard library integer types.
//

extension Int: @retroactive Parseable {
    public static var parser: ASCII.Decimal.Parser<Parser.ByteInput, Int> { .init() }
}

extension UInt: @retroactive Parseable {
    public static var parser: ASCII.Decimal.Parser<Parser.ByteInput, UInt> { .init() }
}

extension Int8: @retroactive Parseable {
    public static var parser: ASCII.Decimal.Parser<Parser.ByteInput, Int8> { .init() }
}

extension Int16: @retroactive Parseable {
    public static var parser: ASCII.Decimal.Parser<Parser.ByteInput, Int16> { .init() }
}

extension Int32: @retroactive Parseable {
    public static var parser: ASCII.Decimal.Parser<Parser.ByteInput, Int32> { .init() }
}

extension Int64: @retroactive Parseable {
    public static var parser: ASCII.Decimal.Parser<Parser.ByteInput, Int64> { .init() }
}

extension UInt8: @retroactive Parseable {
    public static var parser: ASCII.Decimal.Parser<Parser.ByteInput, UInt8> { .init() }
}

extension UInt16: @retroactive Parseable {
    public static var parser: ASCII.Decimal.Parser<Parser.ByteInput, UInt16> { .init() }
}

extension UInt32: @retroactive Parseable {
    public static var parser: ASCII.Decimal.Parser<Parser.ByteInput, UInt32> { .init() }
}

extension UInt64: @retroactive Parseable {
    public static var parser: ASCII.Decimal.Parser<Parser.ByteInput, UInt64> { .init() }
}
