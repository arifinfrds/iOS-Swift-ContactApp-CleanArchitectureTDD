//
//  GojekContactAppTests.swift
//  GojekContactAppTests
//
//  Created by Arifin Firdaus on 30/11/20.
//

import XCTest
@testable import GojekContactApp

protocol HTTPClient {
    func get(from url: URL, completion: @escaping (Error?) -> Void)
}

protocol ContactService {
    func loadContacts(completion: @escaping (Error?) -> Void)
}

class ContactServiceImpl {
    private let client: HTTPClient
    private let url: URL
    
    enum Error: Swift.Error, Equatable {
        case connectivity
    }
    
    init(client: HTTPClient, url: URL) {
        self.client = client
        self.url = url
    }
    
    func loadContacts(completion: @escaping (Error?) -> Void) {
        client.get(from: url) { error in
            completion(.connectivity)
        }
    }
}


class GojekContactAppTests: XCTestCase {
    
    func test_init_doesNotRequestDataFromURL() {
        let url = URL(string: "https://any-url.com")!
        let (_, client) = makeSUT(url: url)
        
        XCTAssertTrue(client.requestedURLs.isEmpty)
    }
    
    func test_loadContacts_shouldRequestWithGivenURL() {
        let url = URL(string: "https://any-url.com")!
        let (sut, client) = makeSUT(url: url)
        
        sut.loadContacts { _ in }
        
        XCTAssertEqual(client.requestedURLs, [url])
    }
    
    func test_loadContactsTwice_shouldRequestWithGivenURLTwice() {
        let url = URL(string: "https://any-url.com")!
        let (sut, client) = makeSUT(url: url)
        
        sut.loadContacts { _ in }
        sut.loadContacts { _ in }
        
        XCTAssertEqual(client.requestedURLs, [url, url])
    }
    
    func test_loadContacts_deliversErrorOnClientError() {
        let url = URL(string: "https://any-url.com")!
        let (sut, client) = makeSUT(url: url)
        let error: ContactServiceImpl.Error = .connectivity
        client.error = error
        
        var capturedErrors: [ContactServiceImpl.Error] = []
        sut.loadContacts { error in
            if let error = error {
                capturedErrors.append(error)
            }
        }
        
        XCTAssertEqual(capturedErrors, [.connectivity])
    }
    
    
    // MARK: - Helpers
    
    private func makeSUT(url: URL) -> (sut: ContactServiceImpl, client: HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = ContactServiceImpl(client: client, url: url)
        return (sut, client)
    }
    
    private class HTTPClientSpy: HTTPClient {
        var requestedURLs: [URL] = []
        var error: Error?
        
        func get(from url: URL, completion: @escaping (Error?) -> Void) {
            self.requestedURLs.append(url)
            if let error = error {
                completion(error)
            }
        }
        
        func complete(with error: Error) {
            self.error = error
        }
    }
    
}
