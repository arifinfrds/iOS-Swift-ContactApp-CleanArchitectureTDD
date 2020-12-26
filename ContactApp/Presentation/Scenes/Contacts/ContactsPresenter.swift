//
//  ContactsPresenter.swift
//  GojekContactApp
//
//  Created by Arifin Firdaus on 02/12/20.
//

import Foundation

protocol ContactsView {
    func display(_ users: [User])
    func display(_ errorMessage: String)
    func display(isLoading: Bool)
}

protocol ContactsPresenter {
    func onLoad()
    func onSelectUser(user: User)
}

class ContactsPresenterImpl: ContactsPresenter {
    private let interactor: LoadContactsInteractor
    private let view: ContactsView
    private let router: ContactsRouter
    
    init(interactor: LoadContactsInteractor, view: ContactsView, router: ContactsRouter) {
        self.interactor = interactor
        self.view = view
        self.router = router
    }
    
    func onLoad() {
        executeLoadContactsInteractor()
    }
    
    private func executeLoadContactsInteractor() {
        view.display(isLoading: true)
        interactor.execute { [weak self] result in
            switch result {
            case .success(let users):
                self?.view.display(users)
            case .failure(let error):
                self?.view.display(error.localizedDescription)
            }
            self?.view.display(isLoading: false)
        }
    }
    
    func onSelectUser(user: User) {
        router.showDetailContact(from: view, user: user)
    }
    
}
