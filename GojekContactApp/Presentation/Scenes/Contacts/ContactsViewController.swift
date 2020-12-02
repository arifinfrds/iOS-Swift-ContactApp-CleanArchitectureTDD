//
//  ContactsViewController.swift
//  GojekContactApp
//
//  Created by Arifin Firdaus on 02/12/20.
//

import UIKit

class ContactsViewController: UIViewController, ContactsView {
    @IBOutlet weak var tableView: UITableView!
    
    private(set) var presenter: ContactsPresenter!
    
    private var users: [User] = [] {
        didSet { tableView.reloadData() }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        instantiatePresenter()
        presenter.onLoad()
        
        tableView.dataSource = self
        tableView.delegate = self
    }
    
    private func instantiatePresenter() {
        let url = URL(string: "https://any-url.com")!
        let client = MockHTTPClient()
        let service = ContactServiceImpl(client: client, url: url)
        let interactor = LoadContactsInteractorImpl(service: service)
        let view = self
        let router = ContactsRouterImpl()
        let presenter: ContactsPresenter = ContactsPresenterImpl(interactor: interactor, view: view, router: router)
        self.presenter = presenter
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
