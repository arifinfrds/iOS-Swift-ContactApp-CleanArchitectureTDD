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
    
    struct UnexpectedValuesRepresentation: Error { }
    
    func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
        session.dataTask(with: url) { (data, response, error) in
            if let error = error {
                completion(.failure(error))
            }
            else if let data = data, let httpURLResponse = response as? HTTPURLResponse {
                completion(.success(data, httpURLResponse))
            }
            else {
                completion(.failure(UnexpectedValuesRepresentation()))
            }
        }
        .resume()
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
    
    func test_getFromURL_failsOnAllInvalidRepresentationCases() {
        XCTAssertNotNil(resultForError(data: nil, response: nil, error: nil))
        XCTAssertNotNil(resultForError(data: nil, response: makeNonHTTPURLResponse(), error: nil))
        XCTAssertNotNil(resultForError(data: makeAnyData(), response: nil, error: nil))
        XCTAssertNotNil(resultForError(data: makeAnyData(), response: nil, error: makeAnyNSError()))
        XCTAssertNotNil(resultForError(data: nil, response: makeNonHTTPURLResponse(), error: makeAnyNSError()))
        XCTAssertNotNil(resultForError(data: nil, response: makeAnyHTTPURLResponse(), error: makeAnyNSError()))
        XCTAssertNotNil(resultForError(data: makeAnyData(), response: makeNonHTTPURLResponse(), error: makeAnyNSError()))
        XCTAssertNotNil(resultForError(data: makeAnyData(), response: makeAnyHTTPURLResponse(), error: makeAnyNSError()))
        XCTAssertNotNil(resultForError(data: makeAnyData(), response: makeNonHTTPURLResponse(), error: nil))
    }
    
    func test_getFromURL_succedsOnHTTPURLResponseWithData() {
        // given
        let givenData = makeAnyData()
        let givenHTTPURLResponse = makeAnyHTTPURLResponse()
        URLProtocolStub.stub(data: givenData, response: givenHTTPURLResponse, error: nil)
        let sut = makeSUT()
        
        // when
        sut.get(from: makeAnyURL()) { result in
            switch result {
            case let .success(data, response):
                // then
                XCTAssertEqual(data, givenData)
                XCTAssertEqual(response, givenHTTPURLResponse)
            default:
                XCTFail("Expect success with result \(result), got failure instead.")
            }
        }
    }
    
    
    // MARK: - Helpers
    
    private func resultForError(data: Data?, response: URLResponse?, error: Error?, file: StaticString = #filePath, line: UInt = #line) -> Error? {
        URLProtocolStub.stub(data: data, response: response, error: error)
        
        let exp = expectation(description: "wait for completion")
        var capturedError: Error?
        makeSUT().get(from: makeAnyURL()) { result in
            switch result {
            case let .failure(error):
                capturedError = error
            default:
                XCTFail("Expect failure with error, but result instead, result: \(result)")
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
        return capturedError
    }
    
    private func makeAnyData() -> Data {
        return "any-data".data(using: .utf8)!
    }
    
    private func makeAnyURLResponse() -> URLResponse {
        return URLResponse(url: makeAnyURL(), mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
    }
    
    private func makeNonHTTPURLResponse() -> URLResponse {
        return URLResponse(url: makeAnyURL(), mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
    }
    
    private func makeAnyHTTPURLResponse() -> HTTPURLResponse {
        return HTTPURLResponse(url: makeAnyURL(), statusCode: 200, httpVersion: nil, headerFields: nil)!
    }
    
    private func makeSUT() -> URLSessionHTTPClient {
        return URLSessionHTTPClient()
    }
    
    private func makeAnyNSError() -> NSError {
        return NSError(domain: "Any Error", code: 1)
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
            if let data = URLProtocolStub.stub?.data {
                self.client?.urlProtocol(self, didLoad: data)
            }
            if let response = URLProtocolStub.stub?.response {
                self.client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            }
            if let error = URLProtocolStub.stub?.error {
                self.client?.urlProtocol(self, didFailWithError: error)
            }
            self.client?.urlProtocolDidFinishLoading(self)
        }
        
        override func stopLoading() { }
    }

}
