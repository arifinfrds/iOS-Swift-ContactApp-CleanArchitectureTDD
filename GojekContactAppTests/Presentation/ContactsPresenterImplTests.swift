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
    
    var users: [User] = []
    
    init(interactor: LoadContactsInteractor) {
        self.interactor = interactor
    }
    
    func onLoad() {
        interactor.execute { result in
            switch result {
            case .success(let users):
                self.users = users
            case .failure(_):
                break
            }
        }
    }
}

class ContactsPresenterImplTests: XCTestCase {
    
    func test_init_doesNotExecuteInteractor() {
        let (_ , client) = makeSUT()
        
        XCTAssertTrue(client.requestedURLs.isEmpty)
    }
    
    func test_onLoad_deliversUsersWithValidUsers() {
        let (sut, client) = makeSUT()
        
        sut.onLoad()
        
        let usersJSONData = makeJSONData(forResourceJsonName: "users")
        client.complete(withStatusCode: 200, data: usersJSONData)
        
        XCTAssertTrue(!sut.users.isEmpty)
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
