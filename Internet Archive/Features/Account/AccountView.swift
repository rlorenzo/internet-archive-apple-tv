//
//  AccountView.swift
//  Internet Archive
//
//  Account management and authentication screen
//

import SwiftUI

/// The account management screen for authentication and user settings.
///
/// This view provides:
/// - Login form for unauthenticated users
/// - Account info and logout for authenticated users
/// - Registration option for new users
///
/// ## Future Implementation
/// This placeholder will be replaced with a full implementation using:
/// - Integration with `APIManager.loginTyped()` and `registerTyped()`
/// - `KeychainManager` for credential storage
/// - `AppState` for reactive auth state updates
struct AccountView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        NavigationStack {
            if appState.isAuthenticated {
                authenticatedContent()
            } else {
                unauthenticatedContent()
            }
        }
    }

    // MARK: - Authenticated Content

    private func authenticatedContent() -> some View {
        VStack(spacing: 40) {
            Spacer()

            // User Avatar Placeholder
            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: 120))
                .foregroundStyle(.blue)

            // User Info
            VStack(spacing: 8) {
                Text(appState.username ?? "User")
                    .font(.title)
                    .fontWeight(.semibold)

                Text(appState.userEmail ?? "")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }

            // Account Actions
            VStack(spacing: 20) {
                Button("Sign Out") {
                    appState.logout()
                }
                .buttonStyle(.bordered)
            }
            .padding(.top, 40)

            Spacer()

            AppInfoFooter()
        }
        .padding()
        .navigationTitle("Account")
    }

    // MARK: - Unauthenticated Content

    private func unauthenticatedContent() -> some View {
        VStack(spacing: 40) {
            Spacer()

            // App Logo Placeholder
            VStack(spacing: 20) {
                Image(systemName: "building.columns")
                    .font(.system(size: 80))
                    .foregroundStyle(.blue)

                Text("Internet Archive")
                    .font(.title)
                    .fontWeight(.bold)
            }

            // Description
            Text("Sign in to your Internet Archive account to save favorites, track your watch history, and more.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 600)

            // Auth Buttons
            VStack(spacing: 20) {
                NavigationLink {
                    LoginFormView()
                } label: {
                    Text("Sign In")
                        .frame(width: 300)
                }
                .buttonStyle(.borderedProminent)

                NavigationLink {
                    RegisterFormView()
                } label: {
                    Text("Create Account")
                        .frame(width: 300)
                }
                .buttonStyle(.bordered)
            }
            .padding(.top, 20)

            Spacer()

            AppInfoFooter()
        }
        .padding()
        .navigationTitle("Account")
    }
}

// MARK: - Login Form View (Placeholder)

struct LoginFormView: View {
    @EnvironmentObject private var appState: AppState

    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            Text("Sign In")
                .font(.title)
                .fontWeight(.bold)

            VStack(spacing: 20) {
                TextField("Email", text: $email)
                    .textContentType(.emailAddress)
                    .autocorrectionDisabled()

                SecureField("Password", text: $password)
                    .textContentType(.password)
            }
            .frame(maxWidth: 500)

            if let error = errorMessage {
                Text(error)
                    .foregroundStyle(.red)
                    .font(.callout)
            }

            Button {
                performLogin()
            } label: {
                if isLoading {
                    ProgressView()
                        .frame(width: 200)
                } else {
                    Text("Sign In")
                        .frame(width: 200)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(email.isEmpty || password.isEmpty || isLoading)

            Spacer()
        }
        .padding()
        .navigationTitle("Sign In")
    }

    private func performLogin() {
        // TODO: Implement actual login with APIManager.loginTyped()
        isLoading = true
        errorMessage = nil

        // Placeholder: simulate login delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            isLoading = false
            // For now, just show placeholder error
            errorMessage = "Login functionality coming soon"
        }
    }
}

// MARK: - Register Form View (Placeholder)

struct RegisterFormView: View {
    @EnvironmentObject private var appState: AppState

    @State private var email = ""
    @State private var username = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            Text("Create Account")
                .font(.title)
                .fontWeight(.bold)

            VStack(spacing: 20) {
                TextField("Email", text: $email)
                    .textContentType(.emailAddress)
                    .autocorrectionDisabled()

                TextField("Username", text: $username)
                    .textContentType(.username)
                    .autocorrectionDisabled()

                SecureField("Password", text: $password)
                    .textContentType(.newPassword)

                SecureField("Confirm Password", text: $confirmPassword)
                    .textContentType(.newPassword)
            }
            .frame(maxWidth: 500)

            if let error = errorMessage {
                Text(error)
                    .foregroundStyle(.red)
                    .font(.callout)
            }

            Button {
                performRegistration()
            } label: {
                if isLoading {
                    ProgressView()
                        .frame(width: 200)
                } else {
                    Text("Create Account")
                        .frame(width: 200)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(!isFormValid || isLoading)

            Spacer()
        }
        .padding()
        .navigationTitle("Create Account")
    }

    private var isFormValid: Bool {
        !email.isEmpty &&
        !username.isEmpty &&
        !password.isEmpty &&
        password == confirmPassword
    }

    private func performRegistration() {
        // TODO: Implement actual registration with APIManager.registerTyped()
        isLoading = true
        errorMessage = nil

        // Placeholder: simulate registration delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            isLoading = false
            // For now, just show placeholder error
            errorMessage = "Registration functionality coming soon"
        }
    }
}

// MARK: - Previews

#Preview("Signed Out") {
    AccountView()
        .environmentObject(AppState())
}

#Preview("Signed In") {
    let appState = AppState()
    appState.setLoggedIn(email: "user@example.com", username: "ArchiveUser")
    return AccountView()
        .environmentObject(appState)
}
