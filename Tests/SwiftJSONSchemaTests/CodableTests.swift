import SwiftJSONSchema
import XCTest

final class CodableTests: XCTestCase {

    // MARK: - Test Structs

    @Schema
    struct SimplePerson {
        var name: String
        var age: Int
    }

    @Schema
    struct PersonWithOptionals {
        var name: String
        var nickname: String?
        var age: Int?
    }

    @Schema
    struct Item {
        var id: Int
        var title: String
    }

    @Schema
    struct PersonWithNestedStruct {
        var name: String
        var favoriteItem: Item
    }

    @Schema
    struct PersonWithArray {
        var name: String
        var items: [Item]
    }

    @Schema
    struct AllTypesStruct {
        var stringValue: String
        var intValue: Int
        var doubleValue: Double
        var floatValue: Float
        var boolValue: Bool
    }

    // MARK: - Encode/Decode Tests

    func testEncodeDecodeSimpleStruct() throws {
        let person = SimplePerson(name: "John", age: 30)

        // Encode
        let encoder = JSONEncoder()
        let data = try encoder.encode(person)

        // Decode
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(SimplePerson.self, from: data)

        XCTAssertEqual(decoded.name, person.name)
        XCTAssertEqual(decoded.age, person.age)
    }

    func testEncodeDecodeNestedStruct() throws {
        let item = Item(id: 1, title: "Test Item")
        let person = PersonWithNestedStruct(name: "Jane", favoriteItem: item)

        // Encode
        let encoder = JSONEncoder()
        let data = try encoder.encode(person)

        // Decode
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(PersonWithNestedStruct.self, from: data)

        XCTAssertEqual(decoded.name, person.name)
        XCTAssertEqual(decoded.favoriteItem.id, person.favoriteItem.id)
        XCTAssertEqual(decoded.favoriteItem.title, person.favoriteItem.title)
    }

    func testEncodeDecodeWithArray() throws {
        let items = [
            Item(id: 1, title: "First"),
            Item(id: 2, title: "Second"),
            Item(id: 3, title: "Third"),
        ]
        let person = PersonWithArray(name: "Bob", items: items)

        // Encode
        let encoder = JSONEncoder()
        let data = try encoder.encode(person)

        // Decode
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(PersonWithArray.self, from: data)

        XCTAssertEqual(decoded.name, person.name)
        XCTAssertEqual(decoded.items.count, person.items.count)
        for (index, item) in decoded.items.enumerated() {
            XCTAssertEqual(item.id, person.items[index].id)
            XCTAssertEqual(item.title, person.items[index].title)
        }
    }

    func testEncodeDecodeWithOptionals() throws {
        // Test with all values present
        let personWithValues = PersonWithOptionals(name: "Alice", nickname: "Ali", age: 25)

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let dataWithValues = try encoder.encode(personWithValues)
        let decodedWithValues = try decoder.decode(PersonWithOptionals.self, from: dataWithValues)

        XCTAssertEqual(decodedWithValues.name, personWithValues.name)
        XCTAssertEqual(decodedWithValues.nickname, personWithValues.nickname)
        XCTAssertEqual(decodedWithValues.age, personWithValues.age)

        // Test with nil values
        let personWithNils = PersonWithOptionals(name: "Charlie", nickname: nil, age: nil)

        let dataWithNils = try encoder.encode(personWithNils)
        let decodedWithNils = try decoder.decode(PersonWithOptionals.self, from: dataWithNils)

        XCTAssertEqual(decodedWithNils.name, personWithNils.name)
        XCTAssertNil(decodedWithNils.nickname)
        XCTAssertNil(decodedWithNils.age)
    }

    func testEncodeDecodeWithAllTypes() throws {
        let allTypes = AllTypesStruct(
            stringValue: "Hello",
            intValue: 42,
            doubleValue: 3.14159,
            floatValue: 2.71828,
            boolValue: true
        )

        // Encode
        let encoder = JSONEncoder()
        let data = try encoder.encode(allTypes)

        // Decode
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(AllTypesStruct.self, from: data)

        XCTAssertEqual(decoded.stringValue, allTypes.stringValue)
        XCTAssertEqual(decoded.intValue, allTypes.intValue)
        XCTAssertEqual(decoded.doubleValue, allTypes.doubleValue, accuracy: 0.00001)
        XCTAssertEqual(decoded.floatValue, allTypes.floatValue, accuracy: 0.00001)
        XCTAssertEqual(decoded.boolValue, allTypes.boolValue)
    }

    func testEncodeDecodeEmptyArray() throws {
        let person = PersonWithArray(name: "Empty", items: [])

        // Encode
        let encoder = JSONEncoder()
        let data = try encoder.encode(person)

        // Decode
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(PersonWithArray.self, from: data)

        XCTAssertEqual(decoded.name, person.name)
        XCTAssertTrue(decoded.items.isEmpty)
    }

    func testJSONStructure() throws {
        let person = SimplePerson(name: "Test", age: 99)

        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        let data = try encoder.encode(person)

        let json = try XCTUnwrap(String(data: data, encoding: .utf8))
        XCTAssertEqual(json, "{\"age\":99,\"name\":\"Test\"}")
    }
}
