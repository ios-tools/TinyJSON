import XCTest
import Nimble
@testable import MiniJSON

final class AccessorTests: XCTestCase {
    
    func testReading() {
        let data = try! Resource.json("user")
        let json = JSON(data)
        
        expect(json["firstName"].string) == "John"
        expect(json["lastName"].stringValue) == "Smith"
        expect(json["not_exist"].exists).to(beFalse())
        expect(json["email"].isNull).to(beTrue())
        expect(json["email"].exists).to(beTrue())
        expect(json["email"].string).to(beNil())
        expect(json["age"].int) == 20
        expect(json["happiness"].float) == 5.5
        expect(json["height"].int) == 170
        
        expect(json["gadgets"][0]["type"].string) == "phone"
        expect(json["gadgets"][0]["name"].string) == "iPhone"
        expect(json["gadgets"][1]["type"].string) == "laptop"
        expect(json["gadgets"][1]["name"].string) == "linux"
        
        expect(json["hasChildren"].bool) == true
        expect(json["hasGrandchildren"].bool) == false
        expect(json["hasCousins"].bool) == true
        expect(json["hasTwin"].bool) == false
    }
    
    func testBoolChange() {
        let data = try! Resource.json("user")
        var json = JSON(data)
        
        expect(json["hasChildren"].bool) == true
        json["hasChildren"].raw = false
        expect(json["hasChildren"].bool) == false
    }
    
    func testDeepChange() {
        let data = try! Resource.json("user")
        var json = JSON(data)
        
        json["gadgets"][0]["name"].string = "bell"
        expect(json["gadgets"][0]["name"].string) == "bell"
    }
    
    func testDynamicLookup() {
        let data = try! Resource.json("user")
        var json = JSON(data)
        
        expect(json.firstName.string) == "John"
        expect(json.gadgets[0].name.string) == "iPhone"
        
        json.gadgets[0].name.string = "bell"
        expect(json.gadgets[0].name.string) == "bell"
    }
    
    func testDefaultValues() {
        
    }

//    static var allTests = [
//        ("testReading", testReading),
//    ]
}
