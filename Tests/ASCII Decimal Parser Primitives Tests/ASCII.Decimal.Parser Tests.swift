import ASCII_Decimal_Parser_Primitives
import Parser_Primitives_Test_Support
import Testing

// MARK: - Test Suite Structure

@Suite("ASCII.Decimal.Parser")
struct ASCIIDecimalParserTests {
    @Suite struct Unit {}
    @Suite struct EdgeCase {}
}

// MARK: - Unit Tests

extension ASCIIDecimalParserTests.Unit {
    @Test
    func `parses single digit`() throws {
        let parser = ASCII.Decimal.Parser<ByteInput, Int>()
        var input: ByteInput = [0x35]  // "5"

        let result = try parser.parse(&input)

        #expect(result == 5)
        #expect(input.isEmpty)
    }

    @Test
    func `parses multi-digit number`() throws {
        let parser = ASCII.Decimal.Parser<ByteInput, Int>()
        var input: ByteInput = [0x31, 0x32, 0x33]  // "123"

        let result = try parser.parse(&input)

        #expect(result == 123)
        #expect(input.isEmpty)
    }

    @Test
    func `stops at non-digit byte`() throws {
        let parser = ASCII.Decimal.Parser<ByteInput, Int>()
        var input: ByteInput = [0x34, 0x32, 0x2E, 0x35]  // "42.5"

        let result = try parser.parse(&input)

        #expect(result == 42)
        #expect(input.first == 0x2E)
    }

    @Test
    func `parses into UInt16`() throws {
        let parser = ASCII.Decimal.Parser<ByteInput, UInt16>()
        var input: ByteInput = [0x38, 0x30, 0x38, 0x30]  // "8080"

        let result = try parser.parse(&input)

        #expect(result == 8080)
    }

    @Test
    func `parses zero`() throws {
        let parser = ASCII.Decimal.Parser<ByteInput, Int>()
        var input: ByteInput = [0x30]  // "0"

        let result = try parser.parse(&input)

        #expect(result == 0)
    }

    @Test
    func `parses leading zeros`() throws {
        let parser = ASCII.Decimal.Parser<ByteInput, Int>()
        var input: ByteInput = [0x30, 0x30, 0x35]  // "005"

        let result = try parser.parse(&input)

        #expect(result == 5)
        #expect(input.isEmpty)
    }
}

// MARK: - Edge Case Tests

extension ASCIIDecimalParserTests.EdgeCase {
    @Test
    func `fails on empty input`() {
        let parser = ASCII.Decimal.Parser<ByteInput, Int>()
        var input: ByteInput = []

        #expect(throws: ASCII.Decimal.Error.noDigits) {
            try parser.parse(&input)
        }
    }

    @Test
    func `fails on non-digit first byte`() {
        let parser = ASCII.Decimal.Parser<ByteInput, Int>()
        var input: ByteInput = [0x41]  // "A"

        #expect(throws: ASCII.Decimal.Error.noDigits) {
            try parser.parse(&input)
        }
    }

    @Test
    func `detects UInt8 overflow`() {
        let parser = ASCII.Decimal.Parser<ByteInput, UInt8>()
        var input: ByteInput = [0x32, 0x35, 0x36]  // "256"

        #expect(throws: ASCII.Decimal.Error.overflow) {
            try parser.parse(&input)
        }
    }

    @Test
    func `boundary value UInt8 max`() throws {
        let parser = ASCII.Decimal.Parser<ByteInput, UInt8>()
        var input: ByteInput = [0x32, 0x35, 0x35]  // "255"

        let result = try parser.parse(&input)

        #expect(result == 255)
    }
}
