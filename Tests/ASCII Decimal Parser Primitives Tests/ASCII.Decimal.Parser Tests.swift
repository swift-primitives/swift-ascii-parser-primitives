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
