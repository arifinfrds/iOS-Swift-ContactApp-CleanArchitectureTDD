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
        let url = URL(string: "https://any-url.com")!
        let givenError = NSError(domain: "Any Error", code: 1)
        let sut = URLSessionHTTPClient()
        
        // when
        sut.get(from: url) { result in
            switch result {
            case .failure(let receivedError as NSError):
                // then
                XCTAssertEqual(receivedError, givenError)
            default:
                XCTFail("Expected failure, but fot success instead.")
            }
        }
        
        
    }

}
