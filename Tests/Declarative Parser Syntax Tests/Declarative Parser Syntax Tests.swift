//
//  Declarative Parser Syntax Tests.swift
//  swift-ascii-parser-primitives
//
//  Reference test suite: canonical `var body` parser pattern.
//
//  Convention: `var body` is the default for composed parsers.
//  `func parse` is reserved for genuine leaf atoms (Body == Never).
//
//  Key syntax features demonstrated:
//  - String literal delimiters: `":"` via Parser.Literal + ExpressibleByStringLiteral
//  - Type placeholder inference: `ASCII.Decimal.Parser<_, UInt16>()`
//  - Nest.Name domain types: Network.Endpoint, Geometry.Point
//  - Void-skipping: literal outputs are automatically discarded
//  - Tuple flattening: (A, B, C) via parameter packs
//  - Output mapping: `.map { ... }` converts to domain type
//  - Error mapping: `.error.map { ... }` converts Either tree
//
//  Infrastructure requirement: Parser.Take.Builder needs a concrete
//  buildExpression for Parser.Literal to enable bare string literal syntax.
//  Without it, `":" as Parser.Literal<Input>` is needed.
//

import ASCII_Decimal_Parser_Primitives
import Parser_Primitives_Test_Support
import Testing

// MARK: - Test Suite

@Suite("Declarative Parser Syntax — var body convention")
struct DeclarativeParserSyntaxTests {
    @Suite("Network.Endpoint") struct EndpointTests {}
    @Suite("Geometry.Point") struct PointTests {}
    @Suite("Measurement.Range") struct RangeTests {}
    @Suite("Composition") struct CompositionTests {}
}

// ════════════════════════════════════════════════════════════
// Domain Types — Nest.Name pattern [API-NAME-001]
// ════════════════════════════════════════════════════════════

// MARK: - Network.Endpoint

struct Network: Sendable {
    struct Endpoint: Equatable, Sendable {
        let host: UInt16
        let port: UInt16
    }
}

extension Network.Endpoint {
    enum Error: Swift.Error, Sendable, Equatable {
        case invalidHost
        case expectedColon
        case invalidPort
    }
}

// MARK: - Geometry.Point

struct Geometry: Sendable {
    struct Point: Equatable, Sendable {
        let x: UInt16
        let y: UInt16
        let z: UInt16
    }
}

extension Geometry.Point {
    enum Error: Swift.Error, Sendable, Equatable {
        case invalidX
        case expectedComma
        case invalidY
        case invalidZ
    }
}

// MARK: - Measurement.Range

struct Measurement: Sendable {
    struct Range: Equatable, Sendable {
        let lower: UInt32
        let upper: UInt32
    }
}

extension Measurement.Range {
    enum Error: Swift.Error, Sendable, Equatable {
        case invalidLower
        case expectedDash
        case invalidUpper
    }
}

// ════════════════════════════════════════════════════════════
// Parsers — var body with string literal delimiters
// ════════════════════════════════════════════════════════════

// MARK: - Network.Endpoint.Parser
//
// Pattern: two values separated by ":"
//
//     ASCII.Decimal.Parser  →  UInt16
//     ":"                   →  Void (skipped)
//     ASCII.Decimal.Parser  →  UInt16
//
// Builder produces (UInt16, UInt16). `.map` converts to domain type.
// `.error.map` flattens the left-nested Either tree.

extension Network.Endpoint {
    struct Parser<Input: Collection.Slice.`Protocol` & Parser_Primitives.Parser.Input.Streaming>: Sendable
    where Input: Sendable, Input.Element == UInt8 {
        init() {}
    }
}

extension Network.Endpoint.Parser: Parser_Primitives.Parser.`Protocol` {
    typealias Output = Network.Endpoint
    typealias Failure = Network.Endpoint.Error

    var body: some Parser_Primitives.Parser.`Protocol`<Input, Network.Endpoint, Network.Endpoint.Error> {
        Parser_Primitives.Parser.Take.Sequence {
            ASCII.Decimal.Parser<_, UInt16>()
            ":"
            ASCII.Decimal.Parser<_, UInt16>()
        }
        .map { host, port in Network.Endpoint(host: host, port: port) }
        .error.map { (either) -> Network.Endpoint.Error in
            switch either {
            case .right: .invalidPort
            case .left(.left): .invalidHost
            case .left(.right): .expectedColon
            }
        }
    }
}

// MARK: - Geometry.Point.Parser
//
// Pattern: three values separated by ","
//
//     ASCII.Decimal.Parser  →  UInt16
//     ","                   →  Void (skipped)
//     ASCII.Decimal.Parser  →  UInt16
//     ","                   →  Void (skipped)
//     ASCII.Decimal.Parser  →  UInt16
//
// Builder flattens to (UInt16, UInt16, UInt16) via parameter packs.
// Five parsers → left-nested Either tree of depth 4.

extension Geometry.Point {
    struct Parser<Input: Collection.Slice.`Protocol` & Parser_Primitives.Parser.Input.Streaming>: Sendable
    where Input: Sendable, Input.Element == UInt8 {
        init() {}
    }
}

extension Geometry.Point.Parser: Parser_Primitives.Parser.`Protocol` {
    typealias Output = Geometry.Point
    typealias Failure = Geometry.Point.Error

    var body: some Parser_Primitives.Parser.`Protocol`<Input, Geometry.Point, Geometry.Point.Error> {
        Parser_Primitives.Parser.Take.Sequence {
            ASCII.Decimal.Parser<_, UInt16>()
            ","
            ASCII.Decimal.Parser<_, UInt16>()
            ","
            ASCII.Decimal.Parser<_, UInt16>()
        }
        .map { x, y, z in Geometry.Point(x: x, y: y, z: z) }
        .error.map { (either) -> Geometry.Point.Error in
            switch either {
            case .right:
                return .invalidZ
            case .left(.right):
                return .expectedComma
            case .left(.left(.right)):
                return .invalidY
            case .left(.left(.left(.right))):
                return .expectedComma
            case .left(.left(.left(.left))):
                return .invalidX
            }
        }
    }
}

// MARK: - Measurement.Range.Parser
//
// Pattern: two values separated by "-"
//
// Same structure as Endpoint but with different delimiter and UInt32.

extension Measurement.Range {
    struct Parser<Input: Collection.Slice.`Protocol` & Parser_Primitives.Parser.Input.Streaming>: Sendable
    where Input: Sendable, Input.Element == UInt8 {
        init() {}
    }
}

extension Measurement.Range.Parser: Parser_Primitives.Parser.`Protocol` {
    typealias Output = Measurement.Range
    typealias Failure = Measurement.Range.Error

    var body: some Parser_Primitives.Parser.`Protocol`<Input, Measurement.Range, Measurement.Range.Error> {
        Parser_Primitives.Parser.Take.Sequence {
            ASCII.Decimal.Parser<_, UInt32>()
            "-"
            ASCII.Decimal.Parser<_, UInt32>()
        }
        .map { lower, upper in Measurement.Range(lower: lower, upper: upper) }
        .error.map { (either) -> Measurement.Range.Error in
            switch either {
            case .right: .invalidUpper
            case .left(.left): .invalidLower
            case .left(.right): .expectedDash
            }
        }
    }
}

// MARK: - Nested Composition
//
// Pattern: a composed parser using another composed parser
//
//     Network.Endpoint.Parser  →  Network.Endpoint
//     "/"                      →  Void (skipped)
//     ASCII.Decimal.Parser     →  UInt16 (weight)
//
// Demonstrates that declarative parsers compose seamlessly.

struct Weighted: Sendable {
    struct Endpoint: Equatable, Sendable {
        let endpoint: Network.Endpoint
        let weight: UInt16
    }
}

extension Weighted.Endpoint {
    enum Error: Swift.Error, Sendable, Equatable {
        case invalidEndpoint
        case expectedSlash
        case invalidWeight
    }
}

extension Weighted.Endpoint {
    struct Parser<Input: Collection.Slice.`Protocol` & Parser_Primitives.Parser.Input.Streaming>: Sendable
    where Input: Sendable, Input.Element == UInt8 {
        init() {}
    }
}

extension Weighted.Endpoint.Parser: Parser_Primitives.Parser.`Protocol` {
    typealias Output = Weighted.Endpoint
    typealias Failure = Weighted.Endpoint.Error

    var body: some Parser_Primitives.Parser.`Protocol`<Input, Weighted.Endpoint, Weighted.Endpoint.Error> {
        Parser_Primitives.Parser.Take.Sequence {
            Network.Endpoint.Parser<Input>()
            "/"
            ASCII.Decimal.Parser<_, UInt16>()
        }
        .map { endpoint, weight in Weighted.Endpoint(endpoint: endpoint, weight: weight) }
        .error.map { (either) -> Weighted.Endpoint.Error in
            switch either {
            case .right: .invalidWeight
            case .left(.left): .invalidEndpoint
            case .left(.right): .expectedSlash
            }
        }
    }
}

// ════════════════════════════════════════════════════════════
// Tests
// ════════════════════════════════════════════════════════════

// MARK: - Network.Endpoint Tests

extension DeclarativeParserSyntaxTests.EndpointTests {
    @Test
    func `parses host:port`() throws {
        let parser = Network.Endpoint.Parser<ByteInput>()
        var input = ByteInput(utf8: "192:8080")

        let endpoint = try parser.parse(&input)

        #expect(endpoint == Network.Endpoint(host: 192, port: 8080))
        #expect(input.isEmpty)
    }

    @Test
    func `consumes only its portion`() throws {
        let parser = Network.Endpoint.Parser<ByteInput>()
        var input = ByteInput(utf8: "80:443/path")

        let endpoint = try parser.parse(&input)

        #expect(endpoint == Network.Endpoint(host: 80, port: 443))
        #expect(input.first == UInt8(ascii: "/"))
    }

    @Test
    func `reports invalidHost on non-digit`() {
        let parser = Network.Endpoint.Parser<ByteInput>()
        var input = ByteInput(utf8: "abc:80")

        #expect(throws: Network.Endpoint.Error.invalidHost) {
            try parser.parse(&input)
        }
    }

    @Test
    func `reports expectedColon on missing delimiter`() {
        let parser = Network.Endpoint.Parser<ByteInput>()
        var input = ByteInput(utf8: "80 443")

        #expect(throws: Network.Endpoint.Error.expectedColon) {
            try parser.parse(&input)
        }
    }

    @Test
    func `reports invalidPort after colon`() {
        let parser = Network.Endpoint.Parser<ByteInput>()
        var input = ByteInput(utf8: "80:abc")

        #expect(throws: Network.Endpoint.Error.invalidPort) {
            try parser.parse(&input)
        }
    }

    @Test
    func `reports invalidHost on empty`() {
        let parser = Network.Endpoint.Parser<ByteInput>()
        var input = ByteInput([])

        #expect(throws: Network.Endpoint.Error.invalidHost) {
            try parser.parse(&input)
        }
    }
}

// MARK: - Geometry.Point Tests

extension DeclarativeParserSyntaxTests.PointTests {
    @Test
    func `parses x,y,z`() throws {
        let parser = Geometry.Point.Parser<ByteInput>()
        var input = ByteInput(utf8: "10,20,30")

        let point = try parser.parse(&input)

        #expect(point == Geometry.Point(x: 10, y: 20, z: 30))
        #expect(input.isEmpty)
    }

    @Test
    func `parses max UInt16 values`() throws {
        let parser = Geometry.Point.Parser<ByteInput>()
        var input = ByteInput(utf8: "65535,0,65535")

        let point = try parser.parse(&input)

        #expect(point == Geometry.Point(x: 65535, y: 0, z: 65535))
    }

    @Test
    func `reports invalidX on empty`() {
        let parser = Geometry.Point.Parser<ByteInput>()
        var input = ByteInput([])

        #expect(throws: Geometry.Point.Error.invalidX) {
            try parser.parse(&input)
        }
    }

    @Test
    func `reports expectedComma after x`() {
        let parser = Geometry.Point.Parser<ByteInput>()
        var input = ByteInput(utf8: "10 20")

        #expect(throws: Geometry.Point.Error.expectedComma) {
            try parser.parse(&input)
        }
    }

    @Test
    func `reports invalidY after first comma`() {
        let parser = Geometry.Point.Parser<ByteInput>()
        var input = ByteInput(utf8: "10,abc")

        #expect(throws: Geometry.Point.Error.invalidY) {
            try parser.parse(&input)
        }
    }

    @Test
    func `reports invalidZ at end`() {
        let parser = Geometry.Point.Parser<ByteInput>()
        var input = ByteInput(utf8: "10,20,abc")

        #expect(throws: Geometry.Point.Error.invalidZ) {
            try parser.parse(&input)
        }
    }
}

// MARK: - Measurement.Range Tests

extension DeclarativeParserSyntaxTests.RangeTests {
    @Test
    func `parses lower-upper`() throws {
        let parser = Measurement.Range.Parser<ByteInput>()
        var input = ByteInput(utf8: "100:999")

        // Wrong delimiter — should fail
        #expect(throws: Measurement.Range.Error.expectedDash) {
            try parser.parse(&input)
        }
    }

    @Test
    func `parses with dash delimiter`() throws {
        let parser = Measurement.Range.Parser<ByteInput>()
        var input = ByteInput(utf8: "100-999")

        let range = try parser.parse(&input)

        #expect(range == Measurement.Range(lower: 100, upper: 999))
        #expect(input.isEmpty)
    }

    @Test
    func `parses UInt32 max`() throws {
        let parser = Measurement.Range.Parser<ByteInput>()
        var input = ByteInput(utf8: "0-4294967295")

        let range = try parser.parse(&input)

        #expect(range == Measurement.Range(lower: 0, upper: UInt32.max))
    }

    @Test
    func `reports invalidLower on non-digit`() {
        let parser = Measurement.Range.Parser<ByteInput>()
        var input = ByteInput(utf8: "abc-999")

        #expect(throws: Measurement.Range.Error.invalidLower) {
            try parser.parse(&input)
        }
    }

    @Test
    func `reports invalidUpper after dash`() {
        let parser = Measurement.Range.Parser<ByteInput>()
        var input = ByteInput(utf8: "100-abc")

        #expect(throws: Measurement.Range.Error.invalidUpper) {
            try parser.parse(&input)
        }
    }
}

// MARK: - Composition Tests

extension DeclarativeParserSyntaxTests.CompositionTests {
    @Test
    func `nested parser composes`() throws {
        let parser = Weighted.Endpoint.Parser<ByteInput>()
        var input = ByteInput(utf8: "80:443/10")

        let weighted = try parser.parse(&input)

        #expect(
            weighted
                == Weighted.Endpoint(
                    endpoint: Network.Endpoint(host: 80, port: 443),
                    weight: 10
                )
        )
        #expect(input.isEmpty)
    }

    @Test
    func `nested parser propagates inner error`() {
        let parser = Weighted.Endpoint.Parser<ByteInput>()
        var input = ByteInput(utf8: "abc:80/10")

        #expect(throws: Weighted.Endpoint.Error.invalidEndpoint) {
            try parser.parse(&input)
        }
    }

    @Test
    func `nested parser reports expectedSlash`() {
        let parser = Weighted.Endpoint.Parser<ByteInput>()
        var input = ByteInput(utf8: "80:443 10")

        #expect(throws: Weighted.Endpoint.Error.expectedSlash) {
            try parser.parse(&input)
        }
    }

    @Test
    func `nested parser reports invalidWeight`() {
        let parser = Weighted.Endpoint.Parser<ByteInput>()
        var input = ByteInput(utf8: "80:443/abc")

        #expect(throws: Weighted.Endpoint.Error.invalidWeight) {
            try parser.parse(&input)
        }
    }

    @Test
    func `body delegates to composed parser`() throws {
        let parser = Network.Endpoint.Parser<ByteInput>()
        var input1 = ByteInput(utf8: "80:443")
        var input2 = ByteInput(utf8: "80:443")

        let fromBody = try parser.body.parse(&input1)
        let fromParse = try parser.parse(&input2)

        #expect(fromBody == fromParse)
    }
}
