//
//  AccountView.swift
//  Internet Archive
//
//  Account management and authentication screen
//

import SwiftUI
import UIKit

/// The account management screen for authentication and user settings.
///
/// This view provides:
/// - Login form for unauthenticated users
/// - Account info and logout for authenticated users
/// - Registration option for new users
///
/// Uses `LoginViewModel` for authentication operations.
struct AccountView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        NavigationStack {
            if appState.isAuthenticated {
                authenticatedContent
            } else {
                unauthenticatedContent
            }
        }
    }

    // MARK: - Authenticated Content

    private var authenticatedContent: some View {
        VStack(spacing: 40) {
            Spacer()

            // User Avatar
            AsyncImage(url: avatarURL) { phase in
                switch phase {
                case .empty:
                    avatarPlaceholder
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure:
                    avatarPlaceholder
                @unknown default:
                    avatarPlaceholder
                }
            }
            .frame(width: 150, height: 150)
            .clipShape(Circle())

            // User Info
            VStack(spacing: 8) {
                Text(appState.username ?? "User")
                    .font(.title)
                    .fontWeight(.semibold)

                Text(appState.userEmail ?? "")
                    .font(.body)
                    .foregroundStyle(.secondary)

                Text("You are logged into the Internet Archive")
                    .font(.callout)
                    .foregroundStyle(.tertiary)
                    .padding(.top, 8)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Signed in as \(appState.username ?? "User")")

            // Account Actions
            VStack(spacing: 20) {
                Button("Sign Out") {
                    signOut()
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

    private var avatarPlaceholder: some View {
        ZStack {
            Circle()
                .fill(Color.blue.opacity(0.2))
            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: 100))
                .foregroundStyle(.blue)
        }
    }

    private var avatarURL: URL? {
        guard let username = appState.username else { return nil }
        return URL(string: "https://archive.org/services/img/@\(username)")
    }

    private func signOut() {
        appState.logout()

        // Announce sign out for VoiceOver
        UIAccessibility.post(
            notification: .announcement,
            argument: "Signed out successfully"
        )
    }

    // MARK: - Unauthenticated Content

    private var unauthenticatedContent: some View {
        VStack(spacing: 40) {
            Spacer()

            // App Logo
            VStack(spacing: 20) {
                Image(systemName: "building.columns")
                    .font(.system(size: 80))
                    .foregroundStyle(.blue)

                Text("Internet Archive")
                    .font(.title)
                    .fontWeight(.bold)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Internet Archive")

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
                        .environmentObject(appState)
                } label: {
                    Text("Sign In")
                        .frame(width: 300)
                }
                .buttonStyle(.borderedProminent)

                NavigationLink {
                    RegisterFormView()
                        .environmentObject(appState)
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

// MARK: - Login Form View

/// Login form with email and password fields using LoginViewModel.
struct LoginFormView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    // MARK: - ViewModel

    @StateObject private var viewModel = LoginViewModel(
        authService: DefaultAuthService()
    )

    // MARK: - Form State

    @State private var email = ""
    @State private var password = ""

    // MARK: - Focus State

    @FocusState private var focusedField: Field?

    enum Field: Hashable {
        case email
        case password
    }

    // MARK: - Task Management

    @State private var loginTask: Task<Void, Never>?

    // MARK: - Body

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            // Title
            Text("Sign In")
                .font(.title)
                .fontWeight(.bold)

            // Form fields
            VStack(spacing: 20) {
                TextField("Email", text: $email)
                    .textContentType(.emailAddress)
                    .autocorrectionDisabled()
                    .focused($focusedField, equals: .email)
                    .accessibilityLabel("Email address")
                    .accessibilityHint("Enter your Internet Archive email address")

                SecureField("Password", text: $password)
                    .textContentType(.password)
                    .focused($focusedField, equals: .password)
                    .accessibilityLabel("Password")
                    .accessibilityHint("Enter your password")
            }
            .frame(maxWidth: 500)

            // Error message
            if let error = viewModel.state.errorMessage {
                Text(error)
                    .foregroundStyle(.red)
                    .font(.callout)
                    .multilineTextAlignment(.center)
                    .accessibilityLabel("Error: \(error)")
            }

            // Sign in button
            Button {
                performLogin()
            } label: {
                if viewModel.state.isLoading {
                    ProgressView()
                        .frame(width: 200)
                } else {
                    Text("Sign In")
                        .frame(width: 200)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(email.isEmpty || password.isEmpty || viewModel.state.isLoading)

            Spacer()
        }
        .padding()
        .navigationTitle("Sign In")
        .onAppear {
            focusedField = .email
        }
        .onDisappear {
            loginTask?.cancel()
            loginTask = nil
        }
    }

    // MARK: - Actions

    private func performLogin() {
        // Cancel any existing login task
        loginTask?.cancel()

        loginTask = Task {
            let success = await viewModel.login(email: email, password: password)

            if success {
                // Fetch account info to get username
                do {
                    let accountInfo = try await viewModel.fetchAccountInfo(email: email)
                    let username = accountInfo.values?.screenname ?? email

                    // Update app state
                    appState.setLoggedIn(email: email, username: username)

                    // Announce success for VoiceOver
                    UIAccessibility.post(
                        notification: .announcement,
                        argument: "Signed in successfully as \(username)"
                    )

                    // Dismiss back to account view
                    dismiss()
                } catch {
                    // Login succeeded but account info fetch failed
                    // Use email as fallback username
                    appState.setLoggedIn(email: email, username: email)

                    UIAccessibility.post(
                        notification: .announcement,
                        argument: "Signed in successfully"
                    )

                    dismiss()
                }
            } else {
                // Announce error for VoiceOver
                if let errorMessage = viewModel.state.errorMessage {
                    UIAccessibility.post(
                        notification: .announcement,
                        argument: "Sign in failed: \(errorMessage)"
                    )
                }
            }
        }
    }
}

// MARK: - Register Form View

/// Registration form for creating a new Internet Archive account.
struct RegisterFormView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    // MARK: - Form State

    @State private var email = ""
    @State private var username = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showSuccessAlert = false

    // MARK: - Focus State

    @FocusState private var focusedField: Field?

    enum Field: Hashable {
        case email
        case username
        case password
        case confirmPassword
    }

    // MARK: - Task Management

    @State private var registrationTask: Task<Void, Never>?

    // MARK: - Body

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            // Title
            Text("Create Account")
                .font(.title)
                .fontWeight(.bold)

            // Form fields
            VStack(spacing: 20) {
                TextField("Email", text: $email)
                    .textContentType(.emailAddress)
                    .autocorrectionDisabled()
                    .focused($focusedField, equals: .email)
                    .accessibilityLabel("Email address")
                    .accessibilityHint("Enter your email address for your new account")

                TextField("Username", text: $username)
                    .textContentType(.username)
                    .autocorrectionDisabled()
                    .focused($focusedField, equals: .username)
                    .accessibilityLabel("Username")
                    .accessibilityHint("Choose a unique username for your account")

                SecureField("Password", text: $password)
                    .textContentType(.newPassword)
                    .focused($focusedField, equals: .password)
                    .accessibilityLabel("Password")
                    .accessibilityHint("Create a password for your account")

                SecureField("Confirm Password", text: $confirmPassword)
                    .textContentType(.newPassword)
                    .focused($focusedField, equals: .confirmPassword)
                    .accessibilityLabel("Confirm password")
                    .accessibilityHint("Re-enter your password to confirm")
            }
            .frame(maxWidth: 500)

            // Validation messages
            VStack(spacing: 8) {
                if !password.isEmpty && !ValidationHelper.isValidPassword(password) {
                    Text("Password must be at least \(ValidationHelper.minimumPasswordLength) characters")
                        .foregroundStyle(.orange)
                        .font(.callout)
                }

                if !password.isEmpty && !confirmPassword.isEmpty && password != confirmPassword {
                    Text("Passwords do not match")
                        .foregroundStyle(.orange)
                        .font(.callout)
                }
            }

            // Error message
            if let error = errorMessage {
                Text(error)
                    .foregroundStyle(.red)
                    .font(.callout)
                    .multilineTextAlignment(.center)
                    .accessibilityLabel("Error: \(error)")
            }

            // Create account button
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
        .onAppear {
            focusedField = .email
        }
        .onDisappear {
            registrationTask?.cancel()
            registrationTask = nil
        }
        .alert("Account Created", isPresented: $showSuccessAlert) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Your Internet Archive account has been created. Please check your email to verify your account, then sign in.")
        }
    }

    // MARK: - Validation

    private var isFormValid: Bool {
        !email.isEmpty &&
        !username.isEmpty &&
        !password.isEmpty &&
        password == confirmPassword &&
        ValidationHelper.isValidPassword(password) &&
        ValidationHelper.isValidEmail(email)
    }

    // MARK: - Actions

    private func performRegistration() {
        // Cancel any existing registration task
        registrationTask?.cancel()

        isLoading = true
        errorMessage = nil

        registrationTask = Task {
            do {
                let params: [String: Any] = [
                    "email": email,
                    "password": password,
                    "screenname": username,
                    "verified": false
                ]
                let response = try await APIManager.networkService.register(params: params)

                isLoading = false

                if response.isSuccess {
                    // Save partial user data (not logged in yet - needs email verification)
                    let userData: [String: Any?] = [
                        "username": username,
                        "email": email,
                        "logged-in": false
                    ]
                    Global.saveUserData(userData: userData)

                    // Show success alert
                    showSuccessAlert = true

                    // Announce success for VoiceOver
                    UIAccessibility.post(
                        notification: .announcement,
                        argument: "Account created successfully. Please check your email to verify your account."
                    )
                } else {
                    errorMessage = response.error ?? "Registration failed. Please try again."

                    // Announce error for VoiceOver
                    UIAccessibility.post(
                        notification: .announcement,
                        argument: "Registration failed: \(errorMessage ?? "Unknown error")"
                    )
                }
            } catch {
                isLoading = false

                if let networkError = error as? NetworkError {
                    errorMessage = ErrorPresenter.shared.userFriendlyMessage(for: networkError)
                } else {
                    errorMessage = "Registration failed. Please try again."
                }

                // Announce error for VoiceOver
                UIAccessibility.post(
                    notification: .announcement,
                    argument: "Registration failed: \(errorMessage ?? "Unknown error")"
                )
            }
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

#Preview("Login Form") {
    NavigationStack {
        LoginFormView()
            .environmentObject(AppState())
    }
}

#Preview("Register Form") {
    NavigationStack {
        RegisterFormView()
            .environmentObject(AppState())
    }
}
