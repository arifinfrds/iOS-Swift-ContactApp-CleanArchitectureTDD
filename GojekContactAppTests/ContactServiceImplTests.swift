//
//  ContactServiceImplTests.swift
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
                let users = try! JSONDecoder().decode([User].self, from: data)
                completion(.success(users))
            case .failure(_):
                completion(.failure(.connectivity))
            }
        }
    }
}

struct User: Codable, Equatable {
    let firstName: String
    let lastName: String
    
    enum CodingKeys: String, CodingKey {
        case firstName = "first_name"
        case lastName = "last_name"
    }
}


class ContactServiceImplTests: XCTestCase {
    
    func test_init_doesNotRequestDataFromURL() {
        // given
        let url = URL(string: "https://any-url.com")!
        let (_, client) = makeSUT(url: url)
        
        // then
        XCTAssertTrue(client.requestedURLs.isEmpty)
    }
    
    func test_loadContacts_shouldRequestWithGivenURL() {
        // given
        let url = URL(string: "https://any-url.com")!
        let (sut, client) = makeSUT(url: url)
        
        // when
        sut.loadContacts { _ in }
        
        // then
        XCTAssertEqual(client.requestedURLs, [url])
    }
    
    func test_loadContactsTwice_shouldRequestWithGivenURLTwice() {
        // given
        let url = URL(string: "https://any-url.com")!
        let (sut, client) = makeSUT(url: url)
        
        // when
        sut.loadContacts { _ in }
        sut.loadContacts { _ in }
        
        // then
        XCTAssertEqual(client.requestedURLs, [url, url])
    }
    
    func test_loadContacts_deliversErrorOnClientError() {
        // given
        let url = URL(string: "https://any-url.com")!
        let (sut, client) = makeSUT(url: url)
        
        // when
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
        
        // then
        XCTAssertEqual(capturedErrors, [.connectivity])
    }
    
    func test_loadContacts_deliversErrorOnNon200HTTTPResponse() {
        // given
        let url = URL(string: "https://any-url.com")!
        let (sut, client) = makeSUT(url: url)
        
        // when
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
                
                // then
                XCTAssertEqual(capturedErrors, [.invalidData])
            }
        }
    }
    
    func test_loadContacts_deliversErrorOn200ResponseWithInvalidJSON() {
        // given
        let url = URL(string: "https://any-url.com")!
        let (sut, client) = makeSUT(url: url)
        
        // when
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
            
            // then
            XCTAssertEqual(capturedErrors, [.invalidData])
        }
    }
    
    func test_loadContacts_deliversNoItemsOn200HTTPResponseWithEmptyJSONList() {
        // given
        let url = URL(string: "https://any-url.com")!
        let (sut, client) = makeSUT(url: url)
        
        // when
        var capturedUsers: [User] = []
        sut.loadContacts { result in
            switch result {
            case .success(let users):
                capturedUsers = users
            case .failure(let error):
                XCTFail("Expected success, but got error instead, erro: \(error)")
            }
        }
        let emptyUsersJSONData = makeJSONData(forResourceJsonName: "users-empty")
        client.complete(withStatusCode: 200, data: emptyUsersJSONData)
        
        // then
        XCTAssertTrue(capturedUsers.isEmpty)
    }
    
    func test_loadContacts_deliversItemsOn200HTTPResponseWithJSONList() {
        // given
        let url = URL(string: "https://any-url.com")!
        let (sut, client) = makeSUT(url: url)
        
        // when
        var capturedUsers: [User] = []
        sut.loadContacts { result in
            switch result {
            case .success(let users):
                capturedUsers = users
            case .failure(let error):
                XCTFail("Expected success, but got error instead, erro: \(error)")
            }
        }
        let usersJSONData = makeJSONData(forResourceJsonName: "users")
        
        // then
        client.complete(withStatusCode: 200, data: usersJSONData)
        
        let expectedUsers = try! JSONDecoder().decode([User].self, from: usersJSONData)
        XCTAssertEqual(capturedUsers, expectedUsers)
    }
    
    private func makeJSONData(forResourceJsonName name: String) -> Data {
        let jsonURL = Bundle(for: ContactServiceImplTests.self).url(forResource: name, withExtension: "json")!
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
