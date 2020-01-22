//
//  ParsingExtension.swift
//  TinyJSON
//
//  Created by Cemen Istomin on 26/12/2018.
//
//  an example of parsing extension with some customization of parser

import Foundation
@testable import TinyJSON

extension JSON {
    func decode<T: Decodable>() throws -> T {
        let decoder = TinyJSONDecoder(json: self)
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
    
    func silentDecode<T: Decodable>() throws -> T {
        let decoder = TinyJSONDecoder(json: self)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        decoder.dateDecodingStrategy = .formatted(dateFormatter)
        decoder.wrongStructureStrategy = .useDefault
        
        return try T(from: decoder)
    }
}
