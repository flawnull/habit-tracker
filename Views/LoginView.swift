//
//  LoginView.swift
//  habit-tracker
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var authManager: AuthenticationManager
    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false
    @State private var showSignUp = false
    @State private var showForgotPassword = false
    @State private var showError = false
    @State private var appeared = false
    @FocusState private var focusedField: Field?

    enum Field {
        case email, password
    }

    private var canSubmit: Bool {
        !email.isEmpty && !password.isEmpty && !authManager.isLoading
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    Spacer(minLength: 48)
                    header
                    if AppConfig.isFirebaseReady {
                        form
                        Button {
                            Task { await signIn() }
                        } label: {
                            if authManager.isLoading {
                                CustomLoadingView(tintColor: .white)
                            } else {
                                Text("Sign in")
                            }
                        }
                        .buttonStyle(BrandButtonStyle())
                        .disabled(!canSubmit)

                        Button("Forgot password?") { showForgotPassword = true }
                            .font(.subheadline.weight(.medium))

                        OrDivider()
                    } else {
                        demoNotice
                    }

                    guestButton

                    if AppConfig.isFirebaseReady {
                        Button {
                            showSignUp = true
                        } label: {
                            HStack(spacing: 4) {
                                Text("New here?").foregroundStyle(.secondary)
                                Text("Create an account").fontWeight(.semibold)
                            }
                            .font(.subheadline)
                        }
                    }
                    Spacer(minLength: 32)
                }
                .padding(.horizontal, 24)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)
            }
            .scrollDismissesKeyboard(.interactively)
            .brandScreen()
            .toolbar(.hidden, for: .navigationBar)
            .alert("Couldn't sign in", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(authManager.errorMessage ?? "Something went wrong.")
            }
            .fullScreenCover(isPresented: $showSignUp) {
                SignUpView()
            }
            .sheet(isPresented: $showForgotPassword) {
                ForgotPasswordView()
            }
            .onAppear {
                withAnimation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.1)) { appeared = true }
            }
        }
    }

    private var header: some View {
        VStack(spacing: 18) {
            BrandMark(size: 104)
            VStack(spacing: 8) {
                Text("Welcome back")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                Text("Small loops, every day. Pick up where you left off.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private var form: some View {
        VStack(spacing: 14) {
            CustomTextField(icon: "envelope.fill", placeholder: "Email", text: $email, contentType: .username)
                .focused($focusedField, equals: .email)
                .textInputAutocapitalization(.never)
                .keyboardType(.emailAddress)
                .submitLabel(.next)
                .onSubmit { focusedField = .password }

            CustomTextField(
                icon: "lock.fill",
                placeholder: "Password",
                text: $password,
                isSecure: !showPassword,
                showPasswordToggle: true,
                showPassword: $showPassword,
                contentType: .password
            )
            .focused($focusedField, equals: .password)
            .submitLabel(.go)
            .onSubmit { Task { await signIn() } }
        }
    }

    private var demoNotice: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "externaldrive.badge.icloud")
                .font(.title3)
                .foregroundStyle(Theme.brandGradient)
            VStack(alignment: .leading, spacing: 4) {
                Text("Local demo build")
                    .font(.subheadline.weight(.semibold))
                Text("No Firebase config found, so accounts are off. Everything works locally, and habits stay on this device.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .glassCard(cornerRadius: 20)
    }

    private var guestButton: some View {
        Group {
            if AppConfig.isFirebaseReady {
                Button {
                    Haptics.tap(.light)
                    authManager.enterGuestMode()
                } label: {
                    Label("Continue without an account", systemImage: "person.crop.circle.dashed")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                }
                .buttonStyle(.glass)
            } else {
                Button {
                    Haptics.tap(.light)
                    authManager.enterGuestMode()
                } label: {
                    Label("Start tracking", systemImage: "arrow.right")
                }
                .buttonStyle(BrandButtonStyle())
            }
        }
    }

    private func signIn() async {
        guard canSubmit else { return }
        do {
            try await authManager.signIn(email: email, password: password)
            Haptics.success()
        } catch {
            showError = true
            Haptics.error()
        }
    }
}

struct OrDivider: View {
    var body: some View {
        HStack(spacing: 14) {
            Rectangle().fill(Color.primary.opacity(0.12)).frame(height: 1)
            Text("OR")
                .font(.caption2.weight(.bold))
                .tracking(1.2)
                .foregroundStyle(.secondary)
            Rectangle().fill(Color.primary.opacity(0.12)).frame(height: 1)
        }
    }
}

struct CustomTextField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var isSecure: Bool = false
    var showPasswordToggle: Bool = false
    @Binding var showPassword: Bool
    var contentType: UITextContentType?

    init(
        icon: String,
        placeholder: String,
        text: Binding<String>,
        isSecure: Bool = false,
        showPasswordToggle: Bool = false,
        showPassword: Binding<Bool> = .constant(false),
        contentType: UITextContentType? = nil
    ) {
        self.icon = icon
        self.placeholder = placeholder
        self._text = text
        self.isSecure = isSecure
        self.showPasswordToggle = showPasswordToggle
        self._showPassword = showPassword
        self.contentType = contentType
    }

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .foregroundStyle(.secondary)
                .frame(width: 20)

            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                }
            }
            .textContentType(contentType)
            .autocorrectionDisabled()

            if showPasswordToggle {
                Button {
                    showPassword.toggle()
                    Haptics.tap(.light)
                } label: {
                    Image(systemName: showPassword ? "eye.fill" : "eye.slash.fill")
                        .foregroundStyle(.secondary)
                        .contentTransition(.symbolEffect(.replace))
                }
                .accessibilityLabel(showPassword ? "Hide password" : "Show password")
            }
        }
        .padding(.horizontal, 18)
        .frame(height: 56)
        .glassCard(cornerRadius: 18)
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthenticationManager())
}
