//
//  Encoder.swift
//  JSONKit
//
//  Created by Cemen Istomin on 20/10/2018.
//  Covered by MIT license.
//

import Foundation


class MiniJSONEncoder: Encoder {
    
    typealias DateEncodingStrategy = JSONEncoder.DateEncodingStrategy
    var dateEncodingStrategy: DateEncodingStrategy = .deferredToDate
    
    // didSet does not work as expected as of Swift 4.2.1 - not called on _every_ change of underlying value
    var _json: JSON
    var json: JSON {
        get { return _json }
        set {
            _json = newValue
            guard let parent = _parent, let lastKey = codingPath.last else { print("no parent"); return }
            // propagate changes upward. By default, swift only change local `json` var because of value semantic of structs
            if let index = lastKey.intValue {
                parent.json[index] = _json
            } else {
                parent.json[lastKey.stringValue] = _json
            }
        }
    }
    private var _parent: MiniJSONEncoder?
    var parent: MiniJSONEncoder { return _parent ?? self }
    
    private(set) var codingPath: [CodingKey] = []
    var userInfo: [CodingUserInfoKey : Any] = [:]
    
    init() {
        _json = JSON()
    }
    
    fileprivate init(json: JSON, key: CodingKey, parent: MiniJSONEncoder) {
        self._json = json
        _parent = parent
        codingPath = parent.codingPath
        codingPath.append(key)
    }
    
    func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key : CodingKey {
        self.json.raw = [String: Any]()
        return KeyedEncodingContainer(Keyed(encoder: self))
    }
    
    func unkeyedContainer() -> UnkeyedEncodingContainer {
        self.json.raw = [Any]()
        return Unkeyed(encoder: self)
    }
    
    func singleValueContainer() -> SingleValueEncodingContainer {
        return SingleValue(encoder: self)
    }
    
    // MARK: - Utils
    
    fileprivate func child(string key: CodingKey) -> MiniJSONEncoder {
        return MiniJSONEncoder(json: json[key.stringValue], key: key, parent: self)
    }
    
    fileprivate func child(index key: CodingKey) -> MiniJSONEncoder {
        return MiniJSONEncoder(json: json[key.intValue!], key: key, parent: self)
    }
    
    fileprivate func encode<T: Encodable>(_ value: T) throws {
        if let date = value as? Date {
            try date.encode(to: self, using: dateEncodingStrategy)
        }
        try value.encode(to: self)
    }
    
    private func convertKey(_ key: CodingKey) -> JSON.Key {
        if let index = key.intValue {
            return .index(index)
        } else {
            return .name(key.stringValue)
        }
    }
    
}


private struct Keyed<Key: CodingKey>: KeyedEncodingContainerProtocol {
    var codingPath: [CodingKey] { return encoder.codingPath }
    var allKeys: [Key] {
        guard let dictionary = encoder.json.raw as? [String: Any] else { return [] }
        return dictionary.keys.compactMap { Key(stringValue: $0) }
    }
    var encoder: MiniJSONEncoder
    
    mutating func encodeNil(forKey key: Key) throws { encoder.child(string: key).json.raw = NSNull() }
    mutating func encode(_ value: Bool,   forKey key: Key) throws { encoder.child(string: key).json.raw = value }
    mutating func encode(_ value: String, forKey key: Key) throws { encoder.child(string: key).json.string = value }
    mutating func encode(_ value: Double, forKey key: Key) throws { encoder.child(string: key).json.double = value }
    mutating func encode(_ value: Float,  forKey key: Key) throws { encoder.child(string: key).json.float = value }
    mutating func encode(_ value: Int,    forKey key: Key) throws { encoder.child(string: key).json.int = value }
    mutating func encode(_ value: Int8,   forKey key: Key) throws { encoder.child(string: key).json.int8 = value }
    mutating func encode(_ value: Int16,  forKey key: Key) throws { encoder.child(string: key).json.int16 = value }
    mutating func encode(_ value: Int32,  forKey key: Key) throws { encoder.child(string: key).json.int32 = value }
    mutating func encode(_ value: Int64,  forKey key: Key) throws { encoder.child(string: key).json.int64 = value }
    mutating func encode(_ value: UInt,   forKey key: Key) throws { encoder.child(string: key).json.uint = value }
    mutating func encode(_ value: UInt8,  forKey key: Key) throws { encoder.child(string: key).json.uint8 = value }
    mutating func encode(_ value: UInt16, forKey key: Key) throws { encoder.child(string: key).json.uint16 = value }
    mutating func encode(_ value: UInt32, forKey key: Key) throws { encoder.child(string: key).json.uint32 = value }
    mutating func encode(_ value: UInt64, forKey key: Key) throws { encoder.child(string: key).json.uint64 = value }
    
    mutating func encode<T>(_ value: T, forKey key: Key) throws where T : Encodable {
        try encoder.child(string: key).encode(value)
    }
    
    func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: Key) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
        return encoder.child(string: key).container(keyedBy: NestedKey.self)
    }
    
    func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
        return encoder.child(string: key).unkeyedContainer()
    }
    
    func superEncoder() -> Encoder {
        return encoder
    }
    
    func superEncoder(forKey key: Key) -> Encoder {
        return encoder
    }
}

private struct Unkeyed: UnkeyedEncodingContainer {
    
    var currentIndex: Int = 0
    var encoder: MiniJSONEncoder
    init(encoder: MiniJSONEncoder) {
        self.encoder = encoder
    }
    
    var codingPath: [CodingKey] { return encoder.codingPath }
    var count: Int { return (encoder.json.raw as! [Any]).count }
    
    mutating func encodeNil() throws { step().json.raw = NSNull() }
    mutating func encode(_ value: Bool)   throws { step().json.raw = value }
    mutating func encode(_ value: String) throws { step().json.string = value }
    mutating func encode(_ value: Double) throws { step().json.double = value }
    mutating func encode(_ value: Float)  throws { step().json.float = value }
    mutating func encode(_ value: Int)    throws { step().json.int = value }
    mutating func encode(_ value: Int8)   throws { step().json.int8 = value }
    mutating func encode(_ value: Int16)  throws { step().json.int16 = value }
    mutating func encode(_ value: Int32)  throws { step().json.int32 = value }
    mutating func encode(_ value: Int64)  throws { step().json.int64 = value }
    mutating func encode(_ value: UInt)   throws { step().json.uint = value }
    mutating func encode(_ value: UInt8)  throws { step().json.uint8 = value }
    mutating func encode(_ value: UInt16) throws { step().json.uint16 = value }
    mutating func encode(_ value: UInt32) throws { step().json.uint32 = value }
    mutating func encode(_ value: UInt64) throws { step().json.uint64 = value }
    
    mutating func encode<T>(_ value: T) throws where T : Encodable {
        try step().encode(value)
    }
    
    mutating private func step() -> MiniJSONEncoder {
        let index = currentIndex
        currentIndex += 1
        return encoder.child(index: JSON.Key.index(index))
    }
    
    mutating func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
        return step().container(keyedBy: NestedKey.self)
    }

    mutating func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
        return step().unkeyedContainer()
    }

    func superEncoder() -> Encoder {
        return encoder
    }
}

private struct SingleValue: SingleValueEncodingContainer {
    var encoder: MiniJSONEncoder
    var codingPath: [CodingKey] { return encoder.codingPath }
    
    mutating func encodeNil() throws { encoder.json.raw = NSNull() }
    mutating func encode(_ value: Bool)   throws { encoder.json.raw = value }
    mutating func encode(_ value: String) throws { encoder.json.string = value }
    mutating func encode(_ value: Double) throws { encoder.json.double = value }
    mutating func encode(_ value: Float)  throws { encoder.json.float = value }
    mutating func encode(_ value: Int)    throws { encoder.json.int = value }
    mutating func encode(_ value: Int8)   throws { encoder.json.int8 = value }
    mutating func encode(_ value: Int16)  throws { encoder.json.int16 = value }
    mutating func encode(_ value: Int32)  throws { encoder.json.int32 = value }
    mutating func encode(_ value: Int64)  throws { encoder.json.int64 = value }
    mutating func encode(_ value: UInt)   throws { encoder.json.uint = value }
    mutating func encode(_ value: UInt8)  throws { encoder.json.uint8 = value }
    mutating func encode(_ value: UInt16) throws { encoder.json.uint16 = value }
    mutating func encode(_ value: UInt32) throws { encoder.json.uint32 = value }
    mutating func encode(_ value: UInt64) throws { encoder.json.uint64 = value }
    
    mutating func encode<T>(_ value: T) throws where T : Encodable {
        try encoder.encode(value)
    }
    
}

// MARK: - Strategy implementations

private extension Date {
    
    func encode(to encoder: MiniJSONEncoder, using strategy: JSONEncoder.DateEncodingStrategy) throws {
        switch strategy {
        case .deferredToDate:
            try self.encode(to: encoder)
            
        case .secondsSince1970:
            try UInt64(self.timeIntervalSince1970).encode(to: encoder)
            
        case .millisecondsSince1970:
            try UInt64(self.timeIntervalSince1970 * 1000).encode(to: encoder)
            
        case .iso8601:
            try self.writeISO8601date().encode(to: encoder)
            
        case .formatted(let formatter):
            try formatter.string(from: self).encode(to: encoder)
            
        case .custom(let encode):
            try encode(self, encoder)
        }
    }
    
    private func writeISO8601date() -> String {
        if #available(iOS 10.0, macOS 10.12, *) {
            return ISO8601DateFormatter().string(from: self)
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy.MM.dd'T'HH:mm:ss"
            return formatter.string(from: self)
        }
    }
}
