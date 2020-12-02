//
//  ContactsViewController.swift
//  GojekContactApp
//
//  Created by Arifin Firdaus on 02/12/20.
//

import UIKit

class HTTPClientMock: HTTPClient {
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

class ContactsViewController: UIViewController, ContactsView {
    @IBOutlet weak var tableView: UITableView!
    
    private(set) var presenter: ContactsPresenter!
    
    private var users: [User] = [] {
        didSet { tableView.reloadData() }
    }
    
    final class func create(with presenter: ContactsPresenter) -> ContactsViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        let viewController = storyboard.instantiateViewController(identifier: "ContactsViewController") as! ContactsViewController
        viewController.presenter  = presenter
        return viewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let url = URL(string: "https://any-url.com")!
        let client = HTTPClientMock()
        let service = ContactServiceImpl(client: client, url: url)
        let interactor = LoadContactsInteractorImpl(service: service)
        let view = self
        let router = ContactsRouterImpl()
        let presenter: ContactsPresenter = ContactsPresenterImpl(interactor: interactor, view: view, router: router)
        self.presenter = presenter
        
        presenter.onLoad()
        
        tableView.dataSource = self
        tableView.delegate = self
    }
    
    
    // MARK: - ContactsView
    
    func display(_ users: [User]) {
        self.users = users
    }
    
    func display(_ errorMessage: String) {
        print(errorMessage)
    }
    
    func display(isLoading: Bool) {
        print(isLoading)
    }

}


// MARK: - UITableViewDataSource

extension ContactsViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ContactCell", for: indexPath)
        let user = users[indexPath.row]
        cell.textLabel?.text = user.firstName + " " + user.lastName
        return cell
    }
    
}


// MARK: - UITableViewDelegate

extension ContactsViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
}
