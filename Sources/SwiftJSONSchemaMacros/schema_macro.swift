import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

typealias JSONSchemaProperty = (
    name: String, type: String, isOptional: Bool, description: String?, example: String?,
    defaultValue: String?, enumCases: [String]?
)

public struct JSONSchemaMacro: MemberMacro, ExtensionMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let structDecl = declaration.as(StructDeclSyntax.self) else {
            let structError = Diagnostic(node: node, message: JSONSchemaDiagnostic.onlyStructs)
            context.diagnose(structError)
            return []
        }

        let properties = try extractProperties(from: structDecl, in: context)
        let schemaFunction = generateSchemaFunction(for: properties)

        return [schemaFunction]
    }

    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        // Only generate extension for structs
        guard declaration.is(StructDeclSyntax.self) else {
            return []
        }

        let ext: DeclSyntax = """
            extension \(type.trimmed): JSONSchemaRepresentable {}
            """

        return [ext.cast(ExtensionDeclSyntax.self)]
    }
}

// MARK: - Generate functions

extension JSONSchemaMacro {
    private static func generateTabs(depth: Int) -> String {
        return String(repeating: " ", count: depth + 2)
    }

    private static func generateNestedObjectSchema(
        for type: String,
        depth _: Int
    ) -> String {
        // Generate the nested schema reference code
        return """
            \(type).jsonSchema()["properties"] as! [String: Any]
            """
    }

    private static func handleEnumCases(_ enumCases: [String]) -> String {
        if enumCases.allSatisfy({ $0.first == "\"" || Int($0) != nil }) {
            return """
                "type": "\(enumCases.first?.first == "\"" ? "string" : "number")",
                "enum": [\(enumCases.joined(separator: ", "))]
                """
        } else {
            return """
                "oneOf": [\(enumCases.map { "{ \"const\": \($0) }" }.joined(separator: ", "))]
                """
        }
    }

    private static func generateSchemaFunction(
        for properties: [JSONSchemaProperty],
        depth: Int = 0
    ) -> DeclSyntax {
        let schemaProperties = properties.map { property in
            let baseSchema = generateTypeSchema(
                for: property.type,
                enumCases: property.enumCases
            )

            var schema = """
                "\(property.name)": [
                """

            schema += "\n\(generateTabs(depth: depth))\(baseSchema)"

            schema +=
                ",\n\(generateTabs(depth: depth))\"required\": \(property.isOptional ? "false" : "true")"

            if let description = property.description {
                schema += ",\n\(generateTabs(depth: depth))\"description\": \"\(description)\""
            }

            if let example = property.example {
                schema += ",\n\(generateTabs(depth: depth))\"example\": \(example)"
            }

            if let defaultValue = property.defaultValue {
                schema += ",\n\(generateTabs(depth: depth))\"default\": \(defaultValue)"
            }

            schema += "]"
            return schema
        }.joined(separator: ",\n    ")

        return """
            static func jsonSchema() -> [String: Any] {
                return [
                    "type": "object",
                    "properties": [
                        \(raw: schemaProperties)
                    ]
                ]
            }
            """ as DeclSyntax
    }

    private static func generateTypeSchema(
        for type: String,
        enumCases: [String]?,
        depth: Int = 0
    ) -> String {
        if let enumCases = enumCases {
            // Handle enum cases as before
            return handleEnumCases(enumCases)
        }

        // Handle arrays
        if type.hasPrefix("[") && type.hasSuffix("]") {
            let elementType = String(type.dropFirst().dropLast())
            return """
                "type": "array",
                "items": [
                \(generateTabs(depth: depth + 1))\(generateTypeSchema(for: elementType, enumCases: nil, depth: depth + 1))
                \(generateTabs(depth: depth))
                ]
                """
        }

        // Handle basic types
        switch type {
        case "String": return "\"type\": \"string\""
        case "Int", "Double", "Float": return "\"type\": \"number\""
        case "Bool": return "\"type\": \"boolean\""
        default:
            // Assume it's a nested object type
            // You'll need to recursively process the type definition
            return """
                "type": "object",\n"properties": \(generateNestedObjectSchema(for: type, depth: depth))
                """
        }
    }
}

// MARK: - Extract properties

extension JSONSchemaMacro {
    /// Extracts the example value from the @Property macro
    private static func extractExample(from attributeList: AttributeListSyntax?) -> String? {
        guard let attributes = attributeList else { return nil }
        for attribute in attributes {
            guard let attr = attribute.as(AttributeSyntax.self),
                attr.attributeName.description == "Property",
                let arguments = attr.arguments?.as(LabeledExprListSyntax.self),
                let exampleArg = arguments.first(where: { argument in
                    argument.label?.text == "example"
                })?.expression
            else {
                continue
            }
            if let stringLiteral = exampleArg.as(StringLiteralExprSyntax.self) {
                return "\"\(stringLiteral.segments.description)\""
            } else if let integerLiteral = exampleArg.as(IntegerLiteralExprSyntax.self) {
                return integerLiteral.literal.text
            } else if let floatLiteral = exampleArg.as(FloatLiteralExprSyntax.self) {
                return floatLiteral.literal.text
            } else if let booleanLiteral = exampleArg.as(BooleanLiteralExprSyntax.self) {
                return booleanLiteral.literal.text
            }
        }
        return nil
    }

    private static func extractDescription(from attributeList: AttributeListSyntax?) -> String? {
        guard let attributes = attributeList else { return nil }

        for attribute in attributes {
            guard let attr = attribute.as(AttributeSyntax.self),
                attr.attributeName.description == "Property",
                let arguments = attr.arguments?.as(LabeledExprListSyntax.self),
                let firstArg = arguments.first?.expression.as(StringLiteralExprSyntax.self)
            else {
                continue
            }

            return firstArg.segments.description.trimmingCharacters(in: .whitespaces)
        }

        return nil
    }

    private static func extractProperties(
        from structDecl: StructDeclSyntax,
        in context: some MacroExpansionContext
    ) throws -> [JSONSchemaProperty] {
        var properties: [JSONSchemaProperty] = []

        for member in structDecl.memberBlock.members {
            guard let varDecl = member.decl.as(VariableDeclSyntax.self) else { continue }

            for binding in varDecl.bindings {
                guard let pat = binding.pattern.as(IdentifierPatternSyntax.self),
                    let type = binding.typeAnnotation?.type
                else { continue }

                let propertyName = pat.identifier.text
                let typeText = type.description.trimmingCharacters(in: .whitespaces)
                let isOptional = typeText.hasSuffix("?")
                let baseType = isOptional ? String(typeText.dropLast()) : typeText

                let description = extractDescription(from: varDecl.attributes)
                let example = extractExample(from: varDecl.attributes)
                let defaultValue = extractDefaultValue(from: binding.initializer)
                let enumCases = try extractEnumCases(from: baseType, in: context)

                properties.append(
                    (
                        propertyName, baseType, isOptional, description, example, defaultValue,
                        enumCases
                    ))
            }
        }

        return properties
    }

    private static func extractDefaultValue(from initializer: InitializerClauseSyntax?) -> String? {
        guard let initializer = initializer else { return nil }

        // Handle different literal types
        if let stringLiteral = initializer.value.as(StringLiteralExprSyntax.self) {
            return "\"\(stringLiteral.segments.description)\""
        } else if let integerLiteral = initializer.value.as(IntegerLiteralExprSyntax.self) {
            return integerLiteral.literal.text
        } else if let floatLiteral = initializer.value.as(FloatLiteralExprSyntax.self) {
            return floatLiteral.literal.text
        } else if let booleanLiteral = initializer.value.as(BooleanLiteralExprSyntax.self) {
            return booleanLiteral.literal.text
        }

        return nil
    }

    private static func extractEnumCases(
        from _: String,
        in _: some MacroExpansionContext
    ) throws -> [String]? {
        // This is a simplified example. In a real implementation,
        // you would need to use the context to look up the actual enum declaration
        // and analyze its cases.
        // For now, we'll return nil to indicate it's not an enum
        return nil
    }
}
