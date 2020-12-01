//
//  LoadContactsInteractorTests.swift
//  GojekContactAppTests
//
//  Created by Arifin Firdaus on 02/12/20.
//

import XCTest
@testable import GojekContactApp

struct User {
    let firstName: String
    let lastName: String
}

enum LoadContactsInteractorResult {
    case success(_ items: [User])
    case failure(_ error: Error)
}

protocol LoadContactsInteractor {
    func execute(completion: @escaping (LoadContactsInteractorResult) -> Void)
}

class LoadContactsInteractorImpl: LoadContactsInteractor {
    private let service: ContactService
    
    init(service: ContactService) {
        self.service = service
    }
    
    func execute(completion: @escaping (LoadContactsInteractorResult) -> Void) {
        
    }
}

class LoadContactsInteractorTests: XCTestCase {

    func test_init_doesNotExecuteInteractor() {
        let (_, client) = makeSUT()
        
        XCTAssertTrue(client.requestedURLs.isEmpty)
    }
 
    private func makeSUT(url: URL = URL(string: "https://any-url.com")!, file: StaticString = #filePath, line: UInt = #line) -> (sut: LoadContactsInteractorImpl, client: HTTPClientSpy) {
        let client = HTTPClientSpy()
        let service = ContactServiceImpl(client: client, url: url)
        let sut = LoadContactsInteractorImpl(service: service)
        return (sut, client)
    }
}
