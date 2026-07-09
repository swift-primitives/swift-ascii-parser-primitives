import ASCII_Binary_Parser_Primitives
import ASCII_Parser_Primitives_Test_Support
import Byte_Parser_Primitives
import Testing

// `Byte.Input` is the canonical byte-stream input — the same input the Standard
// Library Integration target feeds to `ASCII.Binary.Parser<Byte.Input, …>`. It
// vends `Element == Byte`, which the parser requires. Inputs are built with the
// `Byte.Input.bytes(_:)` factory from the Test Support module (an array-literal
// conformance is impossible — see `Byte.Input+Bytes.swift`).
private typealias Cursor = Byte.Input

// MARK: - Test Suite Structure

@Suite
struct `ASCII.Binary.Parser Tests` {
    @Suite struct Unit {}
    @Suite struct EdgeCase {}
    @Suite struct CountPolicy {}
    @Suite struct SignPolicy {}
}

// MARK: - Unit Tests

extension `ASCII.Binary.Parser Tests`.Unit {
    @Test
    func `parses single digit`() throws {
        let parser = ASCII.Binary.Parser<Cursor, Int>()
        var input = Byte.Input.bytes(0x31)  // "1"

        let result = try parser.parse(&input)

        #expect(result == 1)
        #expect(input.isEmpty)
    }

    @Test
    func `parses multi-digit number`() throws {
        let parser = ASCII.Binary.Parser<Cursor, Int>()
        var input = Byte.Input.bytes(0x31, 0x30, 0x31, 0x31)  // "1011" == 11

        let result = try parser.parse(&input)

        #expect(result == 11)
        #expect(input.isEmpty)
    }

    @Test
    func `stops at non-binary-digit byte`() throws {
        let parser = ASCII.Binary.Parser<Cursor, Int>()
        var input = Byte.Input.bytes(0x31, 0x30, 0x32)  // "102" — '2' is not binary

        let result = try parser.parse(&input)

        #expect(result == 2)  // "10" == 2
        #expect(input.first == 0x32)  // remainder begins at '2'
    }

    @Test
    func `parses into UInt8`() throws {
        let parser = ASCII.Binary.Parser<Cursor, UInt8>()
        var input = Byte.Input.bytes(0x31, 0x31, 0x31, 0x31, 0x31, 0x31, 0x31, 0x31)  // "11111111"

        let result = try parser.parse(&input)

        #expect(result == 255)
    }

    @Test
    func `parses zero`() throws {
        let parser = ASCII.Binary.Parser<Cursor, Int>()
        var input = Byte.Input.bytes(0x30)  // "0"

        let result = try parser.parse(&input)

        #expect(result == 0)
    }

    @Test
    func `parses leading zeros`() throws {
        let parser = ASCII.Binary.Parser<Cursor, Int>()
        var input = Byte.Input.bytes(0x30, 0x30, 0x31, 0x31)  // "0011" == 3

        let result = try parser.parse(&input)

        #expect(result == 3)
        #expect(input.isEmpty)
    }
}

// MARK: - Edge Case Tests

extension `ASCII.Binary.Parser Tests`.EdgeCase {
    @Test
    func `fails on empty input`() {
        let parser = ASCII.Binary.Parser<Cursor, Int>()
        var input = Byte.Input.bytes()

        #expect(throws: ASCII.Binary.Error.noDigits) {
            try parser.parse(&input)
        }
    }

    @Test
    func `fails on non-digit first byte`() {
        let parser = ASCII.Binary.Parser<Cursor, Int>()
        var input = Byte.Input.bytes(0x32)  // "2" — not a binary digit

        #expect(throws: ASCII.Binary.Error.noDigits) {
            try parser.parse(&input)
        }
    }

    @Test
    func `detects UInt8 overflow`() {
        let parser = ASCII.Binary.Parser<Cursor, UInt8>()
        var input = Byte.Input.bytes(0x31, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30)  // "100000000" == 256

        #expect(throws: ASCII.Binary.Error.overflow) {
            try parser.parse(&input)
        }
    }

    @Test
    func `boundary value UInt8 max`() throws {
        let parser = ASCII.Binary.Parser<Cursor, UInt8>()
        var input = Byte.Input.bytes(0x31, 0x31, 0x31, 0x31, 0x31, 0x31, 0x31, 0x31)  // "11111111" == 255

        let result = try parser.parse(&input)

        #expect(result == 255)
    }
}

// MARK: - Count Policy Tests

extension `ASCII.Binary.Parser Tests`.CountPolicy {
    @Test
    func `greedy default consumes all digits`() throws {
        let parser = ASCII.Binary.Parser<Cursor, Int>(count: .greedy)
        var input = Byte.Input.bytes(0x31, 0x30, 0x31, 0x31)  // "1011" == 11

        let result = try parser.parse(&input)

        #expect(result == 11)
        #expect(input.isEmpty)
    }

    @Test
    func `exactly consumes exactly n digits and stops`() throws {
        let parser = ASCII.Binary.Parser<Cursor, Int>(count: .exactly(4))
        var input = Byte.Input.bytes(0x31, 0x30, 0x31, 0x31, 0x30)  // "10110"

        let result = try parser.parse(&input)

        #expect(result == 11)  // "1011" == 11
        #expect(input.first == 0x30)  // remainder begins at the fifth '0'
    }

    @Test
    func `exactly stops before a further digit`() throws {
        let parser = ASCII.Binary.Parser<Cursor, Int>(count: .exactly(2))
        var input = Byte.Input.bytes(0x31, 0x30, 0x31, 0x31)  // "1011"

        let result = try parser.parse(&input)

        #expect(result == 2)  // "10" == 2
        #expect(input.first == 0x31)  // remainder "11"
    }

    @Test
    func `exactly shortfall throws insufficientDigits`() {
        let parser = ASCII.Binary.Parser<Cursor, Int>(count: .exactly(4))
        var input = Byte.Input.bytes(0x31, 0x30)  // "10" — only two digits

        #expect(throws: ASCII.Binary.Error.insufficientDigits) {
            try parser.parse(&input)
        }
    }

    @Test
    func `exactly shortfall on non-digit throws insufficientDigits`() {
        let parser = ASCII.Binary.Parser<Cursor, Int>(count: .exactly(3))
        var input = Byte.Input.bytes(0x31, 0x30, 0x32)  // "102" — '2' before n

        #expect(throws: ASCII.Binary.Error.insufficientDigits) {
            try parser.parse(&input)
        }
    }

    @Test
    func `exactly zero is degenerate and throws`() {
        let parser = ASCII.Binary.Parser<Cursor, Int>(count: .exactly(0))
        var input = Byte.Input.bytes(0x31, 0x30)  // "10"

        #expect(throws: ASCII.Binary.Error.insufficientDigits) {
            try parser.parse(&input)
        }
    }

    @Test
    func `exactly preserves overflow check`() {
        let parser = ASCII.Binary.Parser<Cursor, UInt8>(count: .exactly(9))
        var input = Byte.Input.bytes(0x31, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30)  // "100000000" == 256

        #expect(throws: ASCII.Binary.Error.overflow) {
            try parser.parse(&input)
        }
    }

    @Test
    func `atMost caps and leaves the remainder`() throws {
        let parser = ASCII.Binary.Parser<Cursor, Int>(count: .atMost(2))
        var input = Byte.Input.bytes(0x31, 0x30, 0x31, 0x31, 0x30)  // "10110"

        let result = try parser.parse(&input)

        #expect(result == 2)  // "10" == 2
        #expect(input.first == 0x31)  // remainder "110"
    }

    @Test
    func `atMost stops early at a non-digit`() throws {
        let parser = ASCII.Binary.Parser<Cursor, Int>(count: .atMost(5))
        var input = Byte.Input.bytes(0x31, 0x2C)  // "1," — fewer digits than the cap

        let result = try parser.parse(&input)

        #expect(result == 1)
        #expect(input.first == 0x2C)
    }

    @Test
    func `atMost bigger than available consumes all`() throws {
        let parser = ASCII.Binary.Parser<Cursor, Int>(count: .atMost(10))
        var input = Byte.Input.bytes(0x31, 0x30, 0x31, 0x31)  // "1011" == 11

        let result = try parser.parse(&input)

        #expect(result == 11)
        #expect(input.isEmpty)
    }

    @Test
    func `atMost requires at least one digit`() {
        let parser = ASCII.Binary.Parser<Cursor, Int>(count: .atMost(3))
        var input = Byte.Input.bytes(0x32)  // "2" — not a binary digit

        #expect(throws: ASCII.Binary.Error.noDigits) {
            try parser.parse(&input)
        }
    }
}

// MARK: - Sign Policy Tests

extension `ASCII.Binary.Parser Tests`.SignPolicy {
    @Test
    func `none default leaves a leading plus unconsumed`() {
        let parser = ASCII.Binary.Parser<Cursor, Int>()  // sign: .none
        var input = Byte.Input.bytes(0x2B, 0x31, 0x30, 0x31)  // "+101"

        #expect(throws: ASCII.Binary.Error.noDigits) {
            try parser.parse(&input)
        }
        #expect(input.first == 0x2B)  // input unchanged on throw
    }

    @Test
    func `none default leaves a leading minus unconsumed`() {
        let parser = ASCII.Binary.Parser<Cursor, Int>()  // sign: .none
        var input = Byte.Input.bytes(0x2D, 0x31, 0x30, 0x31)  // "-101"

        #expect(throws: ASCII.Binary.Error.noDigits) {
            try parser.parse(&input)
        }
        #expect(input.first == 0x2D)  // input unchanged on throw
    }

    @Test
    func `optional consumes a leading plus`() throws {
        let parser = ASCII.Binary.Parser<Cursor, Int>(sign: .optional)
        var input = Byte.Input.bytes(0x2B, 0x31, 0x30, 0x31)  // "+101" == 5

        let result = try parser.parse(&input)

        #expect(result == 5)
        #expect(input.isEmpty)
    }

    @Test
    func `optional consumes a leading minus`() throws {
        let parser = ASCII.Binary.Parser<Cursor, Int>(sign: .optional)
        var input = Byte.Input.bytes(0x2D, 0x31, 0x30, 0x31)  // "-101" == -5

        let result = try parser.parse(&input)

        #expect(result == -5)
        #expect(input.isEmpty)
    }

    @Test
    func `optional with no sign is positive`() throws {
        let parser = ASCII.Binary.Parser<Cursor, Int>(sign: .optional)
        var input = Byte.Input.bytes(0x31, 0x30, 0x31)  // "101" == 5

        let result = try parser.parse(&input)

        #expect(result == 5)
        #expect(input.isEmpty)
    }

    @Test
    func `Int8 minimum is reachable`() throws {
        let parser = ASCII.Binary.Parser<Cursor, Int8>(sign: .optional)
        var input = Byte.Input.bytes(0x2D, 0x31, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30)  // "-10000000" == -128

        let result = try parser.parse(&input)

        #expect(result == -128)
        #expect(result == Int8.min)
    }

    @Test
    func `Int8 below minimum overflows`() {
        let parser = ASCII.Binary.Parser<Cursor, Int8>(sign: .optional)
        var input = Byte.Input.bytes(0x2D, 0x31, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x31)  // "-10000001" == -129

        #expect(throws: ASCII.Binary.Error.overflow) {
            try parser.parse(&input)
        }
    }

    @Test
    func `Int8 maximum is reachable`() throws {
        let parser = ASCII.Binary.Parser<Cursor, Int8>(sign: .optional)
        var input = Byte.Input.bytes(0x31, 0x31, 0x31, 0x31, 0x31, 0x31, 0x31)  // "1111111" == 127

        let result = try parser.parse(&input)

        #expect(result == 127)
        #expect(result == Int8.max)
    }

    @Test
    func `Int8 above maximum overflows`() {
        let parser = ASCII.Binary.Parser<Cursor, Int8>(sign: .optional)
        var input = Byte.Input.bytes(0x31, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30)  // "10000000" == 128

        #expect(throws: ASCII.Binary.Error.overflow) {
            try parser.parse(&input)
        }
    }

    @Test
    func `negative into unsigned throws invalidSign`() {
        let parser = ASCII.Binary.Parser<Cursor, UInt8>(sign: .optional)
        var input = Byte.Input.bytes(0x2D, 0x31)  // "-1"

        #expect(throws: ASCII.Binary.Error.invalidSign) {
            try parser.parse(&input)
        }
        #expect(input.first == 0x2D)  // input unchanged on throw
    }

    @Test
    func `positive into unsigned is accepted`() throws {
        let parser = ASCII.Binary.Parser<Cursor, UInt8>(sign: .optional)
        var input = Byte.Input.bytes(0x2B, 0x31)  // "+1"

        let result = try parser.parse(&input)

        #expect(result == 1)
        #expect(input.isEmpty)
    }

    @Test
    func `lone minus has no digits`() {
        let parser = ASCII.Binary.Parser<Cursor, Int>(sign: .optional)
        var input = Byte.Input.bytes(0x2D)  // "-"

        #expect(throws: ASCII.Binary.Error.noDigits) {
            try parser.parse(&input)
        }
        #expect(input.first == 0x2D)  // input unchanged on throw
    }

    @Test
    func `lone plus has no digits`() {
        let parser = ASCII.Binary.Parser<Cursor, Int>(sign: .optional)
        var input = Byte.Input.bytes(0x2B)  // "+"

        #expect(throws: ASCII.Binary.Error.noDigits) {
            try parser.parse(&input)
        }
        #expect(input.first == 0x2B)  // input unchanged on throw
    }

    @Test
    func `optional sign with exactly shortfall throws insufficientDigits`() {
        let parser = ASCII.Binary.Parser<Cursor, Int>(sign: .optional, count: .exactly(3))
        var input = Byte.Input.bytes(0x2D, 0x31, 0x30)  // "-10" — two digits after sign

        #expect(throws: ASCII.Binary.Error.insufficientDigits) {
            try parser.parse(&input)
        }
    }

    @Test
    func `optional sign with exactly exact count`() throws {
        let parser = ASCII.Binary.Parser<Cursor, Int>(sign: .optional, count: .exactly(3))
        var input = Byte.Input.bytes(0x2D, 0x31, 0x30, 0x31)  // "-101" == -5

        let result = try parser.parse(&input)

        #expect(result == -5)
        #expect(input.isEmpty)
    }

    @Test
    func `optional sign with exactly leaves the remainder`() throws {
        let parser = ASCII.Binary.Parser<Cursor, Int>(sign: .optional, count: .exactly(3))
        var input = Byte.Input.bytes(0x2D, 0x31, 0x30, 0x31, 0x31)  // "-1011"

        let result = try parser.parse(&input)

        #expect(result == -5)  // "-101" == -5
        #expect(input.first == 0x31)  // remainder "1"
    }
}
