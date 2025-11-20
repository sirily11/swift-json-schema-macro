import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling. Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(SwiftJSONSchemaMacros)
    import SwiftJSONSchemaMacros

    let testMacros: [String: Macro.Type] = [
        "Schema": JSONSchemaMacro.self,
        "Property": SchemaDescriptionMacro.self,
    ]
#endif

final class SwiftJSONSchemaTests: XCTestCase {
    func testGenerateSimpleSchema() throws {
        #if canImport(SwiftJSONSchemaMacros)
            assertMacroExpansion(
                """
                @Schema
                struct Person {
                    @Property(description: "The name of the person", example: "Some name")
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
                      "description": "The name of the person",
                      "example": "Some name"]
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

    func testGenerateNestedSchema() throws {
        #if canImport(SwiftJSONSchemaMacros)
            assertMacroExpansion(
                """
                @Schema
                struct Item {
                    @Property(description: "The name of the person", example: "Some name")
                    var name: String
                }

                @Schema
                struct Person {
                    @Property(description: "The item")
                    var item: Item
                }
                """,
                expandedSource:
                """
                struct Item {
                    var name: String

                    static func jsonSchema() -> [String: Any] {
                        return [
                            "type": "object",
                            "properties": [
                                "name": [
                      "type": "string",
                      "required": true,
                      "description": "The name of the person",
                      "example": "Some name"]
                            ]
                        ]
                    }
                }
                struct Person {
                    var item: Item

                    static func jsonSchema() -> [String: Any] {
                        return [
                            "type": "object",
                            "properties": [
                                "item": [
                      "type": "object",
                                                  "properties": Item.jsonSchema() ["properties"] as! [String: Any],
                      "required": true,
                      "description": "The item"]
                            ]
                        ]
                    }
                }

                extension Item: JSONSchemaRepresentable {
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

    func testGenerateArraySchema() throws {
        #if canImport(SwiftJSONSchemaMacros)
            assertMacroExpansion(
                """
                @Schema
                struct Item {
                    @Property(description: "The name of the person", example: "Some name")
                    var name: String
                }

                @Schema
                struct Person {
                    @Property(description: "Items")
                    var item: [Item]
                }
                """,
                expandedSource:
                """
                struct Item {
                    var name: String

                    static func jsonSchema() -> [String: Any] {
                        return [
                            "type": "object",
                            "properties": [
                                "name": [
                      "type": "string",
                      "required": true,
                      "description": "The name of the person",
                      "example": "Some name"]
                            ]
                        ]
                    }
                }
                struct Person {
                    var item: [Item]

                    static func jsonSchema() -> [String: Any] {
                        return [
                            "type": "object",
                            "properties": [
                                "item": [
                      "type": "array",
                                                  "items": [
                                                     "type": "object",
                                                         "properties": Item.jsonSchema() ["properties"] as! [String: Any]

                                                      ],
                      "required": true,
                      "description": "Items"]
                            ]
                        ]
                    }
                }

                extension Item: JSONSchemaRepresentable {
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

    // MARK: - Error Cases

    func testSchemaOnClassProducesError() throws {
        #if canImport(SwiftJSONSchemaMacros)
            assertMacroExpansion(
                """
                @Schema
                class Person {
                    var name: String
                }
                """,
                expandedSource:
                """
                class Person {
                    var name: String
                }
                """,
                diagnostics: [
                    DiagnosticSpec(message: "@JSONSchema can only be applied to structs", line: 1, column: 1)
                ],
                macros: testMacros
            )
        #else
            throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testSchemaOnEnumProducesError() throws {
        #if canImport(SwiftJSONSchemaMacros)
            assertMacroExpansion(
                """
                @Schema
                enum Status {
                    case active
                    case inactive
                }
                """,
                expandedSource:
                """
                enum Status {
                    case active
                    case inactive
                }
                """,
                diagnostics: [
                    DiagnosticSpec(message: "@JSONSchema can only be applied to structs", line: 1, column: 1)
                ],
                macros: testMacros
            )
        #else
            throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    // MARK: - Optional Properties

    func testOptionalProperty() throws {
        #if canImport(SwiftJSONSchemaMacros)
            assertMacroExpansion(
                """
                @Schema
                struct Person {
                    @Property(description: "The name")
                    var name: String?
                }
                """,
                expandedSource:
                """
                struct Person {
                    var name: String?

                    static func jsonSchema() -> [String: Any] {
                        return [
                            "type": "object",
                            "properties": [
                                "name": [
                      "type": "string",
                      "required": false,
                      "description": "The name"]
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

    // MARK: - Bool Type

    func testBoolProperty() throws {
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

    // MARK: - Double Type

    func testDoubleProperty() throws {
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

    // MARK: - Default Values

    func testStringDefaultValue() throws {
        #if canImport(SwiftJSONSchemaMacros)
            assertMacroExpansion(
                """
                @Schema
                struct Person {
                    @Property(description: "The name")
                    var name: String = "John"
                }
                """,
                expandedSource:
                """
                struct Person {
                    var name: String = "John"

                    static func jsonSchema() -> [String: Any] {
                        return [
                            "type": "object",
                            "properties": [
                                "name": [
                      "type": "string",
                      "required": true,
                      "description": "The name",
                      "default": "John"]
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

    func testIntDefaultValue() throws {
        #if canImport(SwiftJSONSchemaMacros)
            assertMacroExpansion(
                """
                @Schema
                struct Person {
                    @Property(description: "The age")
                    var age: Int = 25
                }
                """,
                expandedSource:
                """
                struct Person {
                    var age: Int = 25

                    static func jsonSchema() -> [String: Any] {
                        return [
                            "type": "object",
                            "properties": [
                                "age": [
                      "type": "number",
                      "required": true,
                      "description": "The age",
                      "default": 25]
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

    func testBoolDefaultValue() throws {
        #if canImport(SwiftJSONSchemaMacros)
            assertMacroExpansion(
                """
                @Schema
                struct Settings {
                    @Property(description: "Is enabled")
                    var isEnabled: Bool = false
                }
                """,
                expandedSource:
                """
                struct Settings {
                    var isEnabled: Bool = false

                    static func jsonSchema() -> [String: Any] {
                        return [
                            "type": "object",
                            "properties": [
                                "isEnabled": [
                      "type": "boolean",
                      "required": true,
                      "description": "Is enabled",
                      "default": false]
                            ]
                        ]
                    }
                }

                extension Settings: JSONSchemaRepresentable {
                }
                """,
                macros: testMacros
            )
        #else
            throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testFloatDefaultValue() throws {
        #if canImport(SwiftJSONSchemaMacros)
            assertMacroExpansion(
                """
                @Schema
                struct Product {
                    @Property(description: "The price")
                    var price: Float = 9.99
                }
                """,
                expandedSource:
                """
                struct Product {
                    var price: Float = 9.99

                    static func jsonSchema() -> [String: Any] {
                        return [
                            "type": "object",
                            "properties": [
                                "price": [
                      "type": "number",
                      "required": true,
                      "description": "The price",
                      "default": 9.99]
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

    // MARK: - Properties Without @Property Decorator

    func testPropertyWithoutDecorator() throws {
        #if canImport(SwiftJSONSchemaMacros)
            assertMacroExpansion(
                """
                @Schema
                struct Person {
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
                      "required": true]
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

    // MARK: - Multiple Properties

    func testMultipleProperties() throws {
        #if canImport(SwiftJSONSchemaMacros)
            assertMacroExpansion(
                """
                @Schema
                struct Person {
                    @Property(description: "The name", example: "John")
                    var name: String
                    @Property(description: "The age", example: 30)
                    var age: Int
                    @Property(description: "Is active", example: true)
                    var isActive: Bool
                }
                """,
                expandedSource:
                """
                struct Person {
                    var name: String
                    var age: Int
                    var isActive: Bool

                    static func jsonSchema() -> [String: Any] {
                        return [
                            "type": "object",
                            "properties": [
                                "name": [
                      "type": "string",
                      "required": true,
                      "description": "The name",
                      "example": "John"],
                        "age": [
                      "type": "number",
                      "required": true,
                      "description": "The age",
                      "example": 30],
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

    // MARK: - Array of Primitive Types

    func testArrayOfStrings() throws {
        #if canImport(SwiftJSONSchemaMacros)
            assertMacroExpansion(
                """
                @Schema
                struct Person {
                    @Property(description: "Tags")
                    var tags: [String]
                }
                """,
                expandedSource:
                """
                struct Person {
                    var tags: [String]

                    static func jsonSchema() -> [String: Any] {
                        return [
                            "type": "object",
                            "properties": [
                                "tags": [
                      "type": "array",
                                                  "items": [
                                                     "type": "string"

                                                      ],
                      "required": true,
                      "description": "Tags"]
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

    func testArrayOfInts() throws {
        #if canImport(SwiftJSONSchemaMacros)
            assertMacroExpansion(
                """
                @Schema
                struct Data {
                    @Property(description: "Numbers")
                    var numbers: [Int]
                }
                """,
                expandedSource:
                """
                struct Data {
                    var numbers: [Int]

                    static func jsonSchema() -> [String: Any] {
                        return [
                            "type": "object",
                            "properties": [
                                "numbers": [
                      "type": "array",
                                                  "items": [
                                                     "type": "number"

                                                      ],
                      "required": true,
                      "description": "Numbers"]
                            ]
                        ]
                    }
                }

                extension Data: JSONSchemaRepresentable {
                }
                """,
                macros: testMacros
            )
        #else
            throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    // MARK: - Mixed Required and Optional

    func testMixedRequiredAndOptional() throws {
        #if canImport(SwiftJSONSchemaMacros)
            assertMacroExpansion(
                """
                @Schema
                struct Person {
                    @Property(description: "The name")
                    var name: String
                    @Property(description: "The nickname")
                    var nickname: String?
                }
                """,
                expandedSource:
                """
                struct Person {
                    var name: String
                    var nickname: String?

                    static func jsonSchema() -> [String: Any] {
                        return [
                            "type": "object",
                            "properties": [
                                "name": [
                      "type": "string",
                      "required": true,
                      "description": "The name"],
                        "nickname": [
                      "type": "string",
                      "required": false,
                      "description": "The nickname"]
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

    // MARK: - Description and Example Together

    func testDescriptionAndExampleWithDefault() throws {
        #if canImport(SwiftJSONSchemaMacros)
            assertMacroExpansion(
                """
                @Schema
                struct Person {
                    @Property(description: "The name", example: "Jane")
                    var name: String = "John"
                }
                """,
                expandedSource:
                """
                struct Person {
                    var name: String = "John"

                    static func jsonSchema() -> [String: Any] {
                        return [
                            "type": "object",
                            "properties": [
                                "name": [
                      "type": "string",
                      "required": true,
                      "description": "The name",
                      "example": "Jane",
                      "default": "John"]
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
}
