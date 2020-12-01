//
//  ContactServiceImplTests.swift
//  GojekContactAppTests
//
//  Created by Arifin Firdaus on 30/11/20.
//

import XCTest
@testable import GojekContactApp

class ContactServiceImplTests: XCTestCase {
    
    func test_init_doesNotRequestDataFromURL() {
        // given
        let (_, client) = makeSUT()
        
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
        let (sut, client) = makeSUT()
        
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
        let (sut, client) = makeSUT()
        
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
        let (sut, client) = makeSUT()
        
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
        let (sut, client) = makeSUT()
        
        // when
        var capturedUsers: [UserResponseDTO] = []
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
        let (sut, client) = makeSUT()
        
        // when
        var capturedUsers: [UserResponseDTO] = []
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
        
        let expectedUsers = try! JSONDecoder().decode([UserResponseDTO].self, from: usersJSONData)
        XCTAssertEqual(capturedUsers, expectedUsers)
    }
    
    func test_loadContacts_doesNotResultAfterSUTInstanceHasBeenDeallocated() {
        let url = URL(string: "https://any-url.com")!
        let client = HTTPClientSpy()
        var sut: ContactServiceImpl? = ContactServiceImpl(client: client, url: url)
        
        var capturedResults: [LoadContactsResult] = []
        sut?.loadContacts { result in
            capturedResults.append(result)
        }
        sut = nil
        
        let usersJSONData = makeJSONData(forResourceJsonName: "users")
        client.complete(withStatusCode: 200, data: usersJSONData)
        
        XCTAssertTrue(capturedResults.isEmpty)
    }
    
    
    private func makeJSONData(forResourceJsonName name: String) -> Data {
        let jsonURL = Bundle(for: ContactServiceImplTests.self).url(forResource: name, withExtension: "json")!
        let data = try! Data(contentsOf: jsonURL)
        return data
    }
    
    
    // MARK: - Helpers
    
    private func makeSUT(url: URL = URL(string: "https://any-url.com")!, file: StaticString = #filePath, line: UInt = #line) -> (sut: ContactServiceImpl, client: HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = ContactServiceImpl(client: client, url: url)
        // trackForMemoryLeaks(instance: client, file: file, line: line)
        // trackForMemoryLeaks(instance: sut, file: file, line: line)
        return (sut, client)
    }
    
    private func trackForMemoryLeaks(instance: AnyObject, file: StaticString = #filePath, line: UInt = #line) {
        addTeardownBlock { [weak instance] in
            XCTAssertNil(instance, "Instance should have been deallocated. Potential memory leaks.", file: file, line: line)
        }
    }
    
    private class HTTPClientSpy: HTTPClient {
        var messages: [(url: URL, completion: (HTTPClientResult) -> Void)] = []
        var requestedURLs: [URL] {
            return messages.map {  $0.url }
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
