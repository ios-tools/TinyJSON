//
//  Decoder.swift
//  JSONKit
//
//  Created by Cemen Istomin on 20/10/2018.
//  Covered by MIT license.
//

import Foundation


extension JSON {
    func decode<T: Decodable>() throws -> T {
        let decoder = MiniJSONDecoder(json: self)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        decoder.dateDecodingStrategy = .formatted(dateFormatter)
        
        return try T(from: decoder)
    }
    
    func tryDecode<T: Decodable>() -> T? {
        do {
            return try self.decode()
        } catch {
            print(error)
        }
        return nil
    }
}

class MiniJSONDecoder: Decoder {
    
    typealias DateDecodingStrategy = JSONDecoder.DateDecodingStrategy
    var dateDecodingStrategy: DateDecodingStrategy = .deferredToDate
    
    var json: JSON
    private var _parent: MiniJSONDecoder?
    var parent: MiniJSONDecoder { return _parent ?? self }
    
    private(set) var codingPath: [CodingKey] = []
    var userInfo: [CodingUserInfoKey : Any] = [:]
    
    init(json: JSON, key: CodingKey? = nil, parent: MiniJSONDecoder? = nil) {
        self.json = json
        _parent = parent
        if let parent = parent {
            codingPath = parent.codingPath
            dateDecodingStrategy = parent.dateDecodingStrategy
            if let key = key {
                codingPath.append(key)
            }
        }
    }
    
    func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key : CodingKey {
        return KeyedDecodingContainer(Keyed(decoder: self))
    }
    
    func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        return Unkeyed(decoder: self)
    }
    
    func singleValueContainer() throws -> SingleValueDecodingContainer {
        return SingleValue(decoder: self)
    }
    
    // MARK: - Utils
    
    fileprivate func child(string key: CodingKey) -> MiniJSONDecoder {
        return MiniJSONDecoder(json: json[key.stringValue], key: key, parent: self)
    }
    
    fileprivate func child(index key: CodingKey) -> MiniJSONDecoder {
        return MiniJSONDecoder(json: json[key.intValue!], key: key, parent: self)
    }
    
    fileprivate func decode<T: Decodable>(as type: T.Type) throws -> T {
        if type == Date.self {
            return try Date(from: self, using: dateDecodingStrategy) as! T
        }
        return try T(from: self)
    }
    
}


private struct Keyed<Key: CodingKey>: KeyedDecodingContainerProtocol {
    var codingPath: [CodingKey] { return decoder.codingPath }
    var allKeys: [Key] {
        guard let dictionary = decoder.json.raw as? [String: Any] else { return [] }
        return dictionary.keys.compactMap { Key(stringValue: $0) }
    }
    var decoder: MiniJSONDecoder
    
    func contains(_ key: Key) -> Bool { return decoder.json[key.stringValue].exists }
    func decodeNil(forKey key: Key) throws -> Bool { return decoder.json[key.stringValue].isNull }
    
    func decode(_ type: Bool.Type,   forKey key: Key) throws -> Bool   { return decoder.child(string: key).json.boolValue }
    func decode(_ type: String.Type, forKey key: Key) throws -> String { return decoder.child(string: key).json.stringValue }
    func decode(_ type: Double.Type, forKey key: Key) throws -> Double { return decoder.child(string: key).json.doubleValue }
    func decode(_ type: Float.Type,  forKey key: Key) throws -> Float  { return decoder.child(string: key).json.floatValue }
    func decode(_ type: Int.Type,    forKey key: Key) throws -> Int    { return decoder.child(string: key).json.intValue }
    func decode(_ type: Int8.Type,   forKey key: Key) throws -> Int8   { return decoder.child(string: key).json.int8Value }
    func decode(_ type: Int16.Type,  forKey key: Key) throws -> Int16  { return decoder.child(string: key).json.int16Value }
    func decode(_ type: Int32.Type,  forKey key: Key) throws -> Int32  { return decoder.child(string: key).json.int32Value }
    func decode(_ type: Int64.Type,  forKey key: Key) throws -> Int64  { return decoder.child(string: key).json.int64Value }
    func decode(_ type: UInt.Type,   forKey key: Key) throws -> UInt   { return decoder.child(string: key).json.uintValue }
    func decode(_ type: UInt8.Type,  forKey key: Key) throws -> UInt8  { return decoder.child(string: key).json.uint8Value }
    func decode(_ type: UInt16.Type, forKey key: Key) throws -> UInt16 { return decoder.child(string: key).json.uint16Value }
    func decode(_ type: UInt32.Type, forKey key: Key) throws -> UInt32 { return decoder.child(string: key).json.uint32Value }
    func decode(_ type: UInt64.Type, forKey key: Key) throws -> UInt64 { return decoder.child(string: key).json.uint64Value }
    func decode<T>(_ type: T.Type,   forKey key: Key) throws -> T where T : Decodable {
        return try decoder.child(string: key).decode(as: T.self)
    }
    
    func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: Key) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
        return try decoder.child(string: key).container(keyedBy: NestedKey.self)
    }
    
    func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer {
        return try decoder.child(string: key).unkeyedContainer()
    }
    
    func superDecoder() throws -> Decoder {
        return decoder.parent
    }
    
    func superDecoder(forKey key: Key) throws -> Decoder {
        return decoder.parent
    }
}

private struct Unkeyed: UnkeyedDecodingContainer {
    var currentIndex: Int = 0
    var decoder: MiniJSONDecoder
    init(decoder: MiniJSONDecoder) {
        self.decoder = decoder
    }
    
    var codingPath: [CodingKey] { return decoder.codingPath }
    var count: Int? { return (decoder.json.raw as? [Any])?.count }
    var isAtEnd: Bool {
        guard let count = count else { return true }
        return currentIndex >= count
    }
    
    mutating func decodeNil() throws -> Bool { return step().json.isNull }
    
    mutating func decode(_ type: Bool.Type   ) throws -> Bool   { return step().json.boolValue }
    mutating func decode(_ type: String.Type ) throws -> String { return step().json.stringValue }
    mutating func decode(_ type: Double.Type ) throws -> Double { return step().json.doubleValue }
    mutating func decode(_ type: Float.Type  ) throws -> Float  { return step().json.floatValue }
    mutating func decode(_ type: Int.Type    ) throws -> Int    { return step().json.intValue }
    mutating func decode(_ type: Int8.Type   ) throws -> Int8   { return step().json.int8Value }
    mutating func decode(_ type: Int16.Type  ) throws -> Int16  { return step().json.int16Value }
    mutating func decode(_ type: Int32.Type  ) throws -> Int32  { return step().json.int32Value }
    mutating func decode(_ type: Int64.Type  ) throws -> Int64  { return step().json.int64Value }
    mutating func decode(_ type: UInt.Type   ) throws -> UInt   { return step().json.uintValue }
    mutating func decode(_ type: UInt8.Type  ) throws -> UInt8  { return step().json.uint8Value }
    mutating func decode(_ type: UInt16.Type ) throws -> UInt16 { return step().json.uint16Value }
    mutating func decode(_ type: UInt32.Type ) throws -> UInt32 { return step().json.uint32Value }
    mutating func decode(_ type: UInt64.Type ) throws -> UInt64 { return step().json.uint64Value }
    mutating func decode<T>(_ type: T.Type   ) throws -> T where T : Decodable {
        return try step().decode(as: T.self)
    }
    
    mutating private func step() -> MiniJSONDecoder {
        let index = currentIndex
        currentIndex += 1
        return decoder.child(index: JSON.Key.index(index))
    }
    
    mutating func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
        return try step().container(keyedBy: NestedKey.self)
    }
    
    mutating func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer {
        return try step().unkeyedContainer()
    }
    
    func superDecoder() throws -> Decoder {
        return decoder.parent
    }
}

private struct SingleValue: SingleValueDecodingContainer {
    var decoder: MiniJSONDecoder
    var codingPath: [CodingKey] { return decoder.codingPath }
    
    func decodeNil() -> Bool { return decoder.json.isNull }
    
    func decode(_ type: Bool.Type   ) throws -> Bool   { return decoder.json.boolValue }
    func decode(_ type: String.Type ) throws -> String { return decoder.json.stringValue }
    func decode(_ type: Double.Type ) throws -> Double { return decoder.json.doubleValue }
    func decode(_ type: Float.Type  ) throws -> Float  { return decoder.json.floatValue }
    func decode(_ type: Int.Type    ) throws -> Int    { return decoder.json.intValue }
    func decode(_ type: Int8.Type   ) throws -> Int8   { return decoder.json.int8Value }
    func decode(_ type: Int16.Type  ) throws -> Int16  { return decoder.json.int16Value }
    func decode(_ type: Int32.Type  ) throws -> Int32  { return decoder.json.int32Value }
    func decode(_ type: Int64.Type  ) throws -> Int64  { return decoder.json.int64Value }
    func decode(_ type: UInt.Type   ) throws -> UInt   { return decoder.json.uintValue }
    func decode(_ type: UInt8.Type  ) throws -> UInt8  { return decoder.json.uint8Value }
    func decode(_ type: UInt16.Type ) throws -> UInt16 { return decoder.json.uint16Value }
    func decode(_ type: UInt32.Type ) throws -> UInt32 { return decoder.json.uint32Value }
    func decode(_ type: UInt64.Type ) throws -> UInt64 { return decoder.json.uint64Value }
    func decode<T>(_ type: T.Type   ) throws -> T where T : Decodable {
        return try decoder.decode(as: T.self)
    }
}

// MARK: - Strategy implementations

private extension Date {
    
    init(from decoder: MiniJSONDecoder, using strategy: JSONDecoder.DateDecodingStrategy) throws {
        switch strategy {
        case .deferredToDate:
            try self.init(from: decoder)
            
        case .secondsSince1970:
            self.init(timeIntervalSince1970: decoder.json.doubleValue)
            
        case .millisecondsSince1970:
            self.init(timeIntervalSince1970: decoder.json.doubleValue * 1000)
            
        case .iso8601:
            let strDate = decoder.json.stringValue
            if let date = Date.parseISO8601date(strDate) {
                self = date
            } else {
                throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: decoder.codingPath,
                                                                        debugDescription: "Can't read ISO8601 date: \(strDate)"))
            }
            
        case .formatted(let formatter):
            let strDate = decoder.json.stringValue
            if let date = formatter.date(from: strDate) {
                self = date
            } else {
                throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: decoder.codingPath,
                                                                        debugDescription: "Can't read custom date: \(strDate)"))
            }
            
        case .custom(let decode):
            self = try decode(decoder)
        }
    }
    
    private static func parseISO8601date(_ input: String) -> Date? {
        if #available(iOS 10.0, macOS 10.12, *) {
            return ISO8601DateFormatter().date(from: input)
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy.MM.dd'T'HH:mm:ss"
            return formatter.date(from: input)
        }
    }
}
