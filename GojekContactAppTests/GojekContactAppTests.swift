//
//  GojekContactAppTests.swift
//  GojekContactAppTests
//
//  Created by Arifin Firdaus on 30/11/20.
//

import XCTest
@testable import GojekContactApp

protocol HTTPClient {
    func get(from url: URL)
}

protocol ContactService {
    func loadContacts()
}

class ContactServiceImpl: ContactService {
    func loadContacts() {
        
    }
}


class GojekContactAppTests: XCTestCase {
    
    func test_init_doesNotRequestDataFromURL() {
        let client = HTTPClientSpy()
        let _ = ContactServiceImpl()
        
        XCTAssertEqual(client.requestedURL, nil)
    }
    
    private class HTTPClientSpy {
        var requestedURL: URL?
    }

}
