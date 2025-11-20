// The Swift Programming Language
// https://docs.swift.org/swift-book

public protocol JSONSchemaRepresentable: Sendable, Codable {
    static func jsonSchema() -> [String: Any]
}

/// A macro that produces a JSON schema from the annotated type.
/// You can attache this macro to a struct and it will generate a struct that conforms to `JSONSchemaRepresentable`.
///  And then you can call `jsonSchema()` on the struct to get the JSON schema.
/// For example:
/// ```
/// @JSONSchema
/// struct Person {
///    var name: String
/// }
/// ```
/// The above code will generate a struct like this:
///
/// ```
/// struct PersonSchema: JSONSchemaRepresentable {
///    static func jsonSchema() -> [String: Any] {
///       return [
///         "type": "object",
///        "properties": [
///          "name": ["type": "string"]
///       ]
///   }
/// }
/// ```
@attached(member, names: named(jsonSchema))
@attached(extension, conformances: JSONSchemaRepresentable)
public macro Schema() = #externalMacro(module: "SwiftJSONSchemaMacros", type: "JSONSchemaMacro")

@attached(peer)
public macro Property(description: String, example: Any? = nil) =
    #externalMacro(module: "SwiftJSONSchemaMacros", type: "SchemaDescriptionMacro")
