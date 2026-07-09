import ASCII_Hexadecimal_Parser_Primitives
import ASCII_Parser_Primitives_Test_Support
import Byte_Parser_Primitives
import Testing

// `Byte.Input` is the canonical byte-stream input — the same input the Standard
// Library Integration target feeds to `ASCII.Decimal.Parser<Byte.Input, …>`. It
// vends `Element == Byte`, which the parser requires. Inputs are built with the
// `Byte.Input.bytes(_:)` factory from the Test Support module (an array-literal
// conformance is impossible — see `Byte.Input+Bytes.swift`).
private typealias Cursor = Byte.Input

// MARK: - Test Suite Structure

@Suite
struct `ASCII.Hexadecimal.Parser Tests` {
    @Suite struct Unit {}
    @Suite struct `Edge Case` {}
    @Suite struct `Count Policy` {}
    @Suite struct `Sign Policy` {}
}

// MARK: - Unit Tests

extension `ASCII.Hexadecimal.Parser Tests`.Unit {
    @Test
    func `parses lowercase hex`() throws {
        let parser = ASCII.Hexadecimal.Parser<Cursor, UInt32>()
        var input = Byte.Input.bytes(0x64, 0x65, 0x61, 0x64)  // "dead"

        let result = try parser.parse(&input)

        #expect(result == 0xDEAD)
    }

    @Test
    func `parses uppercase hex`() throws {
        let parser = ASCII.Hexadecimal.Parser<Cursor, UInt32>()
        var input = Byte.Input.bytes(0x44, 0x45, 0x41, 0x44)  // "DEAD"

        let result = try parser.parse(&input)

        #expect(result == 0xDEAD)
    }

    @Test
    func `parses mixed case hex`() throws {
        let parser = ASCII.Hexadecimal.Parser<Cursor, UInt32>()
        var input = Byte.Input.bytes(0x44, 0x65, 0x41, 0x64)  // "DeAd"

        let result = try parser.parse(&input)

        #expect(result == 0xDEAD)
    }

    @Test
    func `parses decimal digits as hex`() throws {
        let parser = ASCII.Hexadecimal.Parser<Cursor, UInt8>()
        var input = Byte.Input.bytes(0x31, 0x30)  // "10"

        let result = try parser.parse(&input)

        #expect(result == 0x10)
    }

    @Test
    func `stops at non-hex byte`() throws {
        let parser = ASCII.Hexadecimal.Parser<Cursor, UInt32>()
        var input = Byte.Input.bytes(0x46, 0x46, 0x3B)  // "FF;"

        let result = try parser.parse(&input)

        #expect(result == 0xFF)
        #expect(input.first == 0x3B)
    }
}

// MARK: - Edge Case Tests

extension `ASCII.Hexadecimal.Parser Tests`.`Edge Case` {
    @Test
    func `fails on empty input`() {
        let parser = ASCII.Hexadecimal.Parser<Cursor, Int>()
        var input = Byte.Input.bytes()

        #expect(throws: ASCII.Hexadecimal.Error.noDigits) {
            try parser.parse(&input)
        }
    }

    @Test
    func `fails on non-hex first byte`() {
        let parser = ASCII.Hexadecimal.Parser<Cursor, Int>()
        var input = Byte.Input.bytes(0x47)  // "G"

        #expect(throws: ASCII.Hexadecimal.Error.noDigits) {
            try parser.parse(&input)
        }
    }

    @Test
    func `detects UInt8 overflow`() {
        let parser = ASCII.Hexadecimal.Parser<Cursor, UInt8>()
        var input = Byte.Input.bytes(0x31, 0x30, 0x30)  // "100" = 256

        #expect(throws: ASCII.Hexadecimal.Error.overflow) {
            try parser.parse(&input)
        }
    }

    @Test
    func `boundary value UInt8 max`() throws {
        let parser = ASCII.Hexadecimal.Parser<Cursor, UInt8>()
        var input = Byte.Input.bytes(0x46, 0x46)  // "FF"

        let result = try parser.parse(&input)

        #expect(result == 255)
    }
}

// MARK: - Count Policy Tests

extension `ASCII.Hexadecimal.Parser Tests`.`Count Policy` {
    @Test
    func `greedy default consumes all digits`() throws {
        let parser = ASCII.Hexadecimal.Parser<Cursor, UInt32>(count: .greedy)
        var input = Byte.Input.bytes(0x64, 0x65, 0x61, 0x64)  // "dead"

        let result = try parser.parse(&input)

        #expect(result == 0xDEAD)
        #expect(input.isEmpty)
    }

    @Test
    func `exactly consumes exactly n digits and stops`() throws {
        let parser = ASCII.Hexadecimal.Parser<Cursor, UInt8>(count: .exactly(2))
        var input = Byte.Input.bytes(0x46, 0x46, 0x30, 0x30)  // "FF00"

        let result = try parser.parse(&input)

        #expect(result == 0xFF)
        #expect(input.first == 0x30)  // remainder "00"
    }

    @Test
    func `exactly shortfall throws insufficientDigits`() {
        let parser = ASCII.Hexadecimal.Parser<Cursor, UInt16>(count: .exactly(4))
        var input = Byte.Input.bytes(0x41, 0x42)  // "AB" — only two digits

        #expect(throws: ASCII.Hexadecimal.Error.insufficientDigits) {
            try parser.parse(&input)
        }
    }

    @Test
    func `exactly shortfall on non-hex throws insufficientDigits`() {
        let parser = ASCII.Hexadecimal.Parser<Cursor, UInt16>(count: .exactly(3))
        var input = Byte.Input.bytes(0x41, 0x42, 0x47)  // "ABG" — 'G' is not hex

        #expect(throws: ASCII.Hexadecimal.Error.insufficientDigits) {
            try parser.parse(&input)
        }
    }

    @Test
    func `exactly zero is degenerate and throws`() {
        let parser = ASCII.Hexadecimal.Parser<Cursor, UInt16>(count: .exactly(0))
        var input = Byte.Input.bytes(0x41, 0x42)  // "AB"

        #expect(throws: ASCII.Hexadecimal.Error.insufficientDigits) {
            try parser.parse(&input)
        }
    }

    @Test
    func `exactly preserves overflow check`() {
        let parser = ASCII.Hexadecimal.Parser<Cursor, UInt8>(count: .exactly(3))
        var input = Byte.Input.bytes(0x31, 0x30, 0x30)  // "100" = 256 > UInt8.max

        #expect(throws: ASCII.Hexadecimal.Error.overflow) {
            try parser.parse(&input)
        }
    }

    @Test
    func `atMost caps and leaves the remainder`() throws {
        let parser = ASCII.Hexadecimal.Parser<Cursor, UInt8>(count: .atMost(2))
        var input = Byte.Input.bytes(0x41, 0x42, 0x43, 0x44)  // "ABCD"

        let result = try parser.parse(&input)

        #expect(result == 0xAB)
        #expect(input.first == 0x43)  // remainder "CD"
    }

    @Test
    func `atMost stops early at a non-hex byte`() throws {
        let parser = ASCII.Hexadecimal.Parser<Cursor, UInt32>(count: .atMost(5))
        var input = Byte.Input.bytes(0x46, 0x3B)  // "F;" — fewer digits than the cap

        let result = try parser.parse(&input)

        #expect(result == 0xF)
        #expect(input.first == 0x3B)
    }

    @Test
    func `atMost bigger than available consumes all`() throws {
        let parser = ASCII.Hexadecimal.Parser<Cursor, UInt32>(count: .atMost(10))
        var input = Byte.Input.bytes(0x44, 0x45, 0x41, 0x44)  // "DEAD"

        let result = try parser.parse(&input)

        #expect(result == 0xDEAD)
        #expect(input.isEmpty)
    }

    @Test
    func `atMost requires at least one digit`() {
        let parser = ASCII.Hexadecimal.Parser<Cursor, UInt32>(count: .atMost(3))
        var input = Byte.Input.bytes(0x47)  // "G"

        #expect(throws: ASCII.Hexadecimal.Error.noDigits) {
            try parser.parse(&input)
        }
    }
}

// MARK: - Sign Policy Tests

extension `ASCII.Hexadecimal.Parser Tests`.`Sign Policy` {
    @Test
    func `none default leaves a leading plus unconsumed`() {
        let parser = ASCII.Hexadecimal.Parser<Cursor, Int>()  // sign: .none
        var input = Byte.Input.bytes(0x2B, 0x66, 0x66)  // "+ff"

        // '+' is not a hex digit, so the default no-sign policy reads no digits.
        #expect(throws: ASCII.Hexadecimal.Error.noDigits) {
            try parser.parse(&input)
        }
        #expect(input.first == 0x2B)  // input unchanged on throw
    }

    @Test
    func `none default leaves a leading minus unconsumed`() {
        let parser = ASCII.Hexadecimal.Parser<Cursor, Int>()  // sign: .none
        var input = Byte.Input.bytes(0x2D, 0x66, 0x66)  // "-ff"

        #expect(throws: ASCII.Hexadecimal.Error.noDigits) {
            try parser.parse(&input)
        }
        #expect(input.first == 0x2D)  // input unchanged on throw
    }

    @Test
    func `optional consumes a leading plus`() throws {
        let parser = ASCII.Hexadecimal.Parser<Cursor, Int16>(sign: .optional)
        var input = Byte.Input.bytes(0x2B, 0x66, 0x66)  // "+ff"

        let result = try parser.parse(&input)

        #expect(result == 255)
        #expect(input.isEmpty)
    }

    @Test
    func `optional consumes a leading minus`() throws {
        let parser = ASCII.Hexadecimal.Parser<Cursor, Int16>(sign: .optional)
        var input = Byte.Input.bytes(0x2D, 0x66, 0x66)  // "-ff"

        let result = try parser.parse(&input)

        #expect(result == -255)
        #expect(input.isEmpty)
    }

    @Test
    func `optional with no sign is positive`() throws {
        let parser = ASCII.Hexadecimal.Parser<Cursor, Int16>(sign: .optional)
        var input = Byte.Input.bytes(0x66, 0x66)  // "ff"

        let result = try parser.parse(&input)

        #expect(result == 255)
        #expect(input.isEmpty)
    }

    @Test
    func `Int8 minimum is reachable`() throws {
        let parser = ASCII.Hexadecimal.Parser<Cursor, Int8>(sign: .optional)
        var input = Byte.Input.bytes(0x2D, 0x38, 0x30)  // "-80" = -128

        let result = try parser.parse(&input)

        #expect(result == -128)
        #expect(result == Int8.min)
    }

    @Test
    func `Int8 below minimum overflows`() {
        let parser = ASCII.Hexadecimal.Parser<Cursor, Int8>(sign: .optional)
        var input = Byte.Input.bytes(0x2D, 0x38, 0x31)  // "-81" = -129

        #expect(throws: ASCII.Hexadecimal.Error.overflow) {
            try parser.parse(&input)
        }
    }

    @Test
    func `negative into unsigned throws invalidSign`() {
        let parser = ASCII.Hexadecimal.Parser<Cursor, UInt8>(sign: .optional)
        var input = Byte.Input.bytes(0x2D, 0x35)  // "-5"

        #expect(throws: ASCII.Hexadecimal.Error.invalidSign) {
            try parser.parse(&input)
        }
        #expect(input.first == 0x2D)  // input unchanged on throw
    }

    @Test
    func `positive into unsigned is accepted`() throws {
        let parser = ASCII.Hexadecimal.Parser<Cursor, UInt8>(sign: .optional)
        var input = Byte.Input.bytes(0x2B, 0x35)  // "+5"

        let result = try parser.parse(&input)

        #expect(result == 5)
        #expect(input.isEmpty)
    }

    @Test
    func `lone minus has no digits`() {
        let parser = ASCII.Hexadecimal.Parser<Cursor, Int>(sign: .optional)
        var input = Byte.Input.bytes(0x2D)  // "-"

        #expect(throws: ASCII.Hexadecimal.Error.noDigits) {
            try parser.parse(&input)
        }
        #expect(input.first == 0x2D)  // input unchanged on throw
    }

    @Test
    func `lone plus has no digits`() {
        let parser = ASCII.Hexadecimal.Parser<Cursor, Int>(sign: .optional)
        var input = Byte.Input.bytes(0x2B)  // "+"

        #expect(throws: ASCII.Hexadecimal.Error.noDigits) {
            try parser.parse(&input)
        }
        #expect(input.first == 0x2B)  // input unchanged on throw
    }

    @Test
    func `optional sign with exactly leaves the remainder`() throws {
        let parser = ASCII.Hexadecimal.Parser<Cursor, Int16>(sign: .optional, count: .exactly(2))
        var input = Byte.Input.bytes(0x2D, 0x66, 0x66, 0x30)  // "-ff0"

        let result = try parser.parse(&input)

        #expect(result == -255)
        #expect(input.first == 0x30)  // remainder "0"
    }
}
