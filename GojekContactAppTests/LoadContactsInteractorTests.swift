//
//  LoadContactsInteractor.swift
//  GojekContactAppTests
//
//  Created by Arifin Firdaus on 02/12/20.
//

import XCTest

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
    
    func execute(completion: @escaping (LoadContactsInteractorResult) -> Void) {
        
    }
}

class LoadContactsInteractor: XCTestCase {

 
}
