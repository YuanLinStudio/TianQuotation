    import XCTest
    @testable import TianQuotation

    final class TianQuotationTests: XCTestCase {
        
        func testEndpointContent() {
            let endpoint = TXEndpoint(token: "test-token")
            
            let assertResult = "https://api.tianapi.com/txapi/zaoan/index?key=test-token"
            XCTAssertEqual(endpoint.url.absoluteString, assertResult)
        }
        
        func testEndpointCodable() {
            let endpoint = TXEndpoint(token: "test-token")
            
            let assertData =
                """
                {
                    "token": "test-token",
                }
                """
                .data(using: .utf8)!
            
            let assertObject = try! JSONDecoder().decode(TXEndpoint.self, from: assertData)
            
            XCTAssertEqual(endpoint, assertObject)
        }
        
        func testRequestValidResponded() {
            let expectation = self.expectation(description: "request")
            var testData: Data?
            var testError: Error?
            
            let token = "test-token"
            let request = TXRequest()
            request.endpoint.token = token
            XCTAssertEqual(request.endpoint.token, token)
            
            request.fetchDataFromRemote { data, error in
                testData = data
                testError = error
                expectation.fulfill()
            }
            waitForExpectations(timeout: 5, handler: nil)
            XCTAssertNotNil(testData)
            XCTAssertNil(testError)
        }
        
        func testLocalSourceResponse() {
            let expectation = self.expectation(description: "response")
            var testResponse: TXResponse?
            var testError: Error?
            var testContent: String?
            
            let request = TXRequest()
            
            request.fetchExampleData { data, error in
                request.decode(data!) { response, error in
                    testResponse = response
                    testError = error
                    testContent = response?.result[0].content
                    expectation.fulfill()
                }
            }
            
            waitForExpectations(timeout: 5, handler: nil)
            XCTAssertNil(testError)
            XCTAssertNotNil(testResponse)
            XCTAssertEqual(testContent!, "用努力去喂养梦想，愿跌倒不哭，明媚如初，早安。")
        }
        
        func testResponseEquallyCodable() {
            let expectation = self.expectation(description: "response")
            var firstResponse: TXResponse?
            var secondResponse: TXResponse?
            var thirdResponse: TXResponse?
            var secondData: Data?
            var thirdData: Data?
            
            let path = Bundle.module.path(forResource: "MorningQuotation", ofType: "json")!
            let data = try! Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
            
            let request = TXRequest()
            
            request.decode(data) { response1st, _ in
                firstResponse = response1st
                
                secondData = try? JSONEncoder().encode(firstResponse!)
                
                request.decode(secondData!) { response2nd, _ in
                    secondResponse = response2nd
                    
                    thirdData = try? JSONEncoder().encode(secondResponse!)
                    
                    request.decode(thirdData!) { response3rd, _ in
                        thirdResponse = response3rd
                        
                        expectation.fulfill()
                    }
                }
            }
            waitForExpectations(timeout: 5, handler: nil)
            XCTAssertEqual(firstResponse!, secondResponse!)
            XCTAssertNotNil(secondData)
            XCTAssertNotNil(thirdData)
            XCTAssertEqual(secondData, thirdData)
            XCTAssertNotNil(secondResponse)
            XCTAssertNotNil(thirdResponse)
            XCTAssertEqual(secondResponse, thirdResponse)
        }
    }
