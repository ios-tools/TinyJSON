//
//  Decoder.swift
//  TinyJSON
//
//  Created by Cemen Istomin on 20/10/2018.
//  Covered by MIT license.
//

import Foundation


public class TinyJSONDecoder: Decoder {
    
    public typealias DateDecodingStrategy = JSONDecoder.DateDecodingStrategy
    public var dateDecodingStrategy: DateDecodingStrategy = .deferredToDate
    
    // what to do field
    public struct WrongStructureStrategy {
        public enum Strategy {
            case `throw`, useDefault
            case report((TinyJSONDecoder, DecodingError) -> Void)
//            case custom((TinyJSONDecoder) -> String)
        }
        
        public var keyNotFound: Strategy
        public var valueNotFound: Strategy
        public var typeMismatch: Strategy
        
        public static let `throw` = WrongStructureStrategy(keyNotFound: .throw, valueNotFound: .throw, typeMismatch: .throw)
        public static let useDefault = WrongStructureStrategy(keyNotFound: .useDefault, valueNotFound: .useDefault, typeMismatch: .useDefault)
        public static func report(_ closure: @escaping (TinyJSONDecoder, DecodingError) -> Void) -> WrongStructureStrategy {
            return WrongStructureStrategy(keyNotFound: .report(closure), valueNotFound: .report(closure), typeMismatch: .report(closure))
        }
    }
    public var wrongStructureStrategy: WrongStructureStrategy = .throw
    
    public internal(set) var json: JSON
    private var _parent: TinyJSONDecoder?
    var parent: TinyJSONDecoder { return _parent ?? self }
    
    public private(set) var codingPath: [CodingKey] = []
    public var userInfo: [CodingUserInfoKey : Any] = [:]
    
    public init(json: JSON, key: CodingKey? = nil, parent: TinyJSONDecoder? = nil) {
        self.json = json
        _parent = parent
        if let parent = parent {
            codingPath = parent.codingPath
            dateDecodingStrategy = parent.dateDecodingStrategy
            wrongStructureStrategy = parent.wrongStructureStrategy
            if let key = key {
                codingPath.append(key)
            }
        }
    }
    
    public func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key : CodingKey {
        return KeyedDecodingContainer(Keyed(decoder: self))
    }
    
    public func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        return Unkeyed(decoder: self)
    }
    
    public func singleValueContainer() throws -> SingleValueDecodingContainer {
        return SingleValue(decoder: self)
    }
    
    // MARK: - Utils
    
    fileprivate func child(string key: CodingKey) -> TinyJSONDecoder {
        return TinyJSONDecoder(json: json[key.stringValue], key: key, parent: self)
    }
    
    fileprivate func child(index key: CodingKey) -> TinyJSONDecoder {
        return TinyJSONDecoder(json: json[key.intValue!], key: key, parent: self)
    }
    
    fileprivate func decode<T: Decodable>(as type: T.Type) throws -> T {
        if type == Date.self {
            return try Date(from: self, using: dateDecodingStrategy) as! T
        }
        return try T(from: self)
    }
    
    fileprivate func value<T: LosslessStringConvertible & TypeWithDefaultValue>() throws -> T {
        func context(_ desc: String) -> DecodingError.Context {
            return DecodingError.Context(codingPath: codingPath, debugDescription: desc)
        }
        
        func fix(_ strategy: WrongStructureStrategy.Strategy, error: @autoclosure () -> DecodingError) throws -> T {
            switch strategy {
            case .throw: throw error()
            case .useDefault: return T()
            case .report(let closure):
                closure(self, error())
                return T()
            }
        }
        
        guard self.json.exists  else {
            return try fix(wrongStructureStrategy.keyNotFound,
                           error: .keyNotFound(codingPath.last ?? JSON.Key.name("-"), context("key not found in json")))
        }
        guard !self.json.isNull else {
            return try fix(wrongStructureStrategy.valueNotFound,
                           error: .valueNotFound(T.self, context("expected value, got null")))
        }
        guard let result: T = self.json.stringConvertible() else {
            return try fix(wrongStructureStrategy.typeMismatch,
                           error: .typeMismatch(T.self, context("expected \(T.self), got \(type(of: json.raw))")))
        }
        return result
    }
}


private struct Keyed<Key: CodingKey>: KeyedDecodingContainerProtocol {
    var codingPath: [CodingKey] { return decoder.codingPath }
    var allKeys: [Key] {
        guard let dictionary = decoder.json.raw as? [String: Any] else { return [] }
        return dictionary.keys.compactMap { Key(stringValue: $0) }
    }
    var decoder: TinyJSONDecoder
    
    func contains(_ key: Key) -> Bool { return decoder.json[key.stringValue].exists }
    func decodeNil(forKey key: Key) throws -> Bool { return decoder.json[key.stringValue].isNull }
    
    func decode(_ type: Bool.Type,   forKey key: Key) throws -> Bool   { return try decoder.child(string: key).value() }
    func decode(_ type: String.Type, forKey key: Key) throws -> String { return try decoder.child(string: key).value() }
    func decode(_ type: Double.Type, forKey key: Key) throws -> Double { return try decoder.child(string: key).value() }
    func decode(_ type: Float.Type,  forKey key: Key) throws -> Float  { return try decoder.child(string: key).value() }
    func decode(_ type: Int.Type,    forKey key: Key) throws -> Int    { return try decoder.child(string: key).value() }
    func decode(_ type: Int8.Type,   forKey key: Key) throws -> Int8   { return try decoder.child(string: key).value() }
    func decode(_ type: Int16.Type,  forKey key: Key) throws -> Int16  { return try decoder.child(string: key).value() }
    func decode(_ type: Int32.Type,  forKey key: Key) throws -> Int32  { return try decoder.child(string: key).value() }
    func decode(_ type: Int64.Type,  forKey key: Key) throws -> Int64  { return try decoder.child(string: key).value() }
    func decode(_ type: UInt.Type,   forKey key: Key) throws -> UInt   { return try decoder.child(string: key).value() }
    func decode(_ type: UInt8.Type,  forKey key: Key) throws -> UInt8  { return try decoder.child(string: key).value() }
    func decode(_ type: UInt16.Type, forKey key: Key) throws -> UInt16 { return try decoder.child(string: key).value() }
    func decode(_ type: UInt32.Type, forKey key: Key) throws -> UInt32 { return try decoder.child(string: key).value() }
    func decode(_ type: UInt64.Type, forKey key: Key) throws -> UInt64 { return try decoder.child(string: key).value() }
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
    var decoder: TinyJSONDecoder
    init(decoder: TinyJSONDecoder) {
        self.decoder = decoder
    }
    
    var codingPath: [CodingKey] { return decoder.codingPath }
    var count: Int? { return (decoder.json.raw as? [Any])?.count }
    var isAtEnd: Bool {
        guard let count = count else { return true }
        return currentIndex >= count
    }
    
    mutating func decodeNil() throws -> Bool { return step().json.isNull }
    
    mutating func decode(_ type: Bool.Type   ) throws -> Bool   { return try step().value() }
    mutating func decode(_ type: String.Type ) throws -> String { return try step().value() }
    mutating func decode(_ type: Double.Type ) throws -> Double { return try step().value() }
    mutating func decode(_ type: Float.Type  ) throws -> Float  { return try step().value() }
    mutating func decode(_ type: Int.Type    ) throws -> Int    { return try step().value() }
    mutating func decode(_ type: Int8.Type   ) throws -> Int8   { return try step().value() }
    mutating func decode(_ type: Int16.Type  ) throws -> Int16  { return try step().value() }
    mutating func decode(_ type: Int32.Type  ) throws -> Int32  { return try step().value() }
    mutating func decode(_ type: Int64.Type  ) throws -> Int64  { return try step().value() }
    mutating func decode(_ type: UInt.Type   ) throws -> UInt   { return try step().value() }
    mutating func decode(_ type: UInt8.Type  ) throws -> UInt8  { return try step().value() }
    mutating func decode(_ type: UInt16.Type ) throws -> UInt16 { return try step().value() }
    mutating func decode(_ type: UInt32.Type ) throws -> UInt32 { return try step().value() }
    mutating func decode(_ type: UInt64.Type ) throws -> UInt64 { return try step().value() }
    mutating func decode<T>(_ type: T.Type   ) throws -> T where T : Decodable {
        return try step().decode(as: T.self)
    }
    
    mutating private func step() -> TinyJSONDecoder {
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
    var decoder: TinyJSONDecoder
    var codingPath: [CodingKey] { return decoder.codingPath }
    
    func decodeNil() -> Bool { return decoder.json.isNull }
    
    func decode(_ type: Bool.Type   ) throws -> Bool   { return try decoder.value() }
    func decode(_ type: String.Type ) throws -> String { return try decoder.value() }
    func decode(_ type: Double.Type ) throws -> Double { return try decoder.value() }
    func decode(_ type: Float.Type  ) throws -> Float  { return try decoder.value() }
    func decode(_ type: Int.Type    ) throws -> Int    { return try decoder.value() }
    func decode(_ type: Int8.Type   ) throws -> Int8   { return try decoder.value() }
    func decode(_ type: Int16.Type  ) throws -> Int16  { return try decoder.value() }
    func decode(_ type: Int32.Type  ) throws -> Int32  { return try decoder.value() }
    func decode(_ type: Int64.Type  ) throws -> Int64  { return try decoder.value() }
    func decode(_ type: UInt.Type   ) throws -> UInt   { return try decoder.value() }
    func decode(_ type: UInt8.Type  ) throws -> UInt8  { return try decoder.value() }
    func decode(_ type: UInt16.Type ) throws -> UInt16 { return try decoder.value() }
    func decode(_ type: UInt32.Type ) throws -> UInt32 { return try decoder.value() }
    func decode(_ type: UInt64.Type ) throws -> UInt64 { return try decoder.value() }
    func decode<T>(_ type: T.Type   ) throws -> T where T : Decodable {
        return try decoder.decode(as: T.self)
    }
}

// MARK: - Strategy implementations

private extension Date {
    
    init(from decoder: TinyJSONDecoder, using strategy: JSONDecoder.DateDecodingStrategy) throws {
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
