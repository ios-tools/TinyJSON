import XCTest

import MiniJSONTests

var tests = [XCTestCaseEntry]()
tests += MiniJSONTests.allTests()
XCTMain(tests)