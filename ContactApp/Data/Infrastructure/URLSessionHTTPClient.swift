//
//  URLSessionHTTPClient.swift
//  ContactApp
//
//  Created by Arifin Firdaus on 30/12/20.
//

import Foundation

class URLSessionHTTPClient: HTTPClient {
    private let session: URLSession
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    struct UnexpectedValuesRepresentation: Error { }
    
    func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
        session.dataTask(with: url) { (data, response, error) in
            if let error = error {
                completion(.failure(error))
            }
            else if let data = data, let httpURLResponse = response as? HTTPURLResponse {
                completion(.success(data, httpURLResponse))
            }
            else {
                completion(.failure(UnexpectedValuesRepresentation()))
            }
        }
        .resume()
    }
}
