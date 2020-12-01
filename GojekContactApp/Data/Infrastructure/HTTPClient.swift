//
//  HTTPClient.swift
//  GojekContactApp
//
//  Created by Arifin Firdaus on 02/12/20.
//

import Foundation

enum HTTPClientResult {
    case success(URLResponse, Data)
    case failure(Error)
}

protocol HTTPClient {
    func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void)
}
