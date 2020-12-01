//
//  LoadContactsInteractorTests.swift
//  GojekContactAppTests
//
//  Created by Arifin Firdaus on 02/12/20.
//

import XCTest
@testable import GojekContactApp


class LoadContactsInteractorTests: XCTestCase {
    
    func test_init_doesNotExecuteInteractor() {
        let (_, client) = makeSUT()
        
        XCTAssertTrue(client.requestedURLs.isEmpty)
    }
    
    func test_execute_deliversErrorOnServiceError() {
        let (sut, client) = makeSUT()
        
        var capturedErrors: [LoadContactsInteractorImpl.Error] = []
        sut.execute { result in
            switch result {
            case .success(let users):
                XCTFail("Expected fail with error, but got success instead with users: \(users)")
            case .failure(let error):
                capturedErrors.append(error)
            }
        }
        client.complete(with: LoadContactsInteractorImpl.Error.someError)
        
        XCTAssertEqual(capturedErrors, [.someError])
    }
    
    func test_execute_deliversUsersOnValidClientResponse() {
        let (sut, client) = makeSUT()
        
        var capturedUsers: [User] = []
        sut.execute { result in
            switch result {
            case .success(let users):
                capturedUsers = users
            case .failure(let error):
                XCTFail("Expected success, but got error instead with error: \(error)")
            }
        }
        
        let usersJSONData = makeJSONData(forResourceJsonName: "users")
        client.complete(withStatusCode: 200, data: usersJSONData)
        
        let expectedUsers = [User(firstName: "Arifin", lastName: "Firdaus")]
        XCTAssertEqual(capturedUsers, expectedUsers)
    }
    
    
    // MARK: - Helpers
    
    private func makeSUT(url: URL = URL(string: "https://any-url.com")!, file: StaticString = #filePath, line: UInt = #line) -> (sut: LoadContactsInteractorImpl, client: HTTPClientSpy) {
        let client = HTTPClientSpy()
        let service = ContactServiceImpl(client: client, url: url)
        let sut = LoadContactsInteractorImpl(service: service)
        return (sut, client)
    }
    
    private func makeJSONData(forResourceJsonName name: String) -> Data {
        let jsonURL = Bundle(for: ContactServiceImplTests.self).url(forResource: name, withExtension: "json")!
        let data = try! Data(contentsOf: jsonURL)
        return data
    }
}
