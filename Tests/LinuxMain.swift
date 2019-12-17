import XCTest

import git_syncTests

var tests = [XCTestCaseEntry]()
tests += git_syncTests.allTests()
XCTMain(tests)
