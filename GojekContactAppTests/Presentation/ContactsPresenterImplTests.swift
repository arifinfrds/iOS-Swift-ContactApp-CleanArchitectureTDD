//
//  ContactsPresenterImplTests.swift
//  GojekContactAppTests
//
//  Created by Arifin Firdaus on 02/12/20.
//

import XCTest
@testable import GojekContactApp


class ContactsPresenterImpl {
    private let interactor: LoadContactsInteractor
    
    init(interactor: LoadContactsInteractor) {
        self.interactor = interactor
    }
}

class ContactsPresenterImplTests: XCTestCase {
    
    func test_init_doesNotExecuteInteractor() {
        let (_ , client) = makeSUT()
        
        XCTAssertTrue(client.requestedURLs.isEmpty)
    }
    
    
    // MARK: - Helpers
    
    private func makeSUT(url: URL = URL(string: "https://any-url.com")!, file: StaticString = #filePath, line: UInt = #line) -> (sut: ContactsPresenterImpl, client: HTTPClientSpy) {
        let client = HTTPClientSpy()
        let service = ContactServiceImpl(client: client, url: url)
        let interactor = LoadContactsInteractorImpl(service: service)
        let sut = ContactsPresenterImpl(interactor: interactor)
        return (sut, client)
    }
    
    private func makeJSONData(forResourceJsonName name: String) -> Data {
        let jsonURL = Bundle(for: ContactServiceImplTests.self).url(forResource: name, withExtension: "json")!
        let data = try! Data(contentsOf: jsonURL)
        return data
    }
    
}
