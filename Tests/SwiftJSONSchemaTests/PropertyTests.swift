import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

#if canImport(SwiftJSONSchemaMacros)
    import SwiftJSONSchemaMacros
#endif

final class PropertyTests: XCTestCase {
    func testIntExample() throws {
        #if canImport(SwiftJSONSchemaMacros)
            assertMacroExpansion(
                """
                @Schema
                struct Person {
                    @Property(description: "The name of the person", example: 1)
                    var age: Int
                }
                """,
                expandedSource:
                """
                struct Person {
                    var age: Int

                    static func jsonSchema() -> [String: Any] {
                        return [
                            "type": "object",
                            "properties": [
                                "age": [
                      "type": "number",
                      "required": true,
                      "description": "The name of the person",
                      "example": 1]
                            ]
                        ]
                    }
                }

                extension Person: JSONSchemaRepresentable {
                }
                """,
                macros: testMacros
            )
        #else
            throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testFloatExample() throws {
        #if canImport(SwiftJSONSchemaMacros)
            assertMacroExpansion(
                """
                @Schema
                struct Person {
                    @Property(description: "The name of the person", example: 1)
                    var age: Float
                }
                """,
                expandedSource:
                """
                struct Person {
                    var age: Float

                    static func jsonSchema() -> [String: Any] {
                        return [
                            "type": "object",
                            "properties": [
                                "age": [
                      "type": "number",
                      "required": true,
                      "description": "The name of the person",
                      "example": 1]
                            ]
                        ]
                    }
                }

                extension Person: JSONSchemaRepresentable {
                }
                """,
                macros: testMacros
            )
        #else
            throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    // MARK: - Bool Example

    func testBoolExample() throws {
        #if canImport(SwiftJSONSchemaMacros)
            assertMacroExpansion(
                """
                @Schema
                struct Person {
                    @Property(description: "Is active", example: true)
                    var isActive: Bool
                }
                """,
                expandedSource:
                """
                struct Person {
                    var isActive: Bool

                    static func jsonSchema() -> [String: Any] {
                        return [
                            "type": "object",
                            "properties": [
                                "isActive": [
                      "type": "boolean",
                      "required": true,
                      "description": "Is active",
                      "example": true]
                            ]
                        ]
                    }
                }

                extension Person: JSONSchemaRepresentable {
                }
                """,
                macros: testMacros
            )
        #else
            throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    // MARK: - Double Example

    func testDoubleExample() throws {
        #if canImport(SwiftJSONSchemaMacros)
            assertMacroExpansion(
                """
                @Schema
                struct Product {
                    @Property(description: "The price", example: 19.99)
                    var price: Double
                }
                """,
                expandedSource:
                """
                struct Product {
                    var price: Double

                    static func jsonSchema() -> [String: Any] {
                        return [
                            "type": "object",
                            "properties": [
                                "price": [
                      "type": "number",
                      "required": true,
                      "description": "The price",
                      "example": 19.99]
                            ]
                        ]
                    }
                }

                extension Product: JSONSchemaRepresentable {
                }
                """,
                macros: testMacros
            )
        #else
            throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    // MARK: - String Example

    func testStringExample() throws {
        #if canImport(SwiftJSONSchemaMacros)
            assertMacroExpansion(
                """
                @Schema
                struct Person {
                    @Property(description: "The name", example: "John")
                    var name: String
                }
                """,
                expandedSource:
                """
                struct Person {
                    var name: String

                    static func jsonSchema() -> [String: Any] {
                        return [
                            "type": "object",
                            "properties": [
                                "name": [
                      "type": "string",
                      "required": true,
                      "description": "The name",
                      "example": "John"]
                            ]
                        ]
                    }
                }

                extension Person: JSONSchemaRepresentable {
                }
                """,
                macros: testMacros
            )
        #else
            throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    // MARK: - Type Mismatch Errors

    func testStringTypeMismatchError() throws {
        #if canImport(SwiftJSONSchemaMacros)
            assertMacroExpansion(
                """
                @Schema
                struct Person {
                    @Property(description: "The name", example: 123)
                    var name: String
                }
                """,
                expandedSource:
                """
                struct Person {
                    var name: String

                    static func jsonSchema() -> [String: Any] {
                        return [
                            "type": "object",
                            "properties": [
                                "name": [
                      "type": "string",
                      "required": true,
                      "description": "The name",
                      "example": 123]
                            ]
                        ]
                    }
                }

                extension Person: JSONSchemaRepresentable {
                }
                """,
                diagnostics: [
                    DiagnosticSpec(message: "Example type mismatch: expected 'String' but got 'String'", line: 3, column: 49)
                ],
                macros: testMacros
            )
        #else
            throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testIntTypeMismatchError() throws {
        #if canImport(SwiftJSONSchemaMacros)
            assertMacroExpansion(
                """
                @Schema
                struct Person {
                    @Property(description: "The age", example: "twenty")
                    var age: Int
                }
                """,
                expandedSource:
                """
                struct Person {
                    var age: Int

                    static func jsonSchema() -> [String: Any] {
                        return [
                            "type": "object",
                            "properties": [
                                "age": [
                      "type": "number",
                      "required": true,
                      "description": "The age",
                      "example": "twenty"]
                            ]
                        ]
                    }
                }

                extension Person: JSONSchemaRepresentable {
                }
                """,
                diagnostics: [
                    DiagnosticSpec(message: "Example type mismatch: expected 'Int' but got 'Int'", line: 3, column: 48)
                ],
                macros: testMacros
            )
        #else
            throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testBoolTypeMismatchError() throws {
        #if canImport(SwiftJSONSchemaMacros)
            assertMacroExpansion(
                """
                @Schema
                struct Person {
                    @Property(description: "Is active", example: "yes")
                    var isActive: Bool
                }
                """,
                expandedSource:
                """
                struct Person {
                    var isActive: Bool

                    static func jsonSchema() -> [String: Any] {
                        return [
                            "type": "object",
                            "properties": [
                                "isActive": [
                      "type": "boolean",
                      "required": true,
                      "description": "Is active",
                      "example": "yes"]
                            ]
                        ]
                    }
                }

                extension Person: JSONSchemaRepresentable {
                }
                """,
                diagnostics: [
                    DiagnosticSpec(message: "Example type mismatch: expected 'Bool' but got 'Bool'", line: 3, column: 50)
                ],
                macros: testMacros
            )
        #else
            throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testDoubleTypeMismatchError() throws {
        #if canImport(SwiftJSONSchemaMacros)
            assertMacroExpansion(
                """
                @Schema
                struct Product {
                    @Property(description: "The price", example: "free")
                    var price: Double
                }
                """,
                expandedSource:
                """
                struct Product {
                    var price: Double

                    static func jsonSchema() -> [String: Any] {
                        return [
                            "type": "object",
                            "properties": [
                                "price": [
                      "type": "number",
                      "required": true,
                      "description": "The price",
                      "example": "free"]
                            ]
                        ]
                    }
                }

                extension Product: JSONSchemaRepresentable {
                }
                """,
                diagnostics: [
                    DiagnosticSpec(message: "Example type mismatch: expected 'Double or Float' but got 'Double'", line: 3, column: 50)
                ],
                macros: testMacros
            )
        #else
            throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    // MARK: - Property on Non-Variable Error

    func testPropertyOnFunctionProducesError() throws {
        #if canImport(SwiftJSONSchemaMacros)
            assertMacroExpansion(
                """
                struct Person {
                    @Property(description: "Get name")
                    func getName() -> String {
                        return "John"
                    }
                }
                """,
                expandedSource:
                """
                struct Person {
                    func getName() -> String {
                        return "John"
                    }
                }
                """,
                diagnostics: [
                    DiagnosticSpec(message: "This macro can only be applied to properties", line: 2, column: 5)
                ],
                macros: testMacros
            )
        #else
            throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    // MARK: - Int with Float Example (allowed)

    func testIntWithFloatLiteralAsExample() throws {
        #if canImport(SwiftJSONSchemaMacros)
            assertMacroExpansion(
                """
                @Schema
                struct Product {
                    @Property(description: "The count", example: 5)
                    var count: Float
                }
                """,
                expandedSource:
                """
                struct Product {
                    var count: Float

                    static func jsonSchema() -> [String: Any] {
                        return [
                            "type": "object",
                            "properties": [
                                "count": [
                      "type": "number",
                      "required": true,
                      "description": "The count",
                      "example": 5]
                            ]
                        ]
                    }
                }

                extension Product: JSONSchemaRepresentable {
                }
                """,
                macros: testMacros
            )
        #else
            throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
}
