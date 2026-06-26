//
//  Byte.Input+Bytes.swift
//  swift-ascii-parser-primitives
//
//  A variadic factory for the canonical byte-stream input `Byte.Input`
//  (`Input.Slice<Array<Column.Shared<Byte>>>`), so byte-domain parser tests can
//  write `Byte.Input.bytes(0x31, 0x32, 0x33)` instead of an annotated
//  `Byte.Input([0x31, 0x32, 0x33] as [Byte])`.
//
//  ASCII.Decimal.Parser / ASCII.Hexadecimal.Parser require `Input.Element == Byte`.
//  swift-parser-primitives' Test Support only vends a `UInt8`-backed
//  `Parser.Test.Bytes`, which cannot satisfy that requirement. The tests instead
//  reuse the already-canonical `Byte.Input` — the same input the Standard Library
//  Integration target feeds to `ASCII.Decimal.Parser<Byte.Input, …>`.
//
//  This is a plain additive member (no protocol conformance): an
//  `ExpressibleByArrayLiteral` array-literal sugar is impossible here, because
//  `Input.Slice` already carries a single `@retroactive ExpressibleByArrayLiteral`
//  conformance from `Parser.Test.Input.swift` (UInt8-backed), and Swift forbids a
//  second conformance of a type to a protocol even under different bounds.
//
//  The column's storage-conformance lattice (Shared store/buffer seam, the heap
//  buffer, the contiguous storage, and Memory.Heap: Region) must be visible to
//  name `Byte.Input`'s `Array<Column.Shared<Byte>>` base in a public signature —
//  mirrors the import set of `Byte.Input.swift` in swift-byte-parser-primitives.
//

public import Array_Primitives
public import Byte_Parser_Primitives
import Byte_Primitives
public import Column_Primitives
import Input_Primitives
public import Shared_Primitive
public import Buffer_Linear_Primitive
import Buffer_Linear_Primitives
public import Storage_Contiguous_Primitives
public import Memory_Heap_Primitives

extension Input.Slice where Base == Array_Primitives.Array<Column.Shared<Byte>> {
    /// Builds a byte-stream test input from byte values.
    ///
    /// - Parameter values: The bytes the cursor will stream over.
    /// - Returns: A `Byte.Input` positioned at the first byte.
    public static func bytes(_ values: Byte...) -> Byte.Input {
        Byte.Input(values)
    }
}
