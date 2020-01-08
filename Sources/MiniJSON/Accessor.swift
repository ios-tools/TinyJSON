//
//  Accessor.swift
//  JSONKit
//
//  Created by Cemen Istomin on 20/10/2018.
//  Covered by MIT license.
//
//  Lightweight JSON traversal library inspired by SwiftyJSON.
//  Tuned to be better alternative for working w Swift 4 Codable.
//

import Foundation

@dynamicMemberLookup
struct JSON {
    var raw: Any?
    let path: [Key]
    
    enum Key {
        case name(String)
        case index(Int)
    }
    
    init(_ object: Any? = nil, path: [Key] = []) {
        raw = object
        self.path = path
        self.nullStrategy = JSON.nullStrategy   // use current default null strategy (can be changed by client)
    }
    
    var exists: Bool { return raw != nil }
    var isNull: Bool { return raw is NSNull }
    
    subscript(key: String) -> JSON {
        get {
            let newPath = path.appending(.name(key))
            guard let dictionary = raw as? [String: Any] else { return JSON(path: newPath) }
            return JSON(dictionary[key], path: newPath)
        }
        set {
            var dictionary = raw as! [String: Any]
            dictionary[key] = newValue.raw
            raw = dictionary
        }
    }
    
    subscript(index: Int) -> JSON {
        get {
            let newPath = path.appending(.index(index))
            guard let array = raw as? [Any] else { return JSON(path: newPath) }
            guard index < array.count else { return JSON(path: newPath) }
            return JSON(array[index], path: newPath)
        }
        set {
            var array = raw as! [Any]
            if index < array.count {
                array[index] = newValue.raw!
            }
            else if index == array.count {
                array.append(newValue.raw!)
            }
            raw = array
        }
    }
    
    subscript(dynamicMember member: String) -> JSON {
        get { return self[member] }
        set { self[member] = newValue }
    }
    
    // MARK: Accessors
    
    func stringConvertible<T: LosslessStringConvertible>() -> T? {
        if let already = raw as? T { return already }
        if let string = raw as? String { return T(string) }
        return nil
    }
    
    var string: String? {
        get { return raw as? String }
        set { raw = newValue }
    }
    
    var int: Int? {
        get { return stringConvertible() }
        set { raw = newValue }
    }
    var int8: Int8? {
        get { return stringConvertible() }
        set { raw = newValue }
    }
    var int16: Int16? {
        get { return stringConvertible() }
        set { raw = newValue }
    }
    var int32: Int32? {
        get { return stringConvertible() }
        set { raw = newValue }
    }
    var int64: Int64? {
        get { return stringConvertible() }
        set { raw = newValue }
    }
    
    var uint: UInt? {
        get { return stringConvertible() }
        set { raw = newValue }
    }
    var uint8: UInt8? {
        get { return stringConvertible() }
        set { raw = newValue }
    }
    var uint16: UInt16? {
        get { return stringConvertible() }
        set { raw = newValue }
    }
    var uint32: UInt32? {
        get { return stringConvertible() }
        set { raw = newValue }
    }
    var uint64: UInt64? {
        get { return stringConvertible() }
        set { raw = newValue }
    }
    
    var float: Float? {
        get { return stringConvertible() }
        set { raw = newValue }
    }
    var double: Double? {
        get { return stringConvertible() }
        set { raw = newValue }
    }
//    var decimal: Decimal? { return stringConvertible() }      // later
    
    var bool: Bool? {
        if let fromStr: Bool = stringConvertible() { return fromStr }
        if let int: Int = stringConvertible() { return int != 0 }       // 0 / 1 flag types
        return nil
    }
    
    var array: [JSON]? {
        guard let array = raw as? [Any] else { return nil }
        var result: [JSON] = []
        for i in 0 ..< array.count {
            result.append(JSON(array[i], path: self.path.appending(.index(i))))
        }
        return result
    }
    
    var dictionary: [String: JSON]? {
        guard let dict = raw as? [String: Any] else { return nil }
        var result: [String: JSON] = [:]
        for (key, value) in dict {
            result[key] = JSON(value, path: path.appending(.name(key)))
        }
        return result
    }
    
    //MARK: non-optional accessors
    
    enum NullStrategy {
        case forceUnwrap, useEmptyValue
        case custom((JSON) -> Any)
    }
    static var nullStrategy: NullStrategy = .forceUnwrap
    var nullStrategy: NullStrategy
    
    private func unwrap<T: TypeWithDefaultValue>(value: T?) -> T {
        switch nullStrategy {
        case .forceUnwrap: return value!
        case .useEmptyValue: return value ?? T()
        case .custom(let closure): return closure(self) as! T
        }
    }
    
    var stringValue: String {
        get { return unwrap(value: string) }
        set { raw = newValue }
    }
    
    var intValue: Int {
        get { return unwrap(value: int) }
        set { raw = newValue }
    }
    var int8Value: Int8 {
        get { return unwrap(value: int8) }
        set { raw = newValue }
    }
    var int16Value: Int16 {
        get { return unwrap(value: int16) }
        set { raw = newValue }
    }
    var int32Value: Int32 {
        get { return unwrap(value: int32) }
        set { raw = newValue }
    }
    var int64Value: Int64 {
        get { return unwrap(value: int64) }
        set { raw = newValue }
    }
    
    var uintValue: UInt {
        get { return unwrap(value: uint) }
        set { raw = newValue }
    }
    var uint8Value: UInt8 {
        get { return unwrap(value: uint8) }
        set { raw = newValue }
    }
    var uint16Value: UInt16 {
        get { return unwrap(value: uint16) }
        set { raw = newValue }
    }
    var uint32Value: UInt32 {
        get { return unwrap(value: uint32) }
        set { raw = newValue }
    }
    var uint64Value: UInt64 {
        get { return unwrap(value: uint64) }
        set { raw = newValue }
    }
    
    var floatValue: Float {
        get { return unwrap(value: float) }
        set { raw = newValue }
    }
    var doubleValue: Double {
        get { return unwrap(value: double) }
        set { raw = newValue }
    }
    
    var boolValue: Bool {
        get { return unwrap(value: bool) }
        set { raw = newValue }
    }
}

extension Array where Element == JSON.Key {
    func appending(_ component: JSON.Key) -> Array {
        var new = self
        new.append(component)
        return new
    }
}

extension JSON.Key: CodingKey {
    var stringValue: String {
        switch self {
        case .name(let value): return value
        case .index(let value): return "\(value)"
        }
    }
    
    var intValue: Int? {
        switch self {
        case .name(_): return nil
        case .index(let value): return value
        }
    }
    
    init?(stringValue: String) {
        self = .name(stringValue)
    }
    
    init?(intValue: Int) {
        self = .index(intValue)
    }
}

/// any type that has available initializer with no parameters, which can be used as "default" value for this type.
/// Used to substitute absent JSON primitive property values with some empty value (ie "", 0, 0.0 and such)
protocol TypeWithDefaultValue {
    init()
}

//extension TypeWithDefaultValue where Self: BinaryInteger {
//    static var defaultValue: Self { return 0 }
//}
//
//extension TypeWithDefaultValue where Self: BinaryFloatingPoint {
//    static var defaultValue: Self { return 0.0 }
//}
//
//extension String: TypeWithDefaultValue {
//    static let defaultValue = ""
//}
//
//extension Bool: TypeWithDefaultValue {
//    static let defaultValue = false
//}

extension String: TypeWithDefaultValue {}
extension Bool: TypeWithDefaultValue {}

extension Int: TypeWithDefaultValue {}
extension Int8: TypeWithDefaultValue {}
extension Int16: TypeWithDefaultValue {}
extension Int32: TypeWithDefaultValue {}
extension Int64: TypeWithDefaultValue {}
extension UInt: TypeWithDefaultValue {}
extension UInt8: TypeWithDefaultValue {}
extension UInt16: TypeWithDefaultValue {}
extension UInt32: TypeWithDefaultValue {}
extension UInt64: TypeWithDefaultValue {}

extension Float: TypeWithDefaultValue {}
extension Double: TypeWithDefaultValue {}
