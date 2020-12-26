//
//  LoadContactsInteractor.swift
//  GojekContactApp
//
//  Created by Arifin Firdaus on 02/12/20.
//

import Foundation

enum LoadContactsInteractorResult {
    case success(_ items: [User])
    case failure(_ error: LoadContactsInteractorImpl.Error)
}

protocol LoadContactsInteractor {
    func execute(completion: @escaping (LoadContactsInteractorResult) -> Void)
}

class LoadContactsInteractorImpl: LoadContactsInteractor {
    private let service: ContactService
    
    enum Error: Swift.Error, Equatable {
        case someError
    }
    
    init(service: ContactService) {
        self.service = service
    }
    
    func execute(completion: @escaping (LoadContactsInteractorResult) -> Void) {
        service.loadContacts { result in
            switch result {
            case .success(let userResponseDTOs):
                completion(.success(UsersMapper.map(userResponseDTOs)))
            case .failure(_):
                completion(.failure(.someError))
            }
        }
    }
    
    private struct UsersMapper {
        static func map(_ userResponseDTOs: [UserResponseDTO]) -> [User] {
            return userResponseDTOs.map { User(firstName: $0.firstName, lastName: $0.lastName) }
        }
    }
    
}
