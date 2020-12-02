//
//  File.swift
//  GojekContactApp
//
//  Created by Arifin Firdaus on 02/12/20.
//

import Foundation

class MockHTTPClient: HTTPClient {
    func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
        let response = HTTPURLResponse(
            url: url,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!
        let users = [
            UserResponseDTO(firstName: "Arifin", lastName: "Firdaus"),
            UserResponseDTO(firstName: "SomePersonName", lastName: "SomeLastName")
        ]
        let data = try! JSONEncoder().encode(users)
        completion(.success(response, data))
    }

}
