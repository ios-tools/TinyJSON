//
//  Resource.swift
//  JSONKitTests
//
//  Created by Cemen Istomin on 20/10/2018.
//  Copyright © 2018 len-stone.com team. All rights reserved.
//

import Foundation
import XCTest
@testable import MiniJSON

enum ResourceError: Error {
    case notFound
    case wrongFormat
}

final class Resource {
    static func json(_ name: String, extension ext: String = "json", bundle: Bundle = .test) throws -> Any {
        guard let url = bundle.url(forResource: name, withExtension: ext) else { throw ResourceError.notFound }
        let data = try Data(contentsOf: url)
        return try JSONSerialization.jsonObject(with: data)
    }
}

extension Bundle {
    static let test = Bundle(for: Resource.self)
}
