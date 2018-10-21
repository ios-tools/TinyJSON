import XCTest
import Nimble
@testable import MiniJSON

struct User: Codable {
    var firstName: String
    var lastName: String
    var email: String?
    var age: Int
    var happiness: Float
    var height: Int
    
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
        
        expect(user.gadgets).to(haveCount(2))
        expect(user.gadgets[0].type) == .phone
        expect(user.gadgets[0].name) == "iPhone"
        expect(user.gadgets[1].type) == .laptop
        expect(user.gadgets[1].name) == "linux"
    }
    
    //    static var allTests = [
    //        ("testReading", testReading),
    //    ]
}
