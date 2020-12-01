//
//  ContactService.swift
//  GojekContactApp
//
//  Created by Arifin Firdaus on 02/12/20.
//

import Foundation


struct UserResponseDTO: Codable, Equatable {
    let firstName: String
    let lastName: String
    
    enum CodingKeys: String, CodingKey {
        case firstName = "first_name"
        case lastName = "last_name"
    }
}

enum LoadContactsResult {
    case success(_ items: [UserResponseDTO])
    case failure(_ error: ContactServiceImpl.Error)
}


protocol ContactService {
    func loadContacts(completion: @escaping (LoadContactsResult) -> Void)
}

class ContactServiceImpl {
    private let client: HTTPClient
    private let url: URL
    
    enum Error: Swift.Error, Equatable {
        case connectivity
        case invalidData
    }
    
    init(client: HTTPClient, url: URL) {
        self.client = client
        self.url = url
    }
    
    func loadContacts(completion: @escaping (LoadContactsResult) -> Void) {
        client.get(from: url) { [weak self] result in
            guard self != nil else { return }
            
            switch result {
            case .success(let response, let data):
                completion(LoadContactsMapper.map(response, data: data))
            case .failure(_):
                completion(.failure(.connectivity))
            }
        }
    }
    
    private struct LoadContactsMapper {
        static func map(_ response: URLResponse, data: Data) -> LoadContactsResult {
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    let users = try! JSONDecoder().decode([UserResponseDTO].self, from: data)
                    return .success(users)
                }
                return .failure(.invalidData)
            } else {
                return .failure(.invalidData)
            }
        }
    }
}
