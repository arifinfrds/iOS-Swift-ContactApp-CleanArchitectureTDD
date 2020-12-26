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
    
    func test_getFromURL_deliversAnyError() {
        // given
        URLProtocol.registerClass(URLProtocolStub.self)
        let url = URL(string: "https://any-url.com")!
        let givenError = NSError(domain: "Any Error", code: 1)
        URLProtocolStub.stub(url: url, data: nil, response: nil, error: givenError)
        let sut = URLSessionHTTPClient()
        
        // when
        let exp = expectation(description: "Wait for completion")
        sut.get(from: url) { result in
            switch result {
            case .failure(let receivedError as NSError):
                // then
                XCTAssertEqual(receivedError.domain, givenError.domain)
                XCTAssertEqual(receivedError.code, givenError.code)
            default:
                XCTFail("Expected failure, but fot success instead.")
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
        URLProtocol.unregisterClass(URLProtocolStub.self)
    }
    
    
    // MARK: - Helpers
    
    private class URLProtocolStub: URLProtocol {
        private static var stubs: [URL: Stub] = [:]
        
        private struct Stub {
            let data: Data?
            let response: URLResponse?
            let error: Error?
        }
        
        static func stub(url: URL, data: Data?, response: URLResponse?, error: Error) {
            let stub = Stub(data: data, response: response, error: error)
            stubs[url] = stub
        }
     
        override class func canInit(with request: URLRequest) -> Bool {
            guard let url = request.url else {
                return false
            }
            if URLProtocolStub.stubs[url] == nil {
                return false
            }
            return true
        }
        
        override class func canonicalRequest(for request: URLRequest) -> URLRequest {
            return request
        }
        
        override func startLoading() {
            if let url = self.request.url, let error = URLProtocolStub.stubs[url]?.error {
                self.client?.urlProtocol(self, didFailWithError: error)
            }
        }
        
        override func stopLoading() { }
    }

}
