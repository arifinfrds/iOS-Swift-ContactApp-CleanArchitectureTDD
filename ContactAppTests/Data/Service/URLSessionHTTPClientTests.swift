//
//  URLSessionHTTPClientTests.swift
//  ContactAppTests
//
//  Created by Arifin Firdaus on 26/12/20.
//

import XCTest
@testable import ContactApp

class URLSessionHTTPClient: HTTPClient {
    private let session: URLSession
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
        session.dataTask(with: url) { (_, _, error) in
            if let error = error {
                completion(.failure(error))
            }
        }.resume()
    }
}

class URLSessionHTTPClientTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        URLProtocolStub.startInterceptingRequests()
    }
    
    override func tearDown() {
        super.tearDown()
        URLProtocolStub.stopInterceptingRequests()
    }
    
    func test_getFromURL_performGETWithURL() {
        // given
        let url = makeAnyURL()
        let sut = URLSessionHTTPClient()
        
        // when & then
        URLProtocolStub.observeRequest { urlRequest in
            XCTAssertEqual(urlRequest.httpMethod, "GET")
            XCTAssertEqual(urlRequest.url, url)
        }
        
        sut.get(from: url) { _ in }
    }
    
    func test_getFromURL_failsOnAnyInvalidRepresentableCases() {
        let givenError = NSError(domain: "Any Error", code: 1)
        XCTAssertNotNil(getResultFor(data: nil, response: nil, error: givenError))
    }
    
    
    // MARK: - Helpers
    
    
    private func getResultFor(data: Data?, response: URLResponse?, error: Error?) -> HTTPClientResult? {
        URLProtocolStub.stub(data: data, response: response, error: error)
        let sut = URLSessionHTTPClient()
        
        // when
        let exp = expectation(description: "Wait for completion")
        var receivedResult: HTTPClientResult?
        sut.get(from: makeAnyURL()) { result in
            receivedResult = result
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
        return receivedResult
    }
    
    
    private func makeAnyURL() -> URL {
        return URL(string: "https://any-url.com")!
    }
    
    private class URLProtocolStub: URLProtocol {
        private static var stub: Stub?
        private static var requestObserver: ((URLRequest) -> Void)?
        
        private struct Stub {
            let data: Data?
            let response: URLResponse?
            let error: Error?
        }
        
        static func stub(data: Data?, response: URLResponse?, error: Error?) {
            let stub = Stub(data: data, response: response, error: error)
            self.stub = stub
        }
        
        static func observeRequest(completion: @escaping (URLRequest) -> Void) {
            self.requestObserver = completion
        }
        
        static func startInterceptingRequests() {
            URLProtocolStub.registerClass(URLProtocolStub.self)
        }
        
        static func stopInterceptingRequests() {
            URLProtocolStub.unregisterClass(URLProtocolStub.self)
            stub = nil
            requestObserver = nil
        }
     
        override class func canInit(with request: URLRequest) -> Bool {
            return true
        }
        
        override class func canonicalRequest(for request: URLRequest) -> URLRequest {
            return request
        }
        
        override func startLoading() {
            if let requestObserver = URLProtocolStub.requestObserver {
                self.client?.urlProtocolDidFinishLoading(self)
                requestObserver(request)
                return
            }
            if let error = URLProtocolStub.stub?.error {
                self.client?.urlProtocol(self, didFailWithError: error)
            }
        }
        
        override func stopLoading() { }
    }

}
