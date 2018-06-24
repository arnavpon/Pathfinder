//  PathfinderTests.swift
//  PathfinderTests
//  Created by Arnav Pondicherry  on 6/23/18.
//  Copyright © 2018 Arnav Pondicherry . All rights reserved.

//

import XCTest
@testable import Pathfinder

class PathfinderTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testEuclideanDistance() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        let loc1 = (1.0, 1.0)
        let loc2 = (1.0, 2.0)
        XCTAssert(getEuclideanDistance(firstLocation: loc1, secondLocation: loc2) == 1)
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
