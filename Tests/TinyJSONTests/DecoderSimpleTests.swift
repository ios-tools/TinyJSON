import XCTest
import Nimble
@testable import TinyJSON

struct User: Codable {
    var firstName: String
    var lastName: String
    var email: String?
    var age: Int
    var happiness: Float
    var height: Int
    
    var hasChildren: Bool
    var hasGrandchildren: Bool
    var hasCousins: Bool
    var hasTwin: Bool
    
    struct Gadget: Codable {
        enum GadgetType: String, Codable {
            case phone, laptop
        }
        var type: GadgetType
        var name: String
    }
    var gadgets: [Gadget]
}

final class DecoderTests: XCTestCase {
    
    func testBareDecoding() {
        let data = try! Resource.json("user")
        let json = JSON(data)
        let maybeUser: User? = json.tryDecode()
        
        expect(maybeUser).notTo(beNil())
        guard let user = maybeUser else { return }
        verifyUser(user)
    }
    
    func testWrappedDecoding() {
        let data = try! Resource.json("user_response")
        let json = JSON(data)
        let maybeUser: User? = json["payload"].tryDecode()
        
        expect(maybeUser).notTo(beNil())
        guard let user = maybeUser else { return }
        verifyUser(user)
    }
    
    func verifyUser(_ user: User) {
        expect(user.firstName) == "John"
        expect(user.lastName) == "Smith"
        expect(user.email).to(beNil())
        expect(user.age) == 20
        expect(user.happiness) == 5.5
        expect(user.height) == 170
        
        expect(user.hasChildren).to(beTrue())
        expect(user.hasGrandchildren).to(beFalse())
        expect(user.hasCousins).to(beTrue())
        expect(user.hasTwin).to(beFalse())
        
        expect(user.gadgets).to(haveCount(2))
        expect(user.gadgets[0].type) == .phone
        expect(user.gadgets[0].name) == "iPhone"
        expect(user.gadgets[1].type) == .laptop
        expect(user.gadgets[1].name) == "linux"
    }
    
    func testMalformedInput() {
        let data = try! Resource.json("user_malformed")
        let json = JSON(data)
        
        expect { try json.missingKey.decode() as User }.to(throwError(closure: { (error) in
            guard case DecodingError.keyNotFound(let key, let context) = error else { fail("wrong error"); return }
            expect(key.stringValue).to(equal("lastName"))
        }))
        
        expect { try json.missingValue.decode() as User }.to(throwError(closure: { (error) in
            guard case DecodingError.valueNotFound(let type, let context) = error else { fail("wrong error"); return }
            expect(type == String.self).to(beTrue())
            expect(context.codingPath.last?.stringValue) == "lastName"
        }))
        
        expect { try json.wrongType.decode() as User }.to(throwError(closure: { (error) in
            guard case DecodingError.typeMismatch(let type, let context) = error else { fail("wrong error"); return }
            expect(type == Int.self).to(beTrue())
            expect(context.codingPath.last?.stringValue) == "age"
        }))
    }
    
    func testDefaultValues() {
        let data = try! Resource.json("user_malformed")
        let json = JSON(data)
        
        
        expect {
            let user: User = try json.missingKey.silentDecode()
            expect(user.lastName) == ""
            return nil
        }.notTo(throwError())
        
        
        expect {
            let user: User = try json.missingValue.silentDecode()
            expect(user.lastName) == ""
            return nil
        }.notTo(throwError())
        
    }
    
    //    static var allTests = [
    //        ("testReading", testReading),
    //    ]
}
