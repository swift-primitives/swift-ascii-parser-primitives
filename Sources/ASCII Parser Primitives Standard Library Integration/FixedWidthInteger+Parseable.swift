//
//  FixedWidthInteger+Parseable.swift
//  swift-ascii-parser-primitives
//
//  ASCII.Parseable conformances for standard library integer types.
//

public import Array_Primitives
public import ASCII_Decimal_Parser_Primitives
public import Buffer_Linear_Primitive
public import Buffer_Linear_Primitives
public import Byte_Parser_Primitives
public import Parseable_ASCII_Primitives
public import Ownership_Shared_Primitive

// MARK: - Sibling-shape ASCII.Parseable conformances
//
// Per family-Codable convention [FAM-001] and the ASCII codable
// unification plan (Φ.3, option C3), stdlib integer types conform
// to `ASCII.Parseable` as a non-refining sibling — they no longer
// pin `@retroactive Parseable` (the canonical attachment), which
// would lock them into one inherent canonical codec. ASCII parsing
// is reached via the static `parser` accessor (convention, not a
// protocol requirement) or via `init(ascii:)` (provided below).

extension Int: ASCII.Parseable {
    public static var parser: ASCII.Decimal.Parser<Byte.Input, Int> { .init() }
}

extension UInt: ASCII.Parseable {
    public static var parser: ASCII.Decimal.Parser<Byte.Input, UInt> { .init() }
}

extension Int8: ASCII.Parseable {
    public static var parser: ASCII.Decimal.Parser<Byte.Input, Int8> { .init() }
}

extension Int16: ASCII.Parseable {
    public static var parser: ASCII.Decimal.Parser<Byte.Input, Int16> { .init() }
}

extension Int32: ASCII.Parseable {
    public static var parser: ASCII.Decimal.Parser<Byte.Input, Int32> { .init() }
}

extension Int64: ASCII.Parseable {
    public static var parser: ASCII.Decimal.Parser<Byte.Input, Int64> { .init() }
}

extension UInt8: ASCII.Parseable {
    public static var parser: ASCII.Decimal.Parser<Byte.Input, UInt8> { .init() }
}

extension UInt16: ASCII.Parseable {
    public static var parser: ASCII.Decimal.Parser<Byte.Input, UInt16> { .init() }
}

extension UInt32: ASCII.Parseable {
    public static var parser: ASCII.Decimal.Parser<Byte.Input, UInt32> { .init() }
}

extension UInt64: ASCII.Parseable {
    public static var parser: ASCII.Decimal.Parser<Byte.Input, UInt64> { .init() }
}

// MARK: - init(ascii:) requirement witness
//
// Witnesses the `ASCII.Parseable.init(ascii:)` requirement for every
// stdlib integer conformer above. Constrained to
// `FixedWidthInteger & ASCII.Parseable`, this single generic init satisfies
// the protocol requirement for all ten integer types (Int…UInt64) at once;
// the `Failure` associated type infers as ``ASCII/Decimal/Error``.

extension FixedWidthInteger where Self: ASCII.Parseable {
    /// Creates an integer by parsing ASCII decimal bytes.
    ///
    /// - Parameter bytes: The ASCII decimal bytes to parse.
    /// - Throws: ``ASCII/Decimal/Error`` if parsing fails (no digits, overflow).
    @inlinable
    public init<Bytes: Swift.Collection>(ascii bytes: Bytes) throws(ASCII.Decimal.Error)
    where Bytes.Element == Byte {
        var input = Byte.Input(bytes)
        let leaf = ASCII.Decimal.Parser<Byte.Input, Self>()
        self = try leaf.parse(&input)
    }
}
