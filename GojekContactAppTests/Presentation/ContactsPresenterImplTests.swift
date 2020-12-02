//
//  ContactsPresenterImplTests.swift
//  GojekContactAppTests
//
//  Created by Arifin Firdaus on 02/12/20.
//

import XCTest
@testable import GojekContactApp


class ContactsPresenterImplTests: XCTestCase {
    
    
    func test_init_doesNotExecuteInteractor() {
        let (_, client, _, _) = makeSUT()
        
        XCTAssertTrue(client.requestedURLs.isEmpty)
    }
    
    func test_onLoad_deliversErrorWithAnyErrorMessage() {
        let (sut, client, view, _) = makeSUT()
        
        sut.onLoad()
        
        client.complete(with: NSError(domain: NSURLErrorDomain, code: -1, userInfo: nil))
        
        XCTAssertNotEqual(view.errorMessage, "")
    }
    
    func test_onLoad_deliversUsers() {
        let (sut, client, view, _) = makeSUT()
        
        sut.onLoad()
        
        let usersJSONData = makeJSONData(forResourceJsonName: "users")
        client.complete(withStatusCode: 200, data: usersJSONData)
        
        XCTAssertTrue(!view.users.isEmpty)
    }
    
    func test_onSelectUser_shouldNavigate() {
        let (sut, _, _, router) = makeSUT()
        
        let selectedUser = User(firstName: "Arifin", lastName: "Firdaus")
        sut.onSelectUser(user: selectedUser)
        
        XCTAssertTrue(router.isShowDetailContactCalled)
        XCTAssertEqual(router.user!, selectedUser)
    }

    
    // MARK: - Helpers
    
    private func makeSUT(url: URL = URL(string: "https://any-url.com")!, file: StaticString = #filePath, line: UInt = #line) -> (sut: ContactsPresenterImpl, client: HTTPClientSpy, view: ContactsViewSpy, router: ContactsRouterSpy) {
        let client = HTTPClientSpy()
        let service = ContactServiceImpl(client: client, url: url)
        let interactor = LoadContactsInteractorImpl(service: service)
        let view = ContactsViewSpy()
        let router = ContactsRouterSpy()
        let sut = ContactsPresenterImpl(interactor: interactor, view: view, router: router)
        return (sut, client, view, router)
    }
    
    private func makeJSONData(forResourceJsonName name: String) -> Data {
        let jsonURL = Bundle(for: ContactServiceImplTests.self).url(forResource: name, withExtension: "json")!
        let data = try! Data(contentsOf: jsonURL)
        return data
    }
    
    private class ContactsViewSpy: ContactsView {
        var users: [User] = []
        var errorMessage: String = ""
        var isLoading = false
        
        func display(_ users: [User]) {
            self.users = users
        }
        
        func display(_ errorMessage: String) {
            self.errorMessage = errorMessage
        }
        
        func display(isLoading: Bool) {
            self.isLoading = isLoading
        }
    }
    
    private class ContactsRouterSpy: ContactsRouter {
        var isShowDetailContactCalled = false
        var user: User?
        
        func showDetailContact(from view: ContactsView, user: User) {
            self.isShowDetailContactCalled = true
            self.user = user
        }
    }
    
}
