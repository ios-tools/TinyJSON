//
//  EncoderSimpleTests.swift
//  MiniJSONTests
//
//  Created by Cemen Istomin on 05/11/2018.
//

import XCTest
import Nimble
@testable import MiniJSON

class EncoderSimpleTests: XCTestCase {
    
    let sample = User(firstName: "John",
                      lastName: "Smith",
                      email: nil,
                      age: 20,
                      happiness: 5.5,
                      height: 170,
                      hasChildren: true,
                      hasGrandchildren: false,
                      hasCousins: true,
                      hasTwin: false,
                      gadgets: [
                        User.Gadget(type: .phone,
                                    name: "iPhone"),
                        User.Gadget(type: .laptop,
                                    name: "linux")])

    func testExample() {
        let encoder = MiniJSONEncoder()
        try! sample.encode(to: encoder)
        
        expect(encoder.json["firstName"].string) == "John"
        expect(encoder.json["lastName"].string) == "Smith"
//        expect(encoder.json["email"].isNull).to(beTrue())     // nil values are not encoded...
        expect(encoder.json["gadgets"][0]["type"].string) == "phone"
        expect(encoder.json["gadgets"][1]["name"].string) == "linux"
    }
    
}
