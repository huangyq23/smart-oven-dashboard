//
//  SmartOvenDashboardTests.swift
//  SmartOvenDashboardTests
//
//

import XCTest

@testable import SmartOvenDashboard

final class SmartOvenDashboardTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // Any test you write for XCTest can be annotated as throws and async.
        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
        // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.
        
        
        let fry = """
{
            "cookId": "ios-dcbaa973-18ec-4989-9eb6-723710875c60",
            "stages": [
                {
                    "stepType": "stage",
                    "id": "quick_start.PEweV5DHcEvZT7y3IDcX.ios-8a041340-2b8c-47c7-a753-bdced94b010e",
                    "title": "Preheat ",
                    "description": "",
                    "type": "preheat",
                    "userActionRequired": false,
                    "temperatureBulbs": {
                        "dry": {
                            "setpoint": {
                                "celsius": 225,
                                "fahrenheit": 437
                            }
                        },
                        "mode": "dry"
                    },
                    "heatingElements": {
                        "top": {
                            "on": true
                        },
                        "bottom": {
                            "on": false
                        },
                        "rear": {
                            "on": true
                        }
                    },
                    "fan": {
                        "speed": 100
                    },
                    "vent": {
                        "open": false
                    },
                    "rackPosition": 3,
                    "timerAdded": null,
                    "probeAdded": false
                },
                {
                    "stepType": "stage",
                    "id": "quick_start.PEweV5DHcEvZT7y3IDcX.ios-a51993c8-bb9d-4ea7-aace-6bf8ae2d0a71",
                    "title": "Air Fry",
                    "description": "",
                    "type": "cook",
                    "userActionRequired": false,
                    "temperatureBulbs": {
                        "dry": {
                            "setpoint": {
                                "celsius": 225,
                                "fahrenheit": 437
                            }
                        },
                        "mode": "dry"
                    },
                    "heatingElements": {
                        "top": {
                            "on": true
                        },
                        "bottom": {
                            "on": false
                        },
                        "rear": {
                            "on": true
                        }
                    },
                    "fan": {
                        "speed": 100
                    },
                    "vent": {
                        "open": false
                    },
                    "rackPosition": 3,
                    "probeAdded": false
                }
            ]
        }
"""
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let command2 = try decoder.decode(APOStartCommand.Payload.Payload.self, from: fry.data(using: .utf8)!)

        
        print(String(describing: command2))
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        measure {
            // Put the code you want to measure the time of here.
        }
    }

}
