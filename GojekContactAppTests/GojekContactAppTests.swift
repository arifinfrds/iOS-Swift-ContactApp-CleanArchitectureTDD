//
//  GojekContactAppTests.swift
//  GojekContactAppTests
//
//  Created by Arifin Firdaus on 30/11/20.
//

import XCTest
@testable import GojekContactApp


enum HTTPClientResult {
    case success(URLResponse, Data)
    case failure(Error)
}

protocol HTTPClient {
    func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void)
}

protocol ContactService {
    func loadContacts(completion: @escaping (URLResponse?, Error?) -> Void)
}

class ContactServiceImpl {
    private let client: HTTPClient
    private let url: URL
    
    enum Error: Swift.Error, Equatable {
        case connectivity
        case invalidData
    }
    
    enum LoadContactsResult {
        case success(_ items: [User])
        case failure(_ error: Error)
    }
    
    init(client: HTTPClient, url: URL) {
        self.client = client
        self.url = url
    }
    
    func loadContacts(completion: @escaping (LoadContactsResult) -> Void) {
        client.get(from: url) { result in
            switch result {
            case .success(_, let data):
                // let users = try! JSONDecoder().decode([User].self, from: data)
                completion(.success([]))
            case .failure(_):
                completion(.failure(.connectivity))
            }
        }
    }
}

struct User: Codable {
    let firstName: String
    let lastName: String
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
        
        var capturedErrors: [ContactServiceImpl.Error] = []
        sut.loadContacts { result in
            switch result {
            case .success(let users):
                XCTFail("Expected fail, but got success instead, users: \(users)")
            case .failure(let error):
                capturedErrors.append(error)
            }
        }
        let clientError = NSError(domain: NSURLErrorDomain, code: -1, userInfo: nil)
        client.complete(with: clientError)
        
        XCTAssertEqual(capturedErrors, [.connectivity])
    }
    
    func test_loadContacts_deliversErrorOnNon200HTTTPResponse() {
        let url = URL(string: "https://any-url.com")!
        let (sut, client) = makeSUT(url: url)
        
        let codes = [199, 201, 300, 400, 500]
        for (index, code) in codes.enumerated() {
            var capturedErrors: [ContactServiceImpl.Error] = []
            sut.loadContacts { result in
                switch result {
                case .success(let users):
                    XCTFail("Expected fail, but got success instead, users: \(users)")
                case .failure(let error):
                    capturedErrors.append(error)
                }
                client.complete(withStatusCode: code, at: index)
                XCTAssertEqual(capturedErrors, [.invalidData])
            }
        }
    }
    
    func test_loadContacts_deliversErrorOn200ResponseWithInvalidJSON() {
        let url = URL(string: "https://any-url.com")!
        let (sut, client) = makeSUT(url: url)
        
        var capturedErrors: [ContactServiceImpl.Error] = []
        sut.loadContacts { result in
            switch result {
            case .success(let users):
                XCTFail("Expected fail, but got success instead, users: \(users)")
            case .failure(let error):
                capturedErrors.append(error)
            }
            let invalidJSONData = "invalid-JSON-data".data(using: .utf8)!
            client.complete(withStatusCode: 200, data: invalidJSONData)
            XCTAssertEqual(capturedErrors, [.invalidData])
        }
    }
    
    func test_loadContacts_deliversNoItemsOn200HTTPResponseWithEmptyJSONList() {
        let url = URL(string: "https://any-url.com")!
        let (sut, client) = makeSUT(url: url)
        
        var capturedUsers: [User] = []
        sut.loadContacts { result in
            switch result {
            case .success(let users):
                capturedUsers = users
            case .failure(let error):
                XCTFail("Expected success, but got error instead, erro: \(error)")
            }
        }
        
        let emptyUsersJSON = makeJSONData(forResourceJsonName: "users-empty")
        client.complete(withStatusCode: 200, data: emptyUsersJSON)
        XCTAssertTrue(capturedUsers.isEmpty)
    }
    
    private func makeJSONData(forResourceJsonName name: String) -> Data {
        let jsonURL = Bundle(for: GojekContactAppTests.self).url(forResource: name, withExtension: "json")!
        let data = try! Data(contentsOf: jsonURL)
        return data
    }
    
    
    // MARK: - Helpers
    
    private func makeSUT(url: URL) -> (sut: ContactServiceImpl, client: HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = ContactServiceImpl(client: client, url: url)
        return (sut, client)
    }
    
    private class HTTPClientSpy: HTTPClient {
        var messages: [(url: URL, completion: (HTTPClientResult) -> Void)] = []
        var requestedURLs: [URL] {
            return messages.map { $0.url }
        }
        
        func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
            messages.append((url, completion))
        }
        
        func complete(with error: Error, at index: Int = 0) {
            messages[index].completion(.failure(error))
        }
        
        func complete(withStatusCode code: Int, data: Data = Data(), at index: Int = 0) {
            let response = HTTPURLResponse(
                url: requestedURLs[index],
                statusCode: code,
                httpVersion: nil,
                headerFields: nil
            )!
            messages[index].completion(.success(response, data))
        }
    }
    
}
