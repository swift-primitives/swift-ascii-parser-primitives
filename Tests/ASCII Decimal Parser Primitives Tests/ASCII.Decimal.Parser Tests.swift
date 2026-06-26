import ASCII_Decimal_Parser_Primitives
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

@Suite("ASCII.Decimal.Parser")
struct ASCIIDecimalParserTests {
    @Suite struct Unit {}
    @Suite struct EdgeCase {}
    @Suite struct CountPolicy {}
    @Suite struct SignPolicy {}
}

// MARK: - Unit Tests

extension ASCIIDecimalParserTests.Unit {
    @Test
    func `parses single digit`() throws {
        let parser = ASCII.Decimal.Parser<Cursor, Int>()
        var input = Byte.Input.bytes(0x35)  // "5"

        let result = try parser.parse(&input)

        #expect(result == 5)
        #expect(input.isEmpty)
    }

    @Test
    func `parses multi-digit number`() throws {
        let parser = ASCII.Decimal.Parser<Cursor, Int>()
        var input = Byte.Input.bytes(0x31, 0x32, 0x33)  // "123"

        let result = try parser.parse(&input)

        #expect(result == 123)
        #expect(input.isEmpty)
    }

    @Test
    func `stops at non-digit byte`() throws {
        let parser = ASCII.Decimal.Parser<Cursor, Int>()
        var input = Byte.Input.bytes(0x34, 0x32, 0x2E, 0x35)  // "42.5"

        let result = try parser.parse(&input)

        #expect(result == 42)
        #expect(input.first == 0x2E)
    }

    @Test
    func `parses into UInt16`() throws {
        let parser = ASCII.Decimal.Parser<Cursor, UInt16>()
        var input = Byte.Input.bytes(0x38, 0x30, 0x38, 0x30)  // "8080"

        let result = try parser.parse(&input)

        #expect(result == 8080)
    }

    @Test
    func `parses zero`() throws {
        let parser = ASCII.Decimal.Parser<Cursor, Int>()
        var input = Byte.Input.bytes(0x30)  // "0"

        let result = try parser.parse(&input)

        #expect(result == 0)
    }

    @Test
    func `parses leading zeros`() throws {
        let parser = ASCII.Decimal.Parser<Cursor, Int>()
        var input = Byte.Input.bytes(0x30, 0x30, 0x35)  // "005"

        let result = try parser.parse(&input)

        #expect(result == 5)
        #expect(input.isEmpty)
    }
}

// MARK: - Edge Case Tests

extension ASCIIDecimalParserTests.EdgeCase {
    @Test
    func `fails on empty input`() {
        let parser = ASCII.Decimal.Parser<Cursor, Int>()
        var input = Byte.Input.bytes()

        #expect(throws: ASCII.Decimal.Error.noDigits) {
            try parser.parse(&input)
        }
    }

    @Test
    func `fails on non-digit first byte`() {
        let parser = ASCII.Decimal.Parser<Cursor, Int>()
        var input = Byte.Input.bytes(0x41)  // "A"

        #expect(throws: ASCII.Decimal.Error.noDigits) {
            try parser.parse(&input)
        }
    }

    @Test
    func `detects UInt8 overflow`() {
        let parser = ASCII.Decimal.Parser<Cursor, UInt8>()
        var input = Byte.Input.bytes(0x32, 0x35, 0x36)  // "256"

        #expect(throws: ASCII.Decimal.Error.overflow) {
            try parser.parse(&input)
        }
    }

    @Test
    func `boundary value UInt8 max`() throws {
        let parser = ASCII.Decimal.Parser<Cursor, UInt8>()
        var input = Byte.Input.bytes(0x32, 0x35, 0x35)  // "255"

        let result = try parser.parse(&input)

        #expect(result == 255)
    }
}

// MARK: - Count Policy Tests

extension ASCIIDecimalParserTests.CountPolicy {
    @Test
    func `greedy default consumes all digits`() throws {
        let parser = ASCII.Decimal.Parser<Cursor, Int>(count: .greedy)
        var input = Byte.Input.bytes(0x31, 0x32, 0x33, 0x34)  // "1234"

        let result = try parser.parse(&input)

        #expect(result == 1234)
        #expect(input.isEmpty)
    }

    @Test
    func `exactly consumes exactly n digits and stops`() throws {
        let parser = ASCII.Decimal.Parser<Cursor, Int>(count: .exactly(4))
        var input = Byte.Input.bytes(0x32, 0x30, 0x32, 0x36, 0x2D, 0x30, 0x36)  // "2026-06"

        let result = try parser.parse(&input)

        #expect(result == 2026)
        #expect(input.first == 0x2D)  // remainder begins at '-'
    }

    @Test
    func `exactly stops before a further digit`() throws {
        let parser = ASCII.Decimal.Parser<Cursor, Int>(count: .exactly(2))
        var input = Byte.Input.bytes(0x31, 0x32, 0x33, 0x34)  // "1234"

        let result = try parser.parse(&input)

        #expect(result == 12)
        #expect(input.first == 0x33)  // remainder "34"
    }

    @Test
    func `exactly shortfall throws insufficientDigits`() {
        let parser = ASCII.Decimal.Parser<Cursor, Int>(count: .exactly(4))
        var input = Byte.Input.bytes(0x31, 0x32)  // "12" — only two digits

        #expect(throws: ASCII.Decimal.Error.insufficientDigits) {
            try parser.parse(&input)
        }
    }

    @Test
    func `exactly shortfall on non-digit throws insufficientDigits`() {
        let parser = ASCII.Decimal.Parser<Cursor, Int>(count: .exactly(3))
        var input = Byte.Input.bytes(0x31, 0x32, 0x2E)  // "12." — non-digit before n

        #expect(throws: ASCII.Decimal.Error.insufficientDigits) {
            try parser.parse(&input)
        }
    }

    @Test
    func `exactly zero is degenerate and throws`() {
        let parser = ASCII.Decimal.Parser<Cursor, Int>(count: .exactly(0))
        var input = Byte.Input.bytes(0x31, 0x32)  // "12"

        #expect(throws: ASCII.Decimal.Error.insufficientDigits) {
            try parser.parse(&input)
        }
    }

    @Test
    func `exactly preserves overflow check`() {
        let parser = ASCII.Decimal.Parser<Cursor, UInt8>(count: .exactly(3))
        var input = Byte.Input.bytes(0x32, 0x35, 0x36)  // "256" > UInt8.max

        #expect(throws: ASCII.Decimal.Error.overflow) {
            try parser.parse(&input)
        }
    }

    @Test
    func `atMost caps and leaves the remainder`() throws {
        let parser = ASCII.Decimal.Parser<Cursor, Int>(count: .atMost(2))
        var input = Byte.Input.bytes(0x31, 0x32, 0x33, 0x34, 0x35)  // "12345"

        let result = try parser.parse(&input)

        #expect(result == 12)
        #expect(input.first == 0x33)  // remainder "345"
    }

    @Test
    func `atMost stops early at a non-digit`() throws {
        let parser = ASCII.Decimal.Parser<Cursor, Int>(count: .atMost(5))
        var input = Byte.Input.bytes(0x37, 0x2C)  // "7," — fewer digits than the cap

        let result = try parser.parse(&input)

        #expect(result == 7)
        #expect(input.first == 0x2C)
    }

    @Test
    func `atMost bigger than available consumes all`() throws {
        let parser = ASCII.Decimal.Parser<Cursor, Int>(count: .atMost(10))
        var input = Byte.Input.bytes(0x34, 0x32)  // "42"

        let result = try parser.parse(&input)

        #expect(result == 42)
        #expect(input.isEmpty)
    }

    @Test
    func `atMost requires at least one digit`() {
        let parser = ASCII.Decimal.Parser<Cursor, Int>(count: .atMost(3))
        var input = Byte.Input.bytes(0x41)  // "A"

        #expect(throws: ASCII.Decimal.Error.noDigits) {
            try parser.parse(&input)
        }
    }
}

// MARK: - Sign Policy Tests

extension ASCIIDecimalParserTests.SignPolicy {
    @Test
    func `none default leaves a leading plus unconsumed`() {
        let parser = ASCII.Decimal.Parser<Cursor, Int>()  // sign: .none
        var input = Byte.Input.bytes(0x2B, 0x31, 0x32, 0x33)  // "+123"

        // '+' is not a digit, so the default no-sign policy reads no digits.
        #expect(throws: ASCII.Decimal.Error.noDigits) {
            try parser.parse(&input)
        }
        #expect(input.first == 0x2B)  // input unchanged on throw
    }

    @Test
    func `none default leaves a leading minus unconsumed`() {
        let parser = ASCII.Decimal.Parser<Cursor, Int>()  // sign: .none
        var input = Byte.Input.bytes(0x2D, 0x31, 0x32, 0x33)  // "-123"

        #expect(throws: ASCII.Decimal.Error.noDigits) {
            try parser.parse(&input)
        }
        #expect(input.first == 0x2D)  // input unchanged on throw
    }

    @Test
    func `optional consumes a leading plus`() throws {
        let parser = ASCII.Decimal.Parser<Cursor, Int>(sign: .optional)
        var input = Byte.Input.bytes(0x2B, 0x31, 0x32, 0x33)  // "+123"

        let result = try parser.parse(&input)

        #expect(result == 123)
        #expect(input.isEmpty)
    }

    @Test
    func `optional consumes a leading minus`() throws {
        let parser = ASCII.Decimal.Parser<Cursor, Int>(sign: .optional)
        var input = Byte.Input.bytes(0x2D, 0x31, 0x32, 0x33)  // "-123"

        let result = try parser.parse(&input)

        #expect(result == -123)
        #expect(input.isEmpty)
    }

    @Test
    func `optional with no sign is positive`() throws {
        let parser = ASCII.Decimal.Parser<Cursor, Int>(sign: .optional)
        var input = Byte.Input.bytes(0x31, 0x32, 0x33)  // "123"

        let result = try parser.parse(&input)

        #expect(result == 123)
        #expect(input.isEmpty)
    }

    @Test
    func `Int8 minimum is reachable`() throws {
        let parser = ASCII.Decimal.Parser<Cursor, Int8>(sign: .optional)
        var input = Byte.Input.bytes(0x2D, 0x31, 0x32, 0x38)  // "-128"

        let result = try parser.parse(&input)

        #expect(result == -128)
        #expect(result == Int8.min)
    }

    @Test
    func `Int8 below minimum overflows`() {
        let parser = ASCII.Decimal.Parser<Cursor, Int8>(sign: .optional)
        var input = Byte.Input.bytes(0x2D, 0x31, 0x32, 0x39)  // "-129"

        #expect(throws: ASCII.Decimal.Error.overflow) {
            try parser.parse(&input)
        }
    }

    @Test
    func `Int8 maximum is reachable`() throws {
        let parser = ASCII.Decimal.Parser<Cursor, Int8>(sign: .optional)
        var input = Byte.Input.bytes(0x31, 0x32, 0x37)  // "127"

        let result = try parser.parse(&input)

        #expect(result == 127)
        #expect(result == Int8.max)
    }

    @Test
    func `Int8 above maximum overflows`() {
        let parser = ASCII.Decimal.Parser<Cursor, Int8>(sign: .optional)
        var input = Byte.Input.bytes(0x31, 0x32, 0x38)  // "128"

        #expect(throws: ASCII.Decimal.Error.overflow) {
            try parser.parse(&input)
        }
    }

    @Test
    func `negative into unsigned throws invalidSign`() {
        let parser = ASCII.Decimal.Parser<Cursor, UInt8>(sign: .optional)
        var input = Byte.Input.bytes(0x2D, 0x35)  // "-5"

        #expect(throws: ASCII.Decimal.Error.invalidSign) {
            try parser.parse(&input)
        }
        #expect(input.first == 0x2D)  // input unchanged on throw
    }

    @Test
    func `positive into unsigned is accepted`() throws {
        let parser = ASCII.Decimal.Parser<Cursor, UInt8>(sign: .optional)
        var input = Byte.Input.bytes(0x2B, 0x35)  // "+5"

        let result = try parser.parse(&input)

        #expect(result == 5)
        #expect(input.isEmpty)
    }

    @Test
    func `lone minus has no digits`() {
        let parser = ASCII.Decimal.Parser<Cursor, Int>(sign: .optional)
        var input = Byte.Input.bytes(0x2D)  // "-"

        #expect(throws: ASCII.Decimal.Error.noDigits) {
            try parser.parse(&input)
        }
        #expect(input.first == 0x2D)  // input unchanged on throw
    }

    @Test
    func `lone plus has no digits`() {
        let parser = ASCII.Decimal.Parser<Cursor, Int>(sign: .optional)
        var input = Byte.Input.bytes(0x2B)  // "+"

        #expect(throws: ASCII.Decimal.Error.noDigits) {
            try parser.parse(&input)
        }
        #expect(input.first == 0x2B)  // input unchanged on throw
    }

    @Test
    func `optional sign with exactly shortfall throws insufficientDigits`() {
        let parser = ASCII.Decimal.Parser<Cursor, Int>(sign: .optional, count: .exactly(3))
        var input = Byte.Input.bytes(0x2D, 0x31, 0x32)  // "-12" — two digits after sign

        #expect(throws: ASCII.Decimal.Error.insufficientDigits) {
            try parser.parse(&input)
        }
    }

    @Test
    func `optional sign with exactly exact count`() throws {
        let parser = ASCII.Decimal.Parser<Cursor, Int>(sign: .optional, count: .exactly(3))
        var input = Byte.Input.bytes(0x2D, 0x31, 0x32, 0x33)  // "-123"

        let result = try parser.parse(&input)

        #expect(result == -123)
        #expect(input.isEmpty)
    }

    @Test
    func `optional sign with exactly leaves the remainder`() throws {
        let parser = ASCII.Decimal.Parser<Cursor, Int>(sign: .optional, count: .exactly(3))
        var input = Byte.Input.bytes(0x2D, 0x31, 0x32, 0x33, 0x34)  // "-1234"

        let result = try parser.parse(&input)

        #expect(result == -123)
        #expect(input.first == 0x34)  // remainder "4"
    }
}
