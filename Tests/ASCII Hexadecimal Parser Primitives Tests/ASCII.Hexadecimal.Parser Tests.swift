import ASCII_Hexadecimal_Parser_Primitives
import Input_Primitives
import Parser_Primitives_Test_Support
import Testing

private typealias Cursor = Input_Primitives.Input.Slice<Parser.Test.Bytes>


// MARK: - Test Suite Structure

@Suite("ASCII.Hexadecimal.Parser")
struct ASCIIHexadecimalParserTests {
    @Suite struct Unit {}
    @Suite struct EdgeCase {}
}

// MARK: - Unit Tests

extension ASCIIHexadecimalParserTests.Unit {
    @Test
    func `parses lowercase hex`() throws {
        let parser = ASCII.Hexadecimal.Parser<Cursor, UInt32>()
        var input: Cursor = [0x64, 0x65, 0x61, 0x64]  // "dead"

        let result = try parser.parse(&input)

        #expect(result == 0xDEAD)
    }

    @Test
    func `parses uppercase hex`() throws {
        let parser = ASCII.Hexadecimal.Parser<Cursor, UInt32>()
        var input: Cursor = [0x44, 0x45, 0x41, 0x44]  // "DEAD"

        let result = try parser.parse(&input)

        #expect(result == 0xDEAD)
    }

    @Test
    func `parses mixed case hex`() throws {
        let parser = ASCII.Hexadecimal.Parser<Cursor, UInt32>()
        var input: Cursor = [0x44, 0x65, 0x41, 0x64]  // "DeAd"

        let result = try parser.parse(&input)

        #expect(result == 0xDEAD)
    }

    @Test
    func `parses decimal digits as hex`() throws {
        let parser = ASCII.Hexadecimal.Parser<Cursor, UInt8>()
        var input: Cursor = [0x31, 0x30]  // "10"

        let result = try parser.parse(&input)

        #expect(result == 0x10)
    }

    @Test
    func `stops at non-hex byte`() throws {
        let parser = ASCII.Hexadecimal.Parser<Cursor, UInt32>()
        var input: Cursor = [0x46, 0x46, 0x3B]  // "FF;"

        let result = try parser.parse(&input)

        #expect(result == 0xFF)
        #expect(input.first == 0x3B)
    }
}

// MARK: - Edge Case Tests

extension ASCIIHexadecimalParserTests.EdgeCase {
    @Test
    func `fails on empty input`() {
        let parser = ASCII.Hexadecimal.Parser<Cursor, Int>()
        var input: Cursor = []

        #expect(throws: ASCII.Hexadecimal.Error.noDigits) {
            try parser.parse(&input)
        }
    }

    @Test
    func `fails on non-hex first byte`() {
        let parser = ASCII.Hexadecimal.Parser<Cursor, Int>()
        var input: Cursor = [0x47]  // "G"

        #expect(throws: ASCII.Hexadecimal.Error.noDigits) {
            try parser.parse(&input)
        }
    }

    @Test
    func `detects UInt8 overflow`() {
        let parser = ASCII.Hexadecimal.Parser<Cursor, UInt8>()
        var input: Cursor = [0x31, 0x30, 0x30]  // "100" = 256

        #expect(throws: ASCII.Hexadecimal.Error.overflow) {
            try parser.parse(&input)
        }
    }

    @Test
    func `boundary value UInt8 max`() throws {
        let parser = ASCII.Hexadecimal.Parser<Cursor, UInt8>()
        var input: Cursor = [0x46, 0x46]  // "FF"

        let result = try parser.parse(&input)

        #expect(result == 255)
    }
}
