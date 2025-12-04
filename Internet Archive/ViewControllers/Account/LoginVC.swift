//
//  LoginVC.swift
//  Internet Archive
//
//  Created by Eagle19243 on 5/8/18.
//  Copyright © 2018 Eagle19243. All rights reserved.
//
//
//

import UIKit
import Combine

@MainActor
class LoginVC: UIViewController {

    @IBOutlet weak var txtEmail: UITextField!
    @IBOutlet weak var txtPassword: UITextField!

    // MARK: - ViewModel

    private lazy var viewModel: LoginViewModel = {
        LoginViewModel(authService: DefaultAuthService())
    }()

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        bindViewModel()
    }

    // MARK: - ViewModel Binding

    private func bindViewModel() {
        viewModel.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.handleStateChange(state)
            }
            .store(in: &cancellables)
    }

    private func handleStateChange(_ state: LoginViewState) {
        if state.isLoading {
            AppProgressHUD.sharedManager.show(view: self.view)
        } else {
            AppProgressHUD.sharedManager.hide()
        }

        if let errorMessage = state.errorMessage {
            Global.showAlert(title: "Error", message: errorMessage, target: self)
        }

        if state.isLoggedIn {
            handleLoginSuccess()
        }
    }

    private func handleLoginSuccess() {
        // Get account info to retrieve username
        guard let email = txtEmail.text else { return }

        Task {
            do {
                // Route through auth service to respect mock mode for UI testing
                let accountInfo = try await viewModel.fetchAccountInfo(email: email)

                if let values = accountInfo.values, let username = values.screenname {
                    // Update user data with username
                    Global.saveUserData(userData: [
                        "username": username,
                        "email": email,
                        "password": txtPassword.text ?? "",
                        "logged-in": true
                    ])
                }

                if let accountNC = self.navigationController as? AccountNC {
                    accountNC.gotoAccountVC()
                }
            } catch {
                let errorMessage = (error as? NetworkError)?.localizedDescription ?? error.localizedDescription
                Global.showAlert(title: "Error", message: errorMessage, target: self)
            }
        }
    }

    // MARK: - Actions

    @IBAction func onLogin(_ sender: Any) {
        guard let email = txtEmail.text,
              let password = txtPassword.text else {
            return
        }

        // Use ViewModel validation
        let validation = viewModel.validateInputs(email: email, password: password)

        guard validation.isValid else {
            let errorMessage = validation.emailError ?? validation.passwordError ?? "Invalid input"
            Global.showAlert(title: "Error", message: errorMessage, target: self)
            return
        }

        // Perform login through ViewModel
        Task {
            _ = await viewModel.login(email: email, password: password)
        }
    }

    /// Validate inputs - exposed for backward compatibility and testing
    func validate() -> Bool {
        guard let email = txtEmail.text, !email.isEmpty else {
            Global.showAlert(title: "Error", message: "Please enter an email address", target: self)
            return false
        }

        guard let password = txtPassword.text, !password.isEmpty else {
            Global.showAlert(title: "Error", message: "Please enter a password", target: self)
            return false
        }

        return true
    }
}
